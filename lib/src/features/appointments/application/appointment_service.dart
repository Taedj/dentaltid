import 'dart:async';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/exceptions.dart';
import 'package:dentaltid/src/core/network/sync_broadcaster.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:dentaltid/src/features/appointments/data/appointment_repository.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_with_payment.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(DatabaseService.instance);
});

final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService(
    ref,
    ref.watch(appointmentRepositoryProvider),
    ref.watch(auditServiceProvider),
    ref.watch(financeServiceProvider),
  );
});

class AppointmentListConfig extends Equatable {
  final String query;
  final AppointmentStatus? status;
  final bool upcomingOnly;
  final SortOption sortOption;
  final int page;
  final int pageSize;

  const AppointmentListConfig({
    this.query = '',
    this.status,
    this.upcomingOnly = false,
    this.sortOption = SortOption.dateTimeAsc,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props =>
      [query, status, upcomingOnly, sortOption, page, pageSize];
}

final appointmentsProvider =
    FutureProvider.family<PaginatedAppointments, AppointmentListConfig>(
        (ref, config) async {
  final service = ref.read(appointmentServiceProvider);

  final subscription = service.onDataChanged.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());

  return service.getAppointments(
    searchQuery: config.query,
    statusFilter: config.status,
    upcomingOnly: config.upcomingOnly,
    sortOption: config.sortOption,
    page: config.page,
    pageSize: config.pageSize,
  );
});

final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final service = ref.read(appointmentServiceProvider);

  final subscription = service.onDataChanged.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());

  return service.getUpcomingAppointments();
});

final waitingAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final service = ref.read(appointmentServiceProvider);

  final subscription = service.onDataChanged.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());

  return service.getAppointmentsByStatusForDate(
    DateTime.now(),
    AppointmentStatus.waiting,
  );
});

final inProgressAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final service = ref.read(appointmentServiceProvider);

  final subscription = service.onDataChanged.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());

  return service.getAppointmentsByStatusForDate(
    DateTime.now(),
    AppointmentStatus.inProgress,
  );
});

final completedAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final service = ref.read(appointmentServiceProvider);

  final subscription = service.onDataChanged.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());

  return service.getAppointmentsByStatusForDate(
    DateTime.now(),
    AppointmentStatus.completed,
  );
});

final todaysAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final service = ref.read(appointmentServiceProvider);

  final subscription = service.onDataChanged.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());

  return service.getTodaysAppointments();
});

final todaysEmergencyAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final appointmentService = ref.read(appointmentServiceProvider);
  final patientService = ref.read(patientServiceProvider);

  final appSubscription = appointmentService.onDataChanged.listen((_) {
    ref.invalidateSelf();
  });
  final patSubscription = patientService.onDataChanged.listen((_) {
    ref.invalidateSelf();
  });

  ref.onDispose(() {
    appSubscription.cancel();
    patSubscription.cancel();
  });

  final allPatientsResult = await patientService.getPatients(
    filter: PatientFilter.emergency,
    pageSize: 1000, // Safe limit for emergency patients
  );
  final emergencyPatientIds = allPatientsResult.patients
      .where((p) => p.isEmergency)
      .map((p) => p.id)
      .whereType<int>()
      .toSet();

  final todaysAppointments = await appointmentService.getTodaysAppointments();

  return todaysAppointments.where((a) {
    final isEmergencyPatient = emergencyPatientIds.contains(a.patientId);
    final isEmergencyType = a.appointmentType.toLowerCase() == 'emergency';
    final isActive =
        a.status != AppointmentStatus.completed &&
        a.status != AppointmentStatus.cancelled;

    return (isEmergencyPatient || isEmergencyType) && isActive;
  }).toList();
});

class AppointmentService {
  final AppointmentRepository _repository;
  final AuditService _auditService;
  final FinanceService _financeService;
  final Ref _ref;

  final StreamController<void> _dataChangeController =
      StreamController.broadcast();
  Stream<void> get onDataChanged => _dataChangeController.stream;

  AppointmentService(
    this._ref,
    this._repository,
    this._auditService,
    this._financeService,
  );

  void notifyDataChanged() {
    _dataChangeController.add(null);
  }

  void _broadcastChange(SyncAction action, Appointment data) {
    _ref
        .read(syncBroadcasterProvider)
        .broadcast(table: 'appointments', action: action, data: data.toJson());
  }

  Future<Appointment> addAppointment(Appointment appointment) async {
    try {
      final existingAppointment = await _repository
          .getAppointmentByPatientAndDateTime(
            appointment.patientId,
            appointment.dateTime,
          );
      if (existingAppointment != null) {
        throw DuplicateEntryException(
          'An appointment for this patient already exists within 30 minutes of the requested time.',
          entity: 'Appointment',
          duplicateValue:
              'Patient ID: ${appointment.patientId}, Requested: ${appointment.dateTime}, Existing: ${existingAppointment.dateTime}',
        );
      }
      final createdAppointment = await _repository.createAppointment(
        appointment,
      );
      _auditService.logEvent(
        AuditAction.createAppointment,
        details:
            'Appointment for patient ${createdAppointment.patientId} on ${createdAppointment.dateTime} created.',
      );

      notifyDataChanged();
      _broadcastChange(SyncAction.create, createdAppointment);

      return createdAppointment;
    } catch (e) {
      ErrorHandler.logError(e);
      rethrow;
    }
  }

