import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Appointment', () {
    test('toJson and fromJson should be consistent', () {
      final now = DateTime.now();
      final appointment = Appointment(
        id: 1,
        patientId: 101,
        dateTime: now,
        status: AppointmentStatus.waiting,
      );

      final json = appointment.toJson();
      final decodedAppointment = Appointment.fromJson(json);

      expect(decodedAppointment.id, appointment.id);
      expect(decodedAppointment.patientId, appointment.patientId);
      expect(
        decodedAppointment.dateTime.toIso8601String(),
        appointment.dateTime.toIso8601String(),
      );
      expect(decodedAppointment.status, appointment.status);
    });

    test('fromJson should handle missing status gracefully', () {
      final json = {
        'id': 2,
        'patientId': 102,
        'dateTime': DateTime.now().toIso8601String(),
      };
      final appointment = Appointment.fromJson(json);

      expect(appointment.id, 2);
      expect(appointment.patientId, 102);
      expect(appointment.status, AppointmentStatus.waiting); // Default value
    });

    test('fromJson should handle unknown status gracefully', () {
      final json = {
        'id': 3,
        'patientId': 103,
        'dateTime': DateTime.now().toIso8601String(),
        'status': 'AppointmentStatus.unknown', // Unknown status
      };
      final appointment = Appointment.fromJson(json);

      expect(appointment.id, 3);
      expect(appointment.patientId, 103);
      expect(
        appointment.status,
        AppointmentStatus.waiting,
      ); // Fallback to default
    });
  });
}
