import 'dart:convert';
import 'dart:io';
import 'package:dentaltid/src/core/network/network_status_provider.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
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
import 'package:logging/logging.dart';

class SyncServer {
  final _log = Logger('SyncServer');
  final ProviderContainer _container;
  HttpServer? _server;
  final List<WebSocketChannel> _clients = [];

  SyncServer(this._container);

  Future<void> start(int port) async {
    if (_server != null) {
      _log.warning('Server already running.');
      return;
    }

    final router = Router();
    
    final webSocket = webSocketHandler((WebSocketChannel webSocket) {
      _log.info('Client connected!');
      _clients.add(webSocket);
      _container.read(connectedClientsCountProvider.notifier).state = _clients.length;
      
      _sendInitialSync(webSocket);

      webSocket.stream.listen(
        (message) => _processIncomingEvent(message, webSocket),
        onDone: () {
          _log.info('Client disconnected.');
          _clients.remove(webSocket);
          _container.read(connectedClientsCountProvider.notifier).state = _clients.length;
        },
      );
    });

    router.get('/ws', webSocket);

    final handler = const Pipeline().addHandler(router.call);
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    _container.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.serverRunning);
    _log.info('Server started on port ${_server!.port}');
  }

  Future<void> _sendInitialSync(WebSocketChannel webSocket) async {
    try {
      final dbData = await _container.read(syncServiceProvider).exportDatabaseForSync();
      final dentistProfile = await _container.read(userProfileProvider.future);
      
      if (dentistProfile != null) {
        final payload = {
          'type': 'initial_sync',
          'profile': dentistProfile.toJson(),
          'database': jsonDecode(dbData), // dbData is already a JSON string, so decode it to embed in the parent JSON
        };
        webSocket.sink.add(jsonEncode(payload));
        _log.info('Sent initial sync data to client.');
      } else {
        _log.warning('Could not get dentist profile for initial sync.');
      }
    } catch (e) {
      _log.severe('Error sending initial sync: $e');
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
      _container.read(connectedClientsCountProvider.notifier).state = 0;
      _container.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.serverStopped);
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
      final providerMap = {
          'staff_users': staffListProvider,
          'patients': patientsProvider,
          'inventory': inventoryItemsProvider,
          'appointments': appointmentsProvider,
      };

      final provider = providerMap[table];
      if (provider != null) {
          _container.invalidate(provider);
          _log.info('Invalidated provider for table: $table');
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
