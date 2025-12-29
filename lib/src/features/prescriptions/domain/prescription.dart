import 'prescription_medicine.dart';

class Prescription {
  final int? id;
  final String dentistId;
  final int patientId;
  final int orderNumber;
  final DateTime date;
  final String patientName;
  final String patientFamilyName;
  final int patientAge;
  final List<PrescriptionMedicine> medicines;
  final String? notes;
  final String? advice;
  final String? qrContent;
  final String templateId;

  Prescription({
    this.id,
    required this.dentistId,
    required this.patientId,
    required this.orderNumber,
    required this.date,
    required this.patientName,
    required this.patientFamilyName,
    required this.patientAge,
    required this.medicines,
    required this.templateId,
    this.notes,
    this.advice,
    this.qrContent,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dentistId': dentistId,
    'patientId': patientId,
    'orderNumber': orderNumber,
    'date': date.toIso8601String(),
    'patientName': patientName,
    'patientFamilyName': patientFamilyName,
    'patientAge': patientAge,
    'medicines': medicines.map((m) => m.toJson()).toList(),
    'templateId': templateId,
    'notes': notes,
    'advice': advice,
    'qrContent': qrContent,
  };

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
    id: json['id'],
    dentistId: json['dentistId'],
    patientId: json['patientId'],
    orderNumber: json['orderNumber'],
    date: DateTime.parse(json['date']),
    patientName: json['patientName'],
    patientFamilyName: json['patientFamilyName'],
    patientAge: json['patientAge'],
    medicines: (json['medicines'] as List)
        .map((m) => PrescriptionMedicine.fromJson(m as Map<String, dynamic>))
        .toList(),
    templateId: json['templateId'],
    notes: json['notes'],
    advice: json['advice'],
    qrContent: json['qrContent'],
  );

  Prescription copyWith({
    int? id,
    String? dentistId,
    int? patientId,
    int? orderNumber,
    DateTime? date,
    String? patientName,
    String? patientFamilyName,
    int? patientAge,
    List<PrescriptionMedicine>? medicines,
    String? templateId,
    String? notes,
    String? advice,
    String? qrContent,
  }) {
    return Prescription(
      id: id ?? this.id,
      dentistId: dentistId ?? this.dentistId,
      patientId: patientId ?? this.patientId,
      orderNumber: orderNumber ?? this.orderNumber,
      date: date ?? this.date,
      patientName: patientName ?? this.patientName,
      patientFamilyName: patientFamilyName ?? this.patientFamilyName,
      patientAge: patientAge ?? this.patientAge,
      medicines: medicines ?? this.medicines,
      templateId: templateId ?? this.templateId,
      notes: notes ?? this.notes,
      advice: advice ?? this.advice,
      qrContent: qrContent ?? this.qrContent,
    );
  }
}
