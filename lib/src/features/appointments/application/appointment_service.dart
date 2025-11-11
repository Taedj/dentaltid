import 'package:dentaltid/src/core/database_service.dart';
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
    ref,
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
  return emergencyPatientsAsync.when(
    data: (emergencyPatients) {
      if (emergencyPatients.isEmpty) return Future.value([]);
      final service = ref.watch(appointmentServiceProvider);
      final emergencyPatientIds = emergencyPatients
          .where((p) => p.id != null)
          .map((p) => p.id!)
          .toList();
      return service.getTodaysAppointmentsForEmergencyPatients(
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
  final Ref _ref;

  AppointmentService(this._repository, this._auditService, this._ref);

  Future<void> addAppointment(Appointment appointment) async {
    final existingAppointment = await _repository.getAppointmentByDetails(
      appointment.patientId,
      appointment.date,
      appointment.time,
    );
    if (existingAppointment != null) {
      throw Exception(
        'An appointment for this patient at this date and time already exists.',
      );
    }
    await _repository.createAppointment(appointment);
    _auditService.logEvent(
      AuditAction.createAppointment,
      details:
          'Appointment for patient ${appointment.patientId} on ${appointment.date} at ${appointment.time} created.',
    );
    // Invalidate all appointment providers to refresh the UI
    _ref.invalidate(appointmentsProvider);
    _ref.invalidate(upcomingAppointmentsProvider);
    _ref.invalidate(waitingAppointmentsProvider);
    _ref.invalidate(inProgressAppointmentsProvider);
    _ref.invalidate(completedAppointmentsProvider);
    _ref.invalidate(todaysAppointmentsProvider);
    _ref.invalidate(todaysEmergencyAppointmentsProvider);
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
          'Appointment for patient ${appointment.patientId} on ${appointment.date} at ${appointment.time} updated.',
    );
    // Invalidate all appointment providers to refresh the UI
    _ref.invalidate(appointmentsProvider);
    _ref.invalidate(upcomingAppointmentsProvider);
    _ref.invalidate(waitingAppointmentsProvider);
    _ref.invalidate(inProgressAppointmentsProvider);
    _ref.invalidate(completedAppointmentsProvider);
    _ref.invalidate(todaysAppointmentsProvider);
  }

  Future<void> deleteAppointment(int id) async {
    await _repository.deleteAppointment(id);
    _auditService.logEvent(
      AuditAction.deleteAppointment,
      details: 'Appointment with ID $id deleted.',
    );
    // Invalidate all appointment providers to refresh the UI
    _ref.invalidate(appointmentsProvider);
    _ref.invalidate(upcomingAppointmentsProvider);
    _ref.invalidate(waitingAppointmentsProvider);
    _ref.invalidate(inProgressAppointmentsProvider);
    _ref.invalidate(completedAppointmentsProvider);
    _ref.invalidate(todaysAppointmentsProvider);
  }

  Future<void> updateAppointmentStatus(int id, AppointmentStatus status) async {
    await _repository.updateAppointmentStatus(id, status);
    _auditService.logEvent(
      AuditAction.updateAppointment,
      details: 'Appointment with ID $id status updated to ${status.name}.',
    );
    // Invalidate all appointment providers to refresh the UI
    _ref.invalidate(appointmentsProvider);
    _ref.invalidate(upcomingAppointmentsProvider);
    _ref.invalidate(waitingAppointmentsProvider);
    _ref.invalidate(inProgressAppointmentsProvider);
    _ref.invalidate(completedAppointmentsProvider);
    _ref.invalidate(todaysAppointmentsProvider);
  }

  Future<List<Appointment>> getAppointmentsByStatusForDate(
    DateTime date,
    AppointmentStatus status,
  ) async {
    return await _repository.getAppointmentsByStatusForDate(date, status);
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
