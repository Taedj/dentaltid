import 'dart:convert';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/prescriptions/domain/prescription.dart';
import 'package:dentaltid/src/features/prescriptions/domain/prescription_medicine.dart';

class PrescriptionRepository {
  final DatabaseService _dbService;

  PrescriptionRepository(this._dbService);

  Future<Prescription> createPrescription(Prescription prescription) async {
    final db = await _dbService.database;
    final id = await db.insert(
      'prescriptions',
      {
        'dentistId': prescription.dentistId,
        'patientId': prescription.patientId,
        'orderNumber': prescription.orderNumber,
        'date': prescription.date.toIso8601String(),
        'patientName': prescription.patientName,
        'patientFamilyName': prescription.patientFamilyName,
        'patientAge': prescription.patientAge,
        'medicines': jsonEncode(prescription.medicines.map((m) => m.toJson()).toList()),
        'templateId': prescription.templateId,
      },
    );
    return prescription.copyWith(id: id);
  }

  Future<List<Prescription>> getPrescriptionsByDentist(String dentistId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prescriptions',
      where: 'dentistId = ?',
      whereArgs: [dentistId],
      orderBy: 'orderNumber DESC',
    );

    return List.generate(maps.length, (i) {
      return Prescription(
        id: maps[i]['id'] as int,
        dentistId: maps[i]['dentistId'] as String,
        patientId: maps[i]['patientId'] as int,
        orderNumber: maps[i]['orderNumber'] as int,
        date: DateTime.parse(maps[i]['date'] as String),
        patientName: maps[i]['patientName'] as String,
        patientFamilyName: maps[i]['patientFamilyName'] as String,
        patientAge: maps[i]['patientAge'] as int,
        medicines: (jsonDecode(maps[i]['medicines'] as String) as List)
            .map((m) => PrescriptionMedicine.fromJson(m as Map<String, dynamic>))
            .toList(),
        templateId: maps[i]['templateId'] as String,
      );
    });
  }

  Future<List<Prescription>> getPrescriptionsByPatient(int patientId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prescriptions',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Prescription(
        id: maps[i]['id'] as int,
        dentistId: maps[i]['dentistId'] as String,
        patientId: maps[i]['patientId'] as int,
        orderNumber: maps[i]['orderNumber'] as int,
        date: DateTime.parse(maps[i]['date'] as String),
        patientName: maps[i]['patientName'] as String,
        patientFamilyName: maps[i]['patientFamilyName'] as String,
        patientAge: maps[i]['patientAge'] as int,
        medicines: (jsonDecode(maps[i]['medicines'] as String) as List)
            .map((m) => PrescriptionMedicine.fromJson(m as Map<String, dynamic>))
            .toList(),
        templateId: maps[i]['templateId'] as String,
      );
    });
  }

  Future<int> getLastOrderNumber(String dentistId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prescriptions',
      columns: ['orderNumber'],
      where: 'dentistId = ?',
      whereArgs: [dentistId],
      orderBy: 'orderNumber DESC',
      limit: 1,
    );

    if (maps.isEmpty) return 0;
    return maps.first['orderNumber'] as int;
  }

  Future<void> deletePrescription(int id) async {
    final db = await _dbService.database;
    await db.delete('prescriptions', where: 'id = ?', whereArgs: [id]);
  }
}

// Models needed for decoding
