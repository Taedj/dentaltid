import 'dart:async';
import 'dart:convert';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/exceptions.dart';
import 'package:dentaltid/src/core/network/sync_client.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:dentaltid/src/core/network/sync_server.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/appointments/data/appointment_repository.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(DatabaseService.instance);
});

final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService(
    ref,
    ref.watch(appointmentRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final service = ref.read(appointmentServiceProvider);
  
  final subscription = service.onDataChanged.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());
  
  return service.getAppointments();
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

  final allPatients = await patientService.getPatients(PatientFilter.all);
  final emergencyPatientIds = allPatients
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
  final Ref _ref;

  final StreamController<void> _dataChangeController = StreamController.broadcast();
  Stream<void> get onDataChanged => _dataChangeController.stream;

  AppointmentService(this._ref, this._repository, this._auditService);

  void _notifyDataChanged() {
    _dataChangeController.add(null);
  }

  void _broadcastChange(SyncAction action, Appointment data) {
    final event = SyncEvent(
      table: 'appointments',
      action: action,
      data: data.toJson(),
    );
    
    final userProfile = _ref.read(userProfileProvider).value;
    if (userProfile?.role == UserRole.dentist) {
        _ref.read(syncServerProvider).broadcast(jsonEncode(event.toJson()));
    } else {
        _ref.read(syncClientProvider).send(event);
    }
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

      _notifyDataChanged();
      _broadcastChange(SyncAction.create, createdAppointment);

      return createdAppointment;
    } catch (e) {
      ErrorHandler.logError(e);
      rethrow;
    }
  }

  Future<List<Appointment>> getAppointments() async {
    return await _repository.getAppointments();
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
    
    _notifyDataChanged();
    _broadcastChange(SyncAction.update, appointment);
  }

  Future<void> deleteAppointment(int id) async {
    final appointment = await _repository.getAppointmentById(id);
    if (appointment == null) {
      throw NotFoundException('Appointment not found', entity: 'Appointment', id: id);
    }
    await _repository.deleteAppointment(id);
    _auditService.logEvent(
      AuditAction.deleteAppointment,
      details: 'Appointment with ID $id deleted.',
    );
    
    _notifyDataChanged();
    _broadcastChange(SyncAction.delete, appointment);
  }

  Future<void> updateAppointmentStatus(int id, AppointmentStatus status) async {
    final appointment = await _repository.getAppointmentById(id);
    if (appointment == null) {
      throw NotFoundException('Appointment not found', entity: 'Appointment', id: id);
    }
    await _repository.updateAppointmentStatus(id, status);
    _auditService.logEvent(
      AuditAction.updateAppointment,
      details: 'Appointment with ID $id status updated to ${status.name}.',
    );
    
    _notifyDataChanged();
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
}