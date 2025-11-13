import 'package:dentaltid/src/features/patients/domain/patient.dart';

class Visit {
  final int? id;
  final int patientId;
  final DateTime dateTime;
  final String reasonForVisit;
  final String notes;
  final String diagnosis;
  final String treatment;
  final int visitNumber;
  final bool isEmergency;
  final EmergencySeverity emergencySeverity;
  final String healthAlerts;
  // Add other fields as needed, e.g., attachments, associated transactions, etc.

  Visit({
    this.id,
    required this.patientId,
    required this.dateTime,
    this.reasonForVisit = '',
    this.notes = '',
    this.diagnosis = '',
    this.treatment = '',
    this.visitNumber = 1,
    this.isEmergency = false,
    this.emergencySeverity = EmergencySeverity.low,
    this.healthAlerts = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'dateTime': dateTime.toIso8601String(),
    'reasonForVisit': reasonForVisit,
    'notes': notes,
    'diagnosis': diagnosis,
    'treatment': treatment,
    'visitNumber': visitNumber,
    'isEmergency': isEmergency ? 1 : 0,
    'emergencySeverity': emergencySeverity.toString(),
    'healthAlerts': healthAlerts,
  };

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
    id: json['id'],
    patientId: json['patientId'],
    dateTime: DateTime.parse(json['dateTime']),
    reasonForVisit: json['reasonForVisit'] ?? '',
    notes: json['notes'] ?? '',
    diagnosis: json['diagnosis'] ?? '',
    treatment: json['treatment'] ?? '',
    visitNumber: json['visitNumber'] ?? 1,
    isEmergency: json['isEmergency'] == 1,
    emergencySeverity: EmergencySeverity.values.firstWhere(
      (e) => e.toString() == json['emergencySeverity'],
      orElse: () => EmergencySeverity.low,
    ),
    healthAlerts: json['healthAlerts'] ?? '',
  );

  Visit copyWith({
    int? id,
    int? patientId,
    DateTime? dateTime,
    String? reasonForVisit,
    String? notes,
    String? diagnosis,
    String? treatment,
    int? visitNumber,
    bool? isEmergency,
    EmergencySeverity? emergencySeverity,
    String? healthAlerts,
  }) {
    return Visit(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      dateTime: dateTime ?? this.dateTime,
      reasonForVisit: reasonForVisit ?? this.reasonForVisit,
      notes: notes ?? this.notes,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      visitNumber: visitNumber ?? this.visitNumber,
      isEmergency: isEmergency ?? this.isEmergency,
      emergencySeverity: emergencySeverity ?? this.emergencySeverity,
      healthAlerts: healthAlerts ?? this.healthAlerts,
    );
  }
}
