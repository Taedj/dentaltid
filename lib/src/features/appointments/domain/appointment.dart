import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';

class Appointment {
  final int? id;
  final int patientId;
  final DateTime date;
  final String time;
  final AppointmentStatus status;

  Appointment({
    this.id,
    required this.patientId,
    required this.date,
    required this.time,
    this.status = AppointmentStatus.waiting,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'date': date.toIso8601String(),
        'time': time,
        'status': status.toString(),
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'],
        patientId: json['patientId'],
        date: DateTime.parse(json['date']),
        time: json['time'],
        status: AppointmentStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
          orElse: () => AppointmentStatus.waiting,
        ),
      );
}
