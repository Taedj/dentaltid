import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final patientAppointmentsProvider =
    StateNotifierProvider.family<
      PatientAppointmentsNotifier,
      AsyncValue<List<Appointment>>,
      int
    >((ref, patientId) {
      final appointmentService = ref.watch(appointmentServiceProvider);
      return PatientAppointmentsNotifier(appointmentService, patientId);
    });

class PatientAppointmentsNotifier
    extends StateNotifier<AsyncValue<List<Appointment>>> {
  PatientAppointmentsNotifier(this._appointmentService, this._patientId)
    : super(const AsyncValue.loading()) {
    _fetchAppointments();
  }

  final AppointmentService _appointmentService;
  final int _patientId;

  Future<void> _fetchAppointments() async {
    try {
      final appointments = await _appointmentService.getAppointmentsForPatient(
        _patientId,
      );
      state = AsyncValue.data(appointments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _fetchAppointments();
  }
}
