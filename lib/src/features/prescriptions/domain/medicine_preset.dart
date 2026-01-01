import 'dart:convert';
import 'prescription_medicine.dart';

class MedicinePreset {
  final int? id;
  final String name;
  final List<PrescriptionMedicine> medicines;
  final DateTime createdAt;

  MedicinePreset({
    this.id,
    required this.name,
    required this.medicines,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'medicines': jsonEncode(medicines.map((m) => m.toJson()).toList()),
    'createdAt': createdAt.toIso8601String(),
  };

  factory MedicinePreset.fromJson(Map<String, dynamic> json) {
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

    return MedicinePreset(
      id: json['id'],
      name: json['name'],
      medicines: parsedMedicines,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  MedicinePreset copyWith({
    int? id,
    String? name,
    List<PrescriptionMedicine>? medicines,
    DateTime? createdAt,
  }) {
    return MedicinePreset(
      id: id ?? this.id,
      name: name ?? this.name,
      medicines: medicines ?? this.medicines,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
