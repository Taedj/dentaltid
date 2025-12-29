import 'dart:convert';
import 'prescription_medicine.dart';

class Prescription {
  final int? id;
  final String dentistId;
  final int patientId;
  final int? visitId;
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
  final String? logoPath;
  final String? backgroundImagePath;
  final double backgroundOpacity;

  const Prescription({
    this.id,
    required this.dentistId,
    required this.patientId,
    this.visitId,
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
    this.logoPath,
    this.backgroundImagePath,
    this.backgroundOpacity = 0.2,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dentistId': dentistId,
        'patientId': patientId,
        'visitId': visitId,
        'orderNumber': orderNumber,
        'date': date.toIso8601String(),
        'patientName': patientName,
        'patientFamilyName': patientFamilyName,
        'patientAge': patientAge,
        'medicines': jsonEncode(medicines.map((m) => m.toJson()).toList()),
        'templateId': templateId,
        'notes': notes,
        'advice': advice,
        'qrContent': qrContent,
        'logoPath': logoPath,
        'backgroundImagePath': backgroundImagePath,
        'backgroundOpacity': backgroundOpacity,
      };

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final medicinesData = json['medicines'];
    List<PrescriptionMedicine> parsedMedicines = [];

    if (medicinesData is String) {
      final List<dynamic> decoded = jsonDecode(medicinesData);
      parsedMedicines = decoded
          .map((m) => PrescriptionMedicine.fromJson(m as Map<String, dynamic>))
          .toList();
    } else if (medicinesData is List) {
      parsedMedicines = medicinesData
          .map((m) => PrescriptionMedicine.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return Prescription(
      id: json['id'],
      dentistId: json['dentistId'],
      patientId: json['patientId'],
      visitId: json['visitId'],
      orderNumber: json['orderNumber'],
      date: DateTime.parse(json['date']),
      patientName: json['patientName'],
      patientFamilyName: json['patientFamilyName'],
      patientAge: json['patientAge'],
      medicines: parsedMedicines,
      templateId: json['templateId'],
      notes: json['notes'],
      advice: json['advice'],
      qrContent: json['qrContent'],
      logoPath: json['logoPath'],
      backgroundImagePath: json['backgroundImagePath'],
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 0.2,
    );
  }

  Prescription copyWith({
    int? id,
    String? dentistId,
    int? patientId,
    int? visitId,
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
    String? logoPath,
    String? backgroundImagePath,
    double? backgroundOpacity,
  }) {
    return Prescription(
      id: id ?? this.id,
      dentistId: dentistId ?? this.dentistId,
      patientId: patientId ?? this.patientId,
      visitId: visitId ?? this.visitId,
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
      logoPath: logoPath ?? this.logoPath,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    );
  }
}
