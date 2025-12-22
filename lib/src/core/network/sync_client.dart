import 'dart:convert';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/network/network_status_provider.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:dentaltid/src/core/sync_service.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/settings/application/staff_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


class SyncClient {
  final _log = Logger('SyncClient');
  final ProviderContainer _container;
  WebSocketChannel? _channel;
  bool _isInitialSyncComplete = false;

  SyncClient(this._container);

  Future<void> connect(String ip, int port) async {
    if (_channel != null) {
      _log.warning('Already connected.');
      return;
    }
    try {
      final uri = Uri.parse('ws://$ip:$port/ws');
      _log.info('Connecting to $uri...');
      _container.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.connecting);
      _channel = IOWebSocketChannel.connect(uri);
      
      _channel!.stream.listen((message) {
        _handleMessage(message);
      }, onDone: () {
        _log.info('Disconnected from server.');
        _channel = null;
        _isInitialSyncComplete = false;
        _container.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.disconnected);
      }, onError: (error) {
        _log.severe('WebSocket error: $error');
        _channel = null;
        _isInitialSyncComplete = false;
        _container.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.error);
      });

    } catch (e) {
      _log.severe('Failed to connect to server: $e');
      _channel = null;
      _container.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.error);
    }
  }

  void _handleMessage(String message) {
    try {
      final Map<String, dynamic> json = jsonDecode(message);
      final String type = json['type'] ?? 'unknown';

      if (type == 'initial_sync' && !_isInitialSyncComplete) {
        _log.info('Initial sync payload received. Importing...');
        final syncService = _container.read(syncServiceProvider);
        
        final dbData = jsonEncode(json['database']);
        final profileData = json['profile'];

        Future.wait<void>([
          syncService.importDatabaseFromSync(dbData),
          _saveDentistProfile(profileData),
        ]).then((_) {
            _log.info('Initial DB and Profile sync complete!');
            _isInitialSyncComplete = true;
            _container.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.connected);
        }).catchError((e, s) {
            _log.severe('Full sync failed!', e, s);
            _container.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.error);
        });

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

  Future<void> _saveDentistProfile(Map<String, dynamic> profileJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dentist_profile', jsonEncode(profileJson));
    _log.info('Saved dentist profile to local storage for license checking.');
  }

  Future<void> _applySyncEvent(SyncEvent event) async {
    final db = await _container.read(databaseServiceProvider).database;
    switch (event.action) {
      case SyncAction.create:
      case SyncAction.update:
        await db.insert(
          event.table,
          event.data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        _log.info('Applied ${event.action} to ${event.table} for id: ${event.data['id']}');
        break;
      case SyncAction.delete:
        await db.delete(
          event.table,
          where: 'id = ?',
          whereArgs: [event.data['id']],
        );
         _log.info('Applied delete to ${event.table} for id: ${event.data['id']}');
        break;
    }
    _invalidateProviderForTable(event.table);
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

  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
      _container.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.disconnected);
    }
  }

  void send(SyncEvent event) {
    if (_channel != null) {
      final payload = {
        'type': 'sync_event',
        ...event.toJson(),
      };
      final message = jsonEncode(payload);
      _channel!.sink.add(message);
    }
  }
}

final syncClientProvider = Provider((ref) => SyncClient(ref.container));
final databaseServiceProvider = Provider((ref) => DatabaseService.instance);