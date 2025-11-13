class Visit {
  final int? id;
  final int patientId;
  final DateTime dateTime;
  final String reasonForVisit;
  final String notes;
  final String diagnosis;
  final String treatment;
  // Add other fields as needed, e.g., attachments, associated transactions, etc.

  Visit({
    this.id,
    required this.patientId,
    required this.dateTime,
    this.reasonForVisit = '',
    this.notes = '',
    this.diagnosis = '',
    this.treatment = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'dateTime': dateTime.toIso8601String(),
    'reasonForVisit': reasonForVisit,
    'notes': notes,
    'diagnosis': diagnosis,
    'treatment': treatment,
  };

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
    id: json['id'],
    patientId: json['patientId'],
    dateTime: DateTime.parse(json['dateTime']),
    reasonForVisit: json['reasonForVisit'] ?? '',
    notes: json['notes'] ?? '',
    diagnosis: json['diagnosis'] ?? '',
    treatment: json['treatment'] ?? '',
  );

  Visit copyWith({
    int? id,
    int? patientId,
    DateTime? dateTime,
    String? reasonForVisit,
    String? notes,
    String? diagnosis,
    String? treatment,
  }) {
    return Visit(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      dateTime: dateTime ?? this.dateTime,
      reasonForVisit: reasonForVisit ?? this.reasonForVisit,
      notes: notes ?? this.notes,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
    );
  }
}
