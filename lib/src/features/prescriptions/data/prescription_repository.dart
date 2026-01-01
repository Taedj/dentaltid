import 'dart:convert';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/prescriptions/domain/prescription.dart';
import 'package:dentaltid/src/features/prescriptions/domain/prescription_medicine.dart';

class PrescriptionRepository {
  final DatabaseService _dbService;

  PrescriptionRepository(this._dbService);

  Future<Prescription> createPrescription(Prescription prescription) async {
    final db = await _dbService.database;
    final id = await db.insert('prescriptions', {
      'dentistId': prescription.dentistId,
      'patientId': prescription.patientId,
      'visitId': prescription.visitId,
      'orderNumber': prescription.orderNumber,
      'date': prescription.date.toIso8601String(),
      'patientName': prescription.patientName,
      'patientFamilyName': prescription.patientFamilyName,
      'patientAge': prescription.patientAge,
      'medicines': jsonEncode(
        prescription.medicines.map((m) => m.toJson()).toList(),
      ),
      'templateId': prescription.templateId,
      'logoPath': prescription.logoPath,
      'backgroundImagePath': prescription.backgroundImagePath,
      'backgroundOpacity': prescription.backgroundOpacity,
      'notes': prescription.notes,
      'advice': prescription.advice,
      'qrContent': prescription.qrContent,
      'showLogo': prescription.showLogo ? 1 : 0,
      'showNotes': prescription.showNotes ? 1 : 0,
      'showAllergies': prescription.showAllergies ? 1 : 0,
      'showAdvice': prescription.showAdvice ? 1 : 0,
      'showQrCode': prescription.showQrCode ? 1 : 0,
      'showBranding': prescription.showBranding ? 1 : 0,
      'showBorders': prescription.showBorders ? 1 : 0,
      'showEmail': prescription.showEmail ? 1 : 0,
      'language': prescription.language,
    });
    return prescription.copyWith(id: id);
  }

  Future<void> updatePrescription(Prescription prescription) async {
    final db = await _dbService.database;
    await db.update(
      'prescriptions',
      {
        'dentistId': prescription.dentistId,
        'patientId': prescription.patientId,
        'visitId': prescription.visitId,
        'orderNumber': prescription.orderNumber,
        'date': prescription.date.toIso8601String(),
        'patientName': prescription.patientName,
        'patientFamilyName': prescription.patientFamilyName,
        'patientAge': prescription.patientAge,
        'medicines': jsonEncode(
          prescription.medicines.map((m) => m.toJson()).toList(),
        ),
        'templateId': prescription.templateId,
        'logoPath': prescription.logoPath,
        'backgroundImagePath': prescription.backgroundImagePath,
        'backgroundOpacity': prescription.backgroundOpacity,
        'notes': prescription.notes,
        'advice': prescription.advice,
        'qrContent': prescription.qrContent,
        'showLogo': prescription.showLogo ? 1 : 0,
        'showNotes': prescription.showNotes ? 1 : 0,
        'showAllergies': prescription.showAllergies ? 1 : 0,
        'showAdvice': prescription.showAdvice ? 1 : 0,
        'showQrCode': prescription.showQrCode ? 1 : 0,
        'showBranding': prescription.showBranding ? 1 : 0,
        'showBorders': prescription.showBorders ? 1 : 0,
        'showEmail': prescription.showEmail ? 1 : 0,
        'language': prescription.language,
      },
      where: 'id = ?',
      whereArgs: [prescription.id],
    );
  }

