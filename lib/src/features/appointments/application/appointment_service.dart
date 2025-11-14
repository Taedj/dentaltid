import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/exceptions.dart';
import 'package:dentaltid/src/features/appointments/data/appointment_repository.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(DatabaseService.instance);
});

final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService(
    ref.watch(appointmentRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final service = ref.watch(appointmentServiceProvider);
  return service.getAppointments();
});

final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final service = ref.watch(appointmentServiceProvider);
  return service.getUpcomingAppointments();
});

final waitingAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final service = ref.watch(appointmentServiceProvider);
  return service.getAppointmentsByStatusForDate(
    DateTime.now(),
    AppointmentStatus.waiting,
  );
});

final inProgressAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final service = ref.watch(appointmentServiceProvider);
  return service.getAppointmentsByStatusForDate(
    DateTime.now(),
    AppointmentStatus.inProgress,
  );
});

final completedAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final service = ref.watch(appointmentServiceProvider);
  return service.getAppointmentsByStatusForDate(
    DateTime.now(),
    AppointmentStatus.completed,
  );
});

final todaysAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final service = ref.watch(appointmentServiceProvider);
  return service.getTodaysAppointments();
});

final todaysEmergencyAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final emergencyPatientsAsync = ref.watch(
    patientsProvider(PatientFilter.emergency),
  );
  final repository = ref.watch(appointmentRepositoryProvider);

  return emergencyPatientsAsync.when(
    data: (emergencyPatients) {
      if (emergencyPatients.isEmpty) return Future.value([]);
      final emergencyPatientIds = emergencyPatients
          .where((p) => p.id != null)
          .map((p) => p.id!)
          .toList();
      return repository.getTodaysAppointmentsForEmergencyPatients(
        emergencyPatientIds,
      );
    },
    loading: () => Future.value([]),
    error: (error, stack) => Future.value([]),
  );
});

class AppointmentService {
  final AppointmentRepository _repository;
  final AuditService _auditService;

  AppointmentService(this._repository, this._auditService);

  Future<void> addAppointment(Appointment appointment) async {
    try {
      // Check for existing appointment with same patient and dateTime
      final existingAppointment = await _repository
          .getAppointmentByPatientAndDateTime(
            appointment.patientId,
            appointment.dateTime,
          );
      if (existingAppointment != null) {
        throw DuplicateEntryException(
          'An appointment for this patient at this date and time already exists.',
          entity: 'Appointment',
          duplicateValue:
              'Patient ID: ${appointment.patientId}, DateTime: ${appointment.dateTime}',
        );
      }
      await _repository.createAppointment(appointment);
      _auditService.logEvent(
        AuditAction.createAppointment,
        details:
            'Appointment for patient ${appointment.patientId} on ${appointment.dateTime} created.',
      );
      // Provider invalidation is handled by the UI to avoid circular dependencies
    } catch (e) {
      // Log the error for debugging
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
    // Provider invalidation is handled by the UI to avoid circular dependencies
  }

  Future<void> deleteAppointment(int id) async {
    await _repository.deleteAppointment(id);
    _auditService.logEvent(
      AuditAction.deleteAppointment,
      details: 'Appointment with ID $id deleted.',
    );
    // Provider invalidation is handled by the UI to avoid circular dependencies
  }

  Future<void> updateAppointmentStatus(int id, AppointmentStatus status) async {
    await _repository.updateAppointmentStatus(id, status);
    _auditService.logEvent(
      AuditAction.updateAppointment,
      details: 'Appointment with ID $id status updated to ${status.name}.',
    );
    // Provider invalidation is handled by the UI to avoid circular dependencies
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
}
