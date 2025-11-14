import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';

class Appointment {
  final int? id;
  final int patientId;
  final DateTime dateTime; // Combined date and time
  final AppointmentStatus status;
  final String appointmentType; // New field for appointment type
  final String healthState; // New field for health state during visit
  final String diagnosis; // New field for diagnosis
  final String treatment; // New field for treatment
  final String notes; // New field for notes

  Appointment({
    this.id,
    required this.patientId,
    required this.dateTime,
    this.status = AppointmentStatus.waiting,
    this.appointmentType = '',
    this.healthState = '',
    this.diagnosis = '',
    this.treatment = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId':
        patientId, // Use sessionId column but keep patientId logic for now
    'dateTime': dateTime.toIso8601String(), // Store combined DateTime
    'status': status.toString(),
    'appointmentType': appointmentType,
    'healthState': healthState,
    'diagnosis': diagnosis,
    'treatment': treatment,
    'notes': notes,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'],
    patientId: json['patientId'] ?? json['sessionId'], // Backward compatibility
    dateTime: DateTime.parse(json['dateTime']), // Parse combined DateTime
    status: AppointmentStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => AppointmentStatus.waiting,
    ),
    appointmentType: json['appointmentType'] ?? '',
    healthState: json['healthState'] ?? '',
    diagnosis: json['diagnosis'] ?? '',
    treatment: json['treatment'] ?? '',
    notes: json['notes'] ?? '',
  );

  Appointment copyWith({
    int? id,
    int? patientId,
    DateTime? dateTime,
    AppointmentStatus? status,
    String? appointmentType,
    String? healthState,
    String? diagnosis,
    String? treatment,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      appointmentType: appointmentType ?? this.appointmentType,
      healthState: healthState ?? this.healthState,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      notes: notes ?? this.notes,
    );
  }
}