  Future<Prescription?> getPrescriptionByVisit(int visitId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prescriptions',
      where: 'visitId = ?',
      whereArgs: [visitId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final map = maps.first;
    return Prescription(
      id: map['id'] as int,
      dentistId: map['dentistId'] as String,
      patientId: map['patientId'] as int,
      visitId: map['visitId'] as int?,
      orderNumber: map['orderNumber'] as int,
      date: DateTime.parse(map['date'] as String),
      patientName: map['patientName'] as String,
      patientFamilyName: map['patientFamilyName'] as String,
      patientAge: map['patientAge'] as int,
      medicines: (jsonDecode(map['medicines'] as String) as List)
          .map((m) => PrescriptionMedicine.fromJson(m as Map<String, dynamic>))
          .toList(),
      templateId: map['templateId'] as String,
      logoPath: map['logoPath'] as String?,
      backgroundImagePath: map['backgroundImagePath'] as String?,
      backgroundOpacity: (map['backgroundOpacity'] as num?)?.toDouble() ?? 0.2,
      notes: map['notes'] as String?,
      advice: map['advice'] as String?,
      qrContent: map['qrContent'] as String?,
      showLogo: (map['showLogo'] as int?) == 1,
      showNotes: (map['showNotes'] as int?) == 1,
      showAllergies: (map['showAllergies'] as int?) == 1,
      showAdvice: (map['showAdvice'] as int?) == 1,
      showQrCode: (map['showQrCode'] as int?) == 1,
      showBranding: (map['showBranding'] as int?) == 1,
      showBorders: (map['showBorders'] as int?) == 1,
      showEmail: (map['showEmail'] as int?) == 1,
      language: map['language'] as String? ?? 'fr',
    );
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
      final map = maps[i];
      return Prescription(
        id: map['id'] as int,
        dentistId: map['dentistId'] as String,
        patientId: map['patientId'] as int,
        visitId: map['visitId'] as int?,
        orderNumber: map['orderNumber'] as int,
        date: DateTime.parse(map['date'] as String),
        patientName: map['patientName'] as String,
        patientFamilyName: map['patientFamilyName'] as String,
        patientAge: map['patientAge'] as int,
        medicines: (jsonDecode(map['medicines'] as String) as List)
            .map(
              (m) => PrescriptionMedicine.fromJson(m as Map<String, dynamic>),
            )
            .toList(),
        templateId: map['templateId'] as String,
        logoPath: map['logoPath'] as String?,
        backgroundImagePath: map['backgroundImagePath'] as String?,
        backgroundOpacity:
            (map['backgroundOpacity'] as num?)?.toDouble() ?? 0.2,
        notes: map['notes'] as String?,
        advice: map['advice'] as String?,
        qrContent: map['qrContent'] as String?,
        showLogo: (map['showLogo'] as int?) == 1,
        showNotes: (map['showNotes'] as int?) == 1,
        showAllergies: (map['showAllergies'] as int?) == 1,
        showAdvice: (map['showAdvice'] as int?) == 1,
        showQrCode: (map['showQrCode'] as int?) == 1,
        showBranding: (map['showBranding'] as int?) == 1,
        showBorders: (map['showBorders'] as int?) == 1,
        showEmail: (map['showEmail'] as int?) == 1,
        language: map['language'] as String? ?? 'fr',
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
      final map = maps[i];
      return Prescription(
        id: map['id'] as int,
        dentistId: map['dentistId'] as String,
        patientId: map['patientId'] as int,
        visitId: map['visitId'] as int?,
        orderNumber: map['orderNumber'] as int,
        date: DateTime.parse(map['date'] as String),
        patientName: map['patientName'] as String,
        patientFamilyName: map['patientFamilyName'] as String,
        patientAge: map['patientAge'] as int,
        medicines: (jsonDecode(map['medicines'] as String) as List)
            .map(
              (m) => PrescriptionMedicine.fromJson(m as Map<String, dynamic>),
            )
            .toList(),
        templateId: map['templateId'] as String,
        logoPath: map['logoPath'] as String?,
        backgroundImagePath: map['backgroundImagePath'] as String?,
        backgroundOpacity:
            (map['backgroundOpacity'] as num?)?.toDouble() ?? 0.2,
        notes: map['notes'] as String?,
        advice: map['advice'] as String?,
        qrContent: map['qrContent'] as String?,
        showLogo: (map['showLogo'] as int?) == 1,
        showNotes: (map['showNotes'] as int?) == 1,
        showAllergies: (map['showAllergies'] as int?) == 1,
        showAdvice: (map['showAdvice'] as int?) == 1,
        showQrCode: (map['showQrCode'] as int?) == 1,
        showBranding: (map['showBranding'] as int?) == 1,
        showBorders: (map['showBorders'] as int?) == 1,
        showEmail: (map['showEmail'] as int?) == 1,
        language: map['language'] as String? ?? 'fr',
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
