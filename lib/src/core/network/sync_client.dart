import 'dart:async';
import 'dart:convert';

import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:dentaltid/src/core/network/network_status_provider.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/src/core/sync_service.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/settings/application/staff_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SyncClient {
  final _log = Logger('SyncClient');
  final ProviderContainer _container;
  WebSocketChannel? _channel;
  bool _isInitialSyncComplete = false;

  SyncClient(this._container);

  void _setStatus(ConnectionStatus status) {
    // CRITICAL: Prevent status overwrites on Dentist machines
    final roleString = SettingsService.instance.getString('userRole');
    final isDentist = roleString == UserRole.dentist.toString();

    if (isDentist) {
      _log.info(
        'SyncClient: Role is DENTIST. Ignoring status update to $status to preserve Server state.',
      );
      return;
    }

    _log.info('SyncClient: Updating global network status to $status');
    _container.read(networkStatusProvider.notifier).setStatus(status);
  }

  Future<void> connect(String ip, int port) async {
    if (_channel != null) {
      _log.warning('Already connected.');
      return;
    }
    try {
      final uri = Uri.parse('ws://$ip:$port/ws');
      _log.info('Connecting to $uri...');
      _setStatus(ConnectionStatus.connecting);

      _channel = IOWebSocketChannel.connect(uri);

      final completer = Completer<void>();
      StreamSubscription? subscription;

      subscription = _channel!.stream.listen(
        (message) {
          if (!completer.isCompleted) {
            completer.complete();
          }
          _handleMessage(message);
        },
        onDone: () {
          _log.info('Disconnected from server.');
          _channel = null;
          _isInitialSyncComplete = false;
          _setStatus(ConnectionStatus.disconnected);
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('Connection closed before handshake completed.'),
            );
          }
          subscription?.cancel();
        },
        onError: (error) {
          _log.severe('WebSocket stream error: $error');
          _channel = null;
          _isInitialSyncComplete = false;
          _setStatus(ConnectionStatus.error);
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
          subscription?.cancel();
        },
      );

      // Wait for the first message (handshake) or timeout.
      // Now that the server sends an immediate 'connection_accepted',
      // this timeout can be shorter for the initial handshake.
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _channel?.sink.close();
          throw TimeoutException(
            'Handshake timed out. The server might be unreachable or firewalled.',
          );
        },
      );

      _log.info('WebSocket channel established. Waiting for sync data...');
    } catch (e) {
      _log.severe('Failed to connect to server: $e');
      _channel = null;
      rethrow;
    }
  }

  void _handleMessage(String message) {
    try {
      final Map<String, dynamic> json = jsonDecode(message);
      final String type = json['type'] ?? 'unknown';

      if (type == 'connection_accepted') {
        _log.info('Server accepted connection. Starting data transfer wait...');
        _setStatus(ConnectionStatus.handshakeAccepted);
        sendIdentity();
      } else if (type == 'initial_sync' && !_isInitialSyncComplete) {
        _log.info('Initial sync payload received. Importing...');
        _setStatus(ConnectionStatus.syncing);
        final syncService = _container.read(syncServiceProvider);

        final dbDataMap = json['database'] as Map<String, dynamic>;
        final profileData = json['profile'] as Map<String, dynamic>;
        final currency = json['currency'] as String?;

        Future.wait<void>([
              syncService.importDatabaseMapFromSync(dbDataMap),
              _saveDentistProfile(profileData),
              if (currency != null) _saveCurrency(currency),
            ])
            .then((_) {
              _log.info('Initial DB and Profile sync complete!');
              _isInitialSyncComplete = true;
              _container.invalidate(userProfileProvider);
              _setStatus(ConnectionStatus.synced);
            })
            .catchError((e, s) {
              _log.severe('Full sync failed!', e, s);
              _setStatus(ConnectionStatus.error);
            });
      } else if (type == 'error') {
        _log.severe('Received error from server: ${json['message']}');
        _setStatus(ConnectionStatus.error);
        _channel?.sink.close();
      } else if (type == 'sync_event' && _isInitialSyncComplete) {
        _log.info('Received real-time event.');
        final event = SyncEvent.fromJson(json);
        _applySyncEvent(event);
      } else {
        _log.warning('Received unknown or out-of-order message type: $type');
      }
    } catch (e) {
      _log.warning('Could not parse message: $e');
    }
  }

  Future<void> _saveCurrency(String currency) async {
    await SettingsService.instance.setString('currency', currency);
    _container.invalidate(currencyProvider);
    _log.info('Synced currency from server: $currency');
  }

  Future<void> _saveDentistProfile(Map<String, dynamic> profileJson) async {
    await SettingsService.instance.setString(
      'dentist_profile',
      jsonEncode(profileJson),
    );
    _log.info('Saved dentist profile to local storage for license checking.');
  }

  Future<void> _applySyncEvent(SyncEvent event) async {
    if (event.table == 'app_settings') {
      final currency = event.data['currency'];
      if (currency != null) {
        await _saveCurrency(currency);
      }
      return;
    }

    if (event.table == 'dentist_profile') {
      await _saveDentistProfile(event.data);
      _container.invalidate(userProfileProvider);
      return;
    }

    final db = await _container.read(databaseServiceProvider).database;
    switch (event.action) {
      case SyncAction.create:
      case SyncAction.update:
        await db.insert(
          event.table,
          event.data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        _log.info(
          'Applied ${event.action} to ${event.table} for id: ${event.data['id']}',
        );
        break;
      case SyncAction.delete:
        await db.delete(
          event.table,
          where: 'id = ?',
          whereArgs: [event.data['id']],
        );
        _log.info(
          'Applied delete to ${event.table} for id: ${event.data['id']}',
        );
        break;
    }
    _invalidateProviderForTable(event.table);
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
      _log.info(
        'FORCE REFRESH (Client): appointmentsProvider & todaysAppointmentsProvider invalidated.',
      );
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

  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
      _setStatus(ConnectionStatus.disconnected);
    }
  }

  void sendIdentity() {
    if (_channel == null) return;

    final cachedProfileJson = SettingsService.instance.getString(
      'managedUserProfile',
    );
    if (cachedProfileJson != null) {
      try {
        final profileMap = jsonDecode(cachedProfileJson);
        final fullName =
            profileMap['fullName'] ?? profileMap['username'] ?? 'Unknown Staff';
        _log.info('Sending identity: $fullName');
        _channel!.sink.add(
          jsonEncode({'type': 'staff_identity', 'fullName': fullName}),
        );
      } catch (e) {
        _log.warning('Could not decode managedUserProfile for identity: $e');
      }
    }
  }

  void send(SyncEvent event) {
    if (_channel != null) {
      final payload = {'type': 'sync_event', ...event.toJson()};
      final message = jsonEncode(payload);
      _channel!.sink.add(message);
    }
  }
}

final syncClientProvider = Provider((ref) => SyncClient(ref.container));
