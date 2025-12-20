import 'dart:async';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/data_sync_service.dart';
import 'package:dentaltid/src/core/network_discovery_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart'
    as finance;
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(
    patientService: ref.watch(patientServiceProvider),
    appointmentService: ref.watch(appointmentServiceProvider),
    financeService: ref.watch(financeServiceProvider),
    inventoryService: ref.watch(inventoryServiceProvider),
    ref: ref,
  );
  
  // Cleanup on provider disposal
  ref.onDispose(() => manager.dispose());
  
  return manager;
});

/// Manager for coordinating data synchronization between devices
class SyncManager {
  final Logger _logger = Logger('SyncManager');
  final Uuid _uuid = const Uuid();

  final DataSyncService _syncService;
  final PatientService _patientService;
  final AppointmentService _appointmentService;
  final FinanceService _financeService;
  final InventoryService _inventoryService;
  final Ref _ref; // Added

  StreamSubscription<SyncMessage>? _syncSubscription;
  Timer? _pingTimer;
  Timer? _broadcastTimer;

  String? _currentDeviceId;
  UserProfile? _currentUser;

  // Logs
  final StreamController<List<String>> _logController = StreamController<List<String>>.broadcast();
  final List<String> _logs = [];
  Stream<List<String>> get logs => _logController.stream;

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    _logs.add('[$timestamp] $message');
    if (_logs.length > 200) _logs.removeAt(0);
    _logController.add(List.from(_logs.reversed));
    _logger.info(message);
  }

  /// Stream of sync status updates
  final StreamController<Map<String, dynamic>> _statusController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get syncStatus => _statusController.stream;
  bool get isServerRunning => _syncService.isServerRunning;

  SyncManager({
    required PatientService patientService,
    required AppointmentService appointmentService,
    required FinanceService financeService,
    required InventoryService inventoryService,
    required Ref ref, // Added
  }) : _syncService = DataSyncService(),
       _patientService = patientService,
       _appointmentService = appointmentService,
       _financeService = financeService,
       _inventoryService = inventoryService,
       _ref = ref // Added to initializer list
       {
    _initialize();
  }

  void _initialize() {
    // Generate unique device ID
    _currentDeviceId = _uuid.v4();

    // Listen for incoming sync messages
    _syncSubscription = _syncService.incomingMessages.listen(
      _handleIncomingSyncMessage,
    );

    // Start ping timer to keep connections alive
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _syncService.ping();
    });

    _addLog('SyncManager initialized with device ID: $_currentDeviceId');
  }

  /// Stop server manually
  Future<void> stopServer() async {
    _syncService.stopServer();
    _broadcastTimer?.cancel();
    _addLog('Server stopped manually.');
    _statusController.add({'type': 'server_stopped'});
  }

  /// Start server manually
    Future<void> startServer(int port) async {
       if (_currentUser == null) {
          _addLog('Attempting to re-fetch user profile for server start...');
          final userProfile = await _ref.read(userProfileProvider.future) as UserProfile?; // Explicit cast
          if (userProfile == null) {
              _addLog('Error: User not initialized (re-fetch failed)');
              throw Exception('User not initialized');
          }
          _currentUser = userProfile;
          _addLog('User profile re-fetched successfully.');
      }
      
      // Stop if running
      if (isServerRunning) {
          await stopServer();
      }
    try {
      // Start discovery broadcasting
      final discoveryService = NetworkDiscoveryService();
      await discoveryService.startBroadcasting(
        serverId: _currentUser!.uid,
        clinicName: _currentUser!.clinicName ?? 'Unknown Clinic',
        dentistName: _currentUser!.dentistName ?? 'Unknown Dentist',
      );

      // Start sync server
      await _syncService.startServer(
        serverId: _currentUser!.uid,
        dentistProfile: _currentUser!,
        port: port,
      );

      // Start broadcasting sync status
      _broadcastTimer?.cancel();
      _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _broadcastSyncStatus();
      });

      _statusController.add({
        'type': 'server_started',
        'deviceId': _currentDeviceId,
        'connectedClients': _syncService.connectedClientsCount,
      });

      _addLog('Server started successfully on port $port');
    } catch (e) {
      _addLog('Failed to start server: $e');
      rethrow;
    }
  }

  /// Initialize as dentist server
  Future<void> initializeAsServer(UserProfile dentistProfile) async {
    _currentUser = dentistProfile;

    try {
      await startServer(DataSyncService.syncPort);
    } catch (e) {
      _logger.severe('Failed to initialize as server: $e');
      // Don't rethrow here to avoid crashing app init, but log it
      _addLog('Auto-start failed: $e');
    }
  }

  /// Initialize as client device
  Future<void> initializeAsClient({
    required DiscoveredServer server,
    required UserProfile userProfile,
  }) async {
    _currentUser = userProfile;

    try {
      // Connect to sync server
      await _syncService.connectToServer(
        server: server,
        clientId: _currentDeviceId!,
        userProfile: userProfile,
      );

      _statusController.add({
        'type': 'client_connected',
        'deviceId': _currentDeviceId,
        'server': server.toString(),
      });

      _logger.info(
        'SyncManager initialized as client connected to: ${server.clinicName}',
      );
      
      // Request initial synchronization immediately after connection
      await Future.delayed(const Duration(milliseconds: 500)); // give time for socket
      _syncService.requestInitialSync();
    } catch (e) {
      _logger.severe('Failed to initialize as client: $e');
      rethrow;
    }
  }

  /// Broadcast local data changes to connected clients
  Future<void> broadcastLocalChange({
    required SyncDataType type,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    if (_currentUser == null || _currentDeviceId == null) {
      _logger.warning('Cannot broadcast: user or device not initialized');
      return;
    }

    final message = SyncMessage(
      id: _uuid.v4(),
      type: type,
      operation: operation,
      data: data,
      timestamp: DateTime.now(),
      deviceId: _currentDeviceId!,
      userId: _currentUser!.uid,
    );

    try {
      await _syncService.broadcastToClients(message);
      _logger.fine('Broadcasted local change: $message');
    } catch (e) {
      _logger.warning('Failed to broadcast local change: $e');
    }
  }

  /// Send local change to server (client mode)
  Future<void> sendToServer({
    required SyncDataType type,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    if (_currentUser == null || _currentDeviceId == null) {
      _logger.warning('Cannot send to server: user or device not initialized');
      return;
    }

    final message = SyncMessage(
      id: _uuid.v4(),
      type: type,
      operation: operation,
      data: data,
      timestamp: DateTime.now(),
      deviceId: _currentDeviceId!,
      userId: _currentUser!.uid,
    );

    try {
      await _syncService.sendToServer(message);
      _logger.fine('Sent change to server: $message');
    } catch (e) {
      _logger.warning('Failed to send change to server: $e');
    }
  }

  /// Handle incoming synchronization messages
  Future<void> _handleIncomingSyncMessage(SyncMessage message) async {
    _logger.fine('Handling incoming sync message: $message');

    try {
      // Skip messages from our own device to prevent echo
      if (message.deviceId == _currentDeviceId) {
        _logger.fine('Skipping own message: ${message.id}');
        return;
      }

      switch (message.type) {
        case SyncDataType.patients:
          await _handlePatientSync(message);
          break;
        case SyncDataType.appointments:
          await _handleAppointmentSync(message);
          break;
        case SyncDataType.transactions:
          await _handleTransactionSync(message);
          break;
        case SyncDataType.inventory:
          await _handleInventorySync(message);
          break;
        case SyncDataType.settings:
          await _handleSettingsSync(message);
          break;
        case SyncDataType.initialSync:
          if (message.operation == 'request_initial_sync') {
            await _handleInitialSyncRequest(message);
          } else if (message.operation == 'initial_sync') {
            await _handleInitialSyncData(message);
          }
          break;
      }

      _statusController.add({
        'type': 'message_processed',
        'messageId': message.id,
        'dataType': message.type.toString(),
        'operation': message.operation,
      });
    } catch (e) {
      _logger.warning('Error handling sync message ${message.id}: $e');
    }
  }

  Future<void> _handleInitialSyncRequest(SyncMessage message) async {
    final clientId = message.data['clientId'];
    if (clientId == null) return;

    _logger.info('Processing initial sync request for client $clientId');

    try {
      // Gather all data
      final patients = await _patientService.getPatients();
      final appointments = await _appointmentService.getAppointments();
      final transactions = await _financeService.getTransactions();
      final inventory = await _inventoryService.getInventoryItems();

      final syncData = {
        'patients': patients.map((e) => e.toJson()).toList(),
        'appointments': appointments.map((e) => e.toJson()).toList(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'inventory': inventory.map((e) => e.toJson()).toList(),
      };

      _syncService.sendInitialSyncData(clientId, syncData);
      _logger.info('Sent initial sync data to $clientId');
    } catch (e) {
      _logger.severe('Failed to process initial sync request: $e');
    }
  }

  Future<void> _handleInitialSyncData(SyncMessage message) async {
    _logger.info('Processing initial sync data...');
    _statusController.add({
      'type': 'sync_status',
      'status': 'syncing',
      'message': 'Starting initial synchronization...',
    });

    try {
      final data = message.data;
      
      // Process patients
      if (data.containsKey('patients')) {
        final patientsList = data['patients'] as List;
        int count = 0;
        for (final item in patientsList) {
          try {
            final patient = Patient.fromJson(item);
            // Try to create, if exists update (or ignore if handled by service)
            // Ideally services should support upsert. 
            // For now, we'll try fetch and determine.
            try {
               // Check if patient exists (by ID or other unique constraint)
               // This is tricky without simple upsert.
               // We will use a try-catch pattern assuming ID helps.
               if (patient.id != null) {
                  await _patientService.getPatientById(patient.id!);
                  await _patientService.updatePatient(patient, broadcast: false);
               } else {
                  await _patientService.addPatient(patient, broadcast: false);
               }
            } catch (e) {
               // If not found or error, try add
               try {
                 await _patientService.addPatient(patient, broadcast: false);
               } catch (_) {
                 // Duplicate maybe?
               }
            }
            count++;
          } catch (e) {
            _logger.warning('Failed to sync patient: $e');
          }
        }
        _logger.info('Synced $count patients');
      }

      // Process appointments
      if (data.containsKey('appointments')) {
        final list = data['appointments'] as List;
        for (final item in list) {
          try {
            final obj = Appointment.fromJson(item);
            if (obj.id != null) {
               try {
                 await _appointmentService.deleteAppointment(obj.id!, broadcast: false);
               } catch (_) {}
            }
            // Add freshly to ensure clean state or update
            // Since we deleted, we add. But IDs might conflict if auto-increment is used improperly.
            // Best approach for SQLite sync without 'INSERT OR REPLACE' is tricky.
            // Let's assume we update if ID exists.
            // Actually, appointment service `addAppointment` checks for duplicates.
            // We should use a lower level "force save" if possible, but service is okay.
            try {
              await _appointmentService.addAppointment(obj, broadcast: false);
            } catch (e) {
               if (e.toString().contains('Duplicate')) {
                  await _appointmentService.updateAppointment(obj, broadcast: false);
               }
            }
          } catch (e) {
             _logger.warning('Failed to sync appointment: $e');
          }
        }
      }

      // Process transactions
      if (data.containsKey('transactions')) {
        final list = data['transactions'] as List;
        for (final item in list) {
          try {
            final obj = finance.Transaction.fromJson(item);
             if (obj.id != null) {
               // Try update, if fails add?
               // Finance service `addTransaction` is standard.
               try {
                  await _financeService.addTransaction(obj, broadcast: false);
               } catch (_) {
                  await _financeService.updateTransaction(obj, broadcast: false);
               }
             }
          } catch (e) {
            _logger.warning('Failed to sync transaction: $e');
          }
        }
      }

      // Process inventory
      if (data.containsKey('inventory')) {
        final list = data['inventory'] as List;
        for (final item in list) {
          try {
            final obj = InventoryItem.fromJson(item);
             if (obj.id != null) {
               final existing = await _inventoryService.getInventoryItem(obj.id!);
               if (existing != null) {
                  await _inventoryService.updateInventoryItem(obj, broadcast: false);
               } else {
                  await _inventoryService.addInventoryItem(obj, broadcast: false);
               }
             }
          } catch (e) {
            _logger.warning('Failed to sync inventory: $e');
          }
        }
      }

      _statusController.add({
        'type': 'sync_status',
        'status': 'synced',
        'message': 'Initial synchronization complete',
      });
      _logger.info('Initial sync completed successfully');

    } catch (e) {
      _logger.severe('Failed to process initial sync data: $e');
      _statusController.add({
        'type': 'sync_status',
        'status': 'error',
        'message': 'Sync failed: $e',
      });
    }
  }

  Future<void> _handlePatientSync(SyncMessage message) async {
    final patient = Patient.fromJson(message.data);

    switch (message.operation) {
      case 'create':
        await _patientService.addPatient(patient, broadcast: false);
        break;
      case 'update':
        await _patientService.updatePatient(patient, broadcast: false);
        break;
      case 'delete':
        if (patient.id != null) {
          await _patientService.deletePatient(patient.id!, broadcast: false);
        }
        break;
    }
  }

  Future<void> _handleAppointmentSync(SyncMessage message) async {
    final appointment = Appointment.fromJson(message.data);

    switch (message.operation) {
      case 'create':
        await _appointmentService.addAppointment(appointment, broadcast: false);
        break;
      case 'update':
        await _appointmentService.updateAppointment(appointment, broadcast: false);
        break;
      case 'delete':
        if (appointment.id != null) {
          await _appointmentService.deleteAppointment(appointment.id!, broadcast: false);
        }
        break;
    }
  }

  Future<void> _handleTransactionSync(SyncMessage message) async {
    final transaction = finance.Transaction.fromJson(message.data);

    switch (message.operation) {
      case 'create':
        await _financeService.addTransaction(transaction, broadcast: false);
        break;
      case 'update':
        await _financeService.updateTransaction(transaction, broadcast: false);
        break;
      case 'delete':
        if (transaction.id != null) {
          await _financeService.deleteTransaction(transaction.id!, broadcast: false);
        }
        break;
    }
  }

  Future<void> _handleInventorySync(SyncMessage message) async {
    final item = InventoryItem.fromJson(message.data);

    switch (message.operation) {
      case 'create':
        await _inventoryService.addInventoryItem(item, broadcast: false);
        break;
      case 'update':
        await _inventoryService.updateInventoryItem(item, broadcast: false);
        break;
      case 'delete':
        if (item.id != null) {
          await _inventoryService.deleteInventoryItem(item.id!, broadcast: false);
        }
        break;
    }
  }

  Future<void> _handleSettingsSync(SyncMessage message) async {
    // Handle settings synchronization
    // This would update local settings based on server changes
    _logger.info('Settings sync not yet implemented: ${message.data}');
  }

  /// Broadcast current sync status
  void _broadcastSyncStatus() {
    _statusController.add({
      'type': 'status_update',
      'deviceId': _currentDeviceId,
      'connectedClients': _syncService.connectedClientsCount,
      'isConnected': _syncService.isConnected,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get synchronization statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'deviceId': _currentDeviceId,
      'connectedClients': _syncService.connectedClientsCount,
      'isConnected': _syncService.isConnected,
      'userRole': _currentUser?.role.toString(),
      'clinicName': _currentUser?.clinicName,
    };
  }

  /// Stop all synchronization services
  void stopSync() {
    _logger.info('Stopping sync manager...');

    _syncSubscription?.cancel();
    _pingTimer?.cancel();
    _broadcastTimer?.cancel();

    _syncService.dispose();
    _statusController.close();

    _logger.info('Sync manager stopped');
  }

  /// Dispose of resources
  void dispose() {
    stopSync();
  }
}
