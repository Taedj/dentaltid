import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';

class Appointment {
  final int? id;
  final int sessionId;
  final DateTime dateTime; // Combined date and time
  final AppointmentStatus status;

  // Temporary getter for backward compatibility - will be removed when UI is updated
  int get patientId => sessionId;

  Appointment({
    this.id,
    required this.sessionId,
    required this.dateTime,
    this.status = AppointmentStatus.waiting,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'dateTime': dateTime.toIso8601String(), // Store combined DateTime
    'status': status.toString(),
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'],
    sessionId: json['sessionId'],
    dateTime: DateTime.parse(json['dateTime']), // Parse combined DateTime
    status: AppointmentStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => AppointmentStatus.waiting,
    ),
  );
}