  Future<PaginatedAppointments> getAppointments({
    String? searchQuery,
    AppointmentStatus? statusFilter,
    bool upcomingOnly = false,
    SortOption? sortOption,
    int? page,
    int? pageSize,
  }) async {
    return await _repository.getAppointments(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      upcomingOnly: upcomingOnly,
      sortOption: sortOption,
      page: page ?? 1,
      pageSize: pageSize ?? 20,
    );
  }

  Future<List<Appointment>> getUpcomingAppointments() async {
    return await _repository.getUpcomingAppointments();
  }

  Future<void> updateAppointment(Appointment appointment) async {
    await _repository.updateAppointment(appointment);
    _auditService.logEvent(
      AuditAction.updateAppointment,
      details:
          'Appointment for patient ${appointment.patientId} on ${appointment.dateTime} updated.',
    );

    notifyDataChanged();
    _broadcastChange(SyncAction.update, appointment);
  }

  Future<void> deleteAppointment(int id) async {
    final appointment = await _repository.getAppointmentById(id);
    if (appointment == null) {
      throw NotFoundException(
        'Appointment not found',
        entity: 'Appointment',
        id: id,
      );
    }
    await _repository.deleteAppointment(id);
    _auditService.logEvent(
      AuditAction.deleteAppointment,
      details: 'Appointment with ID $id deleted.',
    );

    notifyDataChanged();
    _broadcastChange(SyncAction.delete, appointment);
  }

  Future<void> deleteAppointmentsByPatientId(int patientId) async {
    await _repository.deleteAppointmentsByPatientId(patientId);
    notifyDataChanged();
  }

  Future<void> updateAppointmentStatus(int id, AppointmentStatus status) async {
    final appointment = await _repository.getAppointmentById(id);
    if (appointment == null) {
      throw NotFoundException(
        'Appointment not found',
        entity: 'Appointment',
        id: id,
      );
    }
    await _repository.updateAppointmentStatus(id, status);
    _auditService.logEvent(
      AuditAction.updateAppointment,
      details: 'Appointment with ID $id status updated to ${status.name}.',
    );

    notifyDataChanged();
    _broadcastChange(SyncAction.update, appointment.copyWith(status: status));
  }

  Future<List<Appointment>> getAppointmentsByStatusForDate(
    DateTime dateTime,
    AppointmentStatus status,
  ) async {
    return await _repository.getAppointmentsByStatusForDate(dateTime, status);
  }

  Future<List<Appointment>> getTodaysAppointments() async {
    return await _repository.getTodaysAppointments();
  }

  Future<List<Appointment>> getTodaysAppointmentsForEmergencyPatients(
    List<int> emergencyPatientIds,
  ) async {
    return await _repository.getTodaysAppointmentsForEmergencyPatients(
      emergencyPatientIds,
    );
  }

  Future<List<Appointment>> getAppointmentsForPatient(int patientId) async {
    return await _repository.getAppointmentsForPatient(patientId);
  }

  Future<void> saveAppointmentWithPayment(AppointmentWithPayment data) async {
    Appointment appointment = data.appointment;

    // First, save the appointment itself (create or update)

    if (appointment.id == null) {
      final savedAppointment = await addAppointment(appointment);

      appointment = savedAppointment; // Get the ID for the transaction
    } else {
      await updateAppointment(appointment);
    }

    // Next, handle the financial transaction

    if (data.totalCost > 0 || data.paidAmount > 0) {
      final existingTransactions = await _financeService
          .getTransactionsBySessionId(appointment.id!);

      if (existingTransactions.isNotEmpty) {
        // Update the existing transaction

        final latestTransaction = existingTransactions.reduce(
          (a, b) => a.date.isAfter(b.date) ? a : b,
        );

        final updatedTransaction = latestTransaction.copyWith(
          description: 'Appointment payment for ${appointment.appointmentType}',

          totalAmount: data.totalCost,

          paidAmount: data.paidAmount,

          category: appointment.appointmentType,
        );

        await _financeService.updateTransaction(updatedTransaction);
      } else {
        // Create a new transaction

        final transaction = Transaction(
          sessionId: appointment.id!,

          description: 'Appointment payment for ${appointment.appointmentType}',

          totalAmount: data.totalCost,

          paidAmount: data.paidAmount,

          type: TransactionType.income,

          date: DateTime.now(),

          sourceType: TransactionSourceType.appointment,

          sourceId: appointment.id,

          category: appointment.appointmentType,
        );

        await _financeService.addTransaction(transaction);
      }
    }
  }
}
