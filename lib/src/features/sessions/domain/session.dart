enum SessionStatus { scheduled, completed, cancelled }

class Session {
  final int? id;
  final int visitId;
  final int sessionNumber;
  final DateTime dateTime;
  final String notes;
  final String treatmentDetails;
  final double totalAmount;
  final double paidAmount;
  final SessionStatus status;

  Session({
    this.id,
    required this.visitId,
    required this.sessionNumber,
    required this.dateTime,
    this.notes = '',
    this.treatmentDetails = '',
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.status = SessionStatus.scheduled,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'visitId': visitId,
    'sessionNumber': sessionNumber,
    'dateTime': dateTime.toIso8601String(),
    'notes': notes,
    'treatmentDetails': treatmentDetails,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'status': status.toString(),
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'],
    visitId: json['visitId'],
    sessionNumber: json['sessionNumber'],
    dateTime: DateTime.parse(json['dateTime']),
    notes: json['notes'] ?? '',
    treatmentDetails: json['treatmentDetails'] ?? '',
    totalAmount: json['totalAmount'] ?? 0.0,
    paidAmount: json['paidAmount'] ?? 0.0,
    status: SessionStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => SessionStatus.scheduled,
    ),
  );

  Session copyWith({
    int? id,
    int? visitId,
    int? sessionNumber,
    DateTime? dateTime,
    String? notes,
    String? treatmentDetails,
    double? totalAmount,
    double? paidAmount,
    SessionStatus? status,
  }) {
    return Session(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      treatmentDetails: treatmentDetails ?? this.treatmentDetails,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
    );
  }
}
