import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';

class Appointment {
  final int? id;
  final int patientId;
  final int? visitId; // New field to link to a Visit
  final DateTime dateTime; // Combined date and time
  final AppointmentStatus status;

  Appointment({
    this.id,
    required this.patientId,
    this.visitId, // New field
    required this.dateTime,
    this.status = AppointmentStatus.waiting,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'visitId': visitId,
    'dateTime': dateTime.toIso8601String(), // Store combined DateTime
    'status': status.toString(),
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'],
    patientId: json['patientId'],
    visitId: json['visitId'],
    dateTime: DateTime.parse(json['dateTime']), // Parse combined DateTime
    status: AppointmentStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => AppointmentStatus.waiting,
    ),
  );
}
