import 'dart:convert';
import 'dart:io';
import 'package:dentaltid/src/core/network/network_status_provider.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/settings/application/staff_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/sync_service.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:logging/logging.dart';

class SyncServer {
  final _log = Logger('SyncServer');
  final ProviderContainer _container;
  HttpServer? _server;
  final List<WebSocketChannel> _clients = [];
  final Map<WebSocketChannel, String> _clientIdentities = {};

  SyncServer(this._container);

  bool get isRunning => _server != null;

  bool _isStarting = false;

  Future<void> start(int port) async {
    if (_server != null || _isStarting) {
      _log.warning('Server already running or starting.');
      return;
    }

    _isStarting = true;
    final router = Router();

    // Middleware to log all requests
    final pipeline = const Pipeline().addMiddleware(
      logRequests(
        logger: (msg, isError) {
          if (isError) {
            _log.severe(msg);
          } else {
            _log.info('HTTP: $msg');
          }
        },
      ),
    );

    final webSocket = webSocketHandler((WebSocketChannel webSocket) {
      _log.info('WEBSOCKET: Client connection handshake initiated.');

      // CRITICAL: Send immediate ACK to prevent client timeout during DB export
      webSocket.sink.add(jsonEncode({'type': 'connection_accepted'}));

      _clients.add(webSocket);
      _container.read(connectedClientsCountProvider.notifier).state =
          _clients.length;

      _sendInitialSync(webSocket);

      webSocket.stream.listen(
        (message) => _processIncomingEvent(message, webSocket),
        onDone: () {
          _log.info('WEBSOCKET: Client disconnected.');
          _clients.remove(webSocket);
          _clientIdentities.remove(webSocket);
          _container.read(connectedClientsCountProvider.notifier).state =
              _clients.length;
          _container.read(connectedStaffNamesProvider.notifier).state =
              _clientIdentities.values.toList();
        },
        onError: (err) => _log.severe('WEBSOCKET ERROR: $err'),
      );
    });

    router.get('/ws', webSocket);

    try {
      _server = await shelf_io.serve(
        pipeline.addHandler(router.call),
        InternetAddress.anyIPv4,
        port,
      );
      _container
          .read(networkStatusProvider.notifier)
          .setStatus(ConnectionStatus.serverRunning);
      _log.info('Server successfully bound to port ${_server!.port}');
    } catch (e) {
      _log.severe('CRITICAL: Failed to start shelf server: $e');
      _container
          .read(networkStatusProvider.notifier)
          .setStatus(ConnectionStatus.error);
      rethrow;
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _sendInitialSync(WebSocketChannel webSocket) async {
    _log.info('SYNC: Preparing initial sync payload...');
    try {
      final dbDataMap = await _container
          .read(syncServiceProvider)
          .exportDatabaseMapForSync();
      _log.info('SYNC: Database export complete.');

      // Attempt to get profile from provider
      _log.info('SYNC: Fetching dentist profile...');

      Map<String, dynamic>? profileMap;
      try {
        final dentistProfile = await _container
            .read(userProfileProvider.future)
            .timeout(const Duration(seconds: 2));
        profileMap = dentistProfile?.toJson();
      } catch (e) {
        _log.warning(
          'SYNC: Provider timeout/error, using local settings cache: $e',
        );
        final cachedJson =
            SettingsService.instance.getString('cached_user_profile') ??
            SettingsService.instance.getString('dentist_profile');
        if (cachedJson != null) {
          try {
            profileMap = jsonDecode(cachedJson);
          } catch (_) {}
        }
      }

      if (profileMap == null) {
        _log.warning('SYNC: Creating fallback offline profile for handshake.');
        final fallbackProfile = UserProfile(
          uid: 'offline_dentist',
          email: 'offline@local.dentist',
          licenseKey: 'OFFLINE_MODE',
          plan: SubscriptionPlan.trial,
          status: SubscriptionStatus.active,
          licenseExpiry: DateTime.now().add(const Duration(days: 365)),
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          lastSync: DateTime.now(),
          dentistName: 'Offline Dentist',
          isPremium: false, // Default to non-premium if profile is missing
        );
        profileMap = fallbackProfile.toJson();
      }

      _log.info('SYNC: Constructing full payload Map...');
      final fullPayload = {
        'type': 'initial_sync',
        'profile': profileMap,
        'database': dbDataMap,
        'currency': SettingsService.instance.getString('currency') ?? r'$',
      };

      _log.info(
        'SYNC: Encoding and sending payload (this may take a few seconds)...',
      );
      try {
        final payloadString = jsonEncode(fullPayload);
        _log.info('SYNC: Encoded payload size: ${payloadString.length} bytes.');

        webSocket.sink.add(payloadString);
        _log.info('SYNC: Initial sync data added to sink successfully.');
      } catch (e) {
        _log.severe(
          'SYNC ERROR: jsonEncode failed. Database might be too large for memory: $e',
        );
        webSocket.sink.add(
          jsonEncode({
            'type': 'error',
            'message':
                'Server ran out of memory or encountered encoding error during sync.',
          }),
        );
      }
    } catch (e, stack) {
      _log.severe('SYNC ERROR: Error sending initial sync: $e', e, stack);
      webSocket.sink.add(
        jsonEncode({
          'type': 'error',
          'message': 'Internal Server Error during sync: $e',
        }),
      );
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      for (var client in _clients) {
        client.sink.close();
      }
      _clients.clear();
      _clientIdentities.clear();
      _container.read(connectedClientsCountProvider.notifier).state = 0;
      _container.read(connectedStaffNamesProvider.notifier).state = [];
      _container
          .read(networkStatusProvider.notifier)
          .setStatus(ConnectionStatus.serverStopped);
      _log.info('Server stopped.');
    }
  }

  Future<void> _processIncomingEvent(
    String message,
    WebSocketChannel origin,
  ) async {
    _log.info('Received from client: $message');
    try {
      final json = jsonDecode(message);
      final String type = json['type'] ?? 'sync_event';

      if (type == 'staff_identity') {
        final name = json['fullName'] as String? ?? 'Unknown Staff';
        _clientIdentities[origin] = name;
        _container.read(connectedStaffNamesProvider.notifier).state =
            _clientIdentities.values.toList();
        _log.info('WEBSOCKET: Identified client as $name');
        return;
      }

      final event = SyncEvent.fromJson(json);

      _log.info('Applying event to server database for table: ${event.table}');

      // Apply to local DB
      final db = await _container.read(databaseServiceProvider).database;
      switch (event.action) {
        case SyncAction.create:
        case SyncAction.update:
          await db.insert(
            event.table,
            event.data,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          break;
        case SyncAction.delete:
          await db.delete(
            event.table,
            where: 'id = ?',
            whereArgs: [event.data['id']],
          );
          break;
      }

      // Invalidate relevant provider to refresh server UI
      _invalidateProviderForTable(event.table);

      // Broadcast the event to all OTHER clients
      broadcast(message, from: origin);
    } catch (e) {
      _log.warning('Could not process incoming event: $e');
    }
  }

  void _invalidateProviderForTable(String table) {
    if (table == 'patients') {
      _container.read(patientServiceProvider).notifyDataChanged();
      _container.read(financeServiceProvider).notifyDataChanged();
      _container.invalidate(patientsProvider);
      _log.info('Triggered refresh for table: $table (including Finance)');
    } else if (table == 'appointments') {
      _container.read(appointmentServiceProvider).notifyDataChanged();
      _container.read(financeServiceProvider).notifyDataChanged();
      _container.invalidate(appointmentsProvider);
      _container.invalidate(todaysAppointmentsProvider);
      _container.invalidate(todaysEmergencyAppointmentsProvider);
      _log.info('Triggered refresh for table: $table (including Finance)');
    } else if (table == 'inventory') {
      _container.read(inventoryServiceProvider).notifyDataChanged();
      _container.invalidate(inventoryItemsProvider);
      _log.info('Triggered refresh for table: $table');
    } else if (table == 'transactions') {
      _container.read(financeServiceProvider).notifyDataChanged();
      _log.info('Triggered refresh for table: $table');
    } else if (table == 'staff_users') {
      _container.invalidate(staffListProvider);
      _log.info('Invalidated staffListProvider');
    } else if (table == 'dentist_profile') {
      _container.invalidate(userProfileProvider);
      _log.info(
        'Invalidated userProfileProvider due to dentist_profile update',
      );
    }
  }

  void broadcast(String message, {WebSocketChannel? from}) {
    _log.info('Broadcasting message to ${_clients.length} clients.');

    // Ensure the message has the 'sync_event' type if it's a raw event string
    String finalMessage = message;
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map && !decoded.containsKey('type')) {
        decoded['type'] = 'sync_event';
        finalMessage = jsonEncode(decoded);
      }
    } catch (_) {}

    for (var client in _clients) {
      if (client != from) {
        client.sink.add(finalMessage);
      }
    }
  }
}

final syncServerProvider = Provider((ref) => SyncServer(ref.container));
