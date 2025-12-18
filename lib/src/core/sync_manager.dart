import 'dart:async';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:dentaltid/src/core/user_model.dart';
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

/// Manager for coordinating data synchronization between devices
class SyncManager {
  final Logger _logger = Logger('SyncManager');
  final Uuid _uuid = const Uuid();

  final DataSyncService _syncService;
  final PatientService _patientService;
  final AppointmentService _appointmentService;
  final FinanceService _financeService;
  final InventoryService _inventoryService;

  StreamSubscription<SyncMessage>? _syncSubscription;
  Timer? _pingTimer;
  Timer? _broadcastTimer;

  String? _currentDeviceId;
  UserProfile? _currentUser;

  /// Stream of sync status updates
  final StreamController<Map<String, dynamic>> _statusController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get syncStatus => _statusController.stream;

  SyncManager({
    required PatientService patientService,
    required AppointmentService appointmentService,
    required FinanceService financeService,
    required InventoryService inventoryService,
  }) : _syncService = DataSyncService(),
       _patientService = patientService,
       _appointmentService = appointmentService,
       _financeService = financeService,
       _inventoryService = inventoryService {
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

    _logger.info('SyncManager initialized with device ID: $_currentDeviceId');
  }

  /// Initialize as dentist server
  Future<void> initializeAsServer(UserProfile dentistProfile) async {
    _currentUser = dentistProfile;

    try {
      // Start discovery broadcasting
      final discoveryService = NetworkDiscoveryService();
      await discoveryService.startBroadcasting(
        serverId: dentistProfile.uid,
        clinicName: dentistProfile.clinicName ?? 'Unknown Clinic',
        dentistName: dentistProfile.dentistName ?? 'Unknown Dentist',
      );

      // Start sync server
      await _syncService.startServer(
        serverId: dentistProfile.uid,
        dentistProfile: dentistProfile,
      );

      // Start broadcasting sync status
      _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _broadcastSyncStatus();
      });

      _statusController.add({
        'type': 'server_started',
        'deviceId': _currentDeviceId,
        'connectedClients': _syncService.connectedClientsCount,
      });

      _logger.info(
        'SyncManager initialized as server for dentist: ${dentistProfile.dentistName}',
      );
    } catch (e) {
      _logger.severe('Failed to initialize as server: $e');
      rethrow;
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

  Future<void> _handlePatientSync(SyncMessage message) async {
    final patient = Patient.fromJson(message.data);

    switch (message.operation) {
      case 'create':
        await _patientService.addPatient(patient);
        break;
      case 'update':
        await _patientService.updatePatient(patient);
        break;
      case 'delete':
        if (patient.id != null) {
          await _patientService.deletePatient(patient.id!);
        }
        break;
    }
  }

  Future<void> _handleAppointmentSync(SyncMessage message) async {
    final appointment = Appointment.fromJson(message.data);

    switch (message.operation) {
      case 'create':
        await _appointmentService.addAppointment(appointment);
        break;
      case 'update':
        await _appointmentService.updateAppointment(appointment);
        break;
      case 'delete':
        if (appointment.id != null) {
          await _appointmentService.deleteAppointment(appointment.id!);
        }
        break;
    }
  }

  Future<void> _handleTransactionSync(SyncMessage message) async {
    final transaction = finance.Transaction.fromJson(message.data);

    switch (message.operation) {
      case 'create':
        await _financeService.addTransaction(transaction);
        break;
      case 'update':
        await _financeService.updateTransaction(transaction);
        break;
      case 'delete':
        if (transaction.id != null) {
          await _financeService.deleteTransaction(transaction.id!);
        }
        break;
    }
  }

  Future<void> _handleInventorySync(SyncMessage message) async {
    final item = InventoryItem.fromJson(message.data);

    switch (message.operation) {
      case 'create':
        await _inventoryService.addInventoryItem(item);
        break;
      case 'update':
        await _inventoryService.updateInventoryItem(item);
        break;
      case 'delete':
        if (item.id != null) {
          await _inventoryService.deleteInventoryItem(item.id!);
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
