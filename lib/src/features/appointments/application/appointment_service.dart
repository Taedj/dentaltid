import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/appointments/data/appointment_repository.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(DatabaseService.instance);
});

final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService(ref.watch(appointmentRepositoryProvider));
});

class AppointmentService {
  final AppointmentRepository _repository;

  AppointmentService(this._repository);

  Future<void> addAppointment(Appointment appointment) async {
    await _repository.createAppointment(appointment);
  }

  Future<List<Appointment>> getAppointments() async {
    return await _repository.getAppointments();
  }

  Future<void> updateAppointment(Appointment appointment) async {
    await _repository.updateAppointment(appointment);
  }

  Future<void> deleteAppointment(int id) async {
    await _repository.deleteAppointment(id);
  }
}
