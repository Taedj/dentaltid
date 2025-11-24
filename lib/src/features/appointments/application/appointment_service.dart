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

final todaysEmergencyAppointmentsProvider =
    FutureProvider<List<Appointment>>((ref) async {
  final appointmentService = ref.watch(appointmentServiceProvider);
  final patientService = ref.watch(patientServiceProvider);

  // 1. Get all patients and create a set of emergency patient IDs for efficient lookup
  final allPatients = await patientService.getPatients(PatientFilter.all);
  final emergencyPatientIds = allPatients
      .where((p) => p.isEmergency)
      .map((p) => p.id)
      .whereType<int>()
      .toSet();

  // 2. Get all of today's appointments
  final todaysAppointments = await appointmentService.getTodaysAppointments();

  // 3. Filter appointments based on the combined emergency conditions
  return todaysAppointments
      .where((a) {
        final isEmergencyPatient = emergencyPatientIds.contains(a.patientId);
        final isEmergencyType = a.appointmentType.toLowerCase() == 'emergency';
        final isActive = a.status != AppointmentStatus.completed &&
                         a.status != AppointmentStatus.cancelled;

        return (isEmergencyPatient || isEmergencyType) && isActive;
      })
      .toList();
});

class AppointmentService {
  final AppointmentRepository _repository;
  final AuditService _auditService;

  AppointmentService(this._repository, this._auditService);

  Future<Appointment> addAppointment(Appointment appointment) async {
    try {
      // Check for existing appointment with same patient and dateTime
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
      // Provider invalidation is handled by the UI to avoid circular dependencies
      return createdAppointment;
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

  Future<List<Appointment>> getAppointmentsForPatient(int patientId) async {
    return await _repository.getAppointmentsForPatient(patientId);
  }
}
