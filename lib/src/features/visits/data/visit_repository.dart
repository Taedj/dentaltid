import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/visits/domain/visit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class VisitRepository {
  final DatabaseService _databaseService;

  VisitRepository(this._databaseService);

  Future<int> addVisit(Visit visit) async {
    final db = await _databaseService.database;
    return await db.insert(
      'visits',
      visit.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Visit?> getVisitById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visits',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Visit.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Visit>> getVisitsByPatientId(int patientId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visits',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'dateTime DESC',
    );
    return List.generate(maps.length, (i) {
      return Visit.fromJson(maps[i]);
    });
  }

  Future<int> updateVisit(Visit visit) async {
    final db = await _databaseService.database;
    return await db.update(
      'visits',
      visit.toJson(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<int> deleteVisit(int id) async {
    final db = await _databaseService.database;
    return await db.delete('visits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Visit>> getEmergencyVisits() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visits',
      where: 'isEmergency = 1',
      orderBy: 'dateTime DESC',
    );
    return List.generate(maps.length, (i) {
      return Visit.fromJson(maps[i]);
    });
  }

  Future<int> getNextVisitNumber(int patientId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT MAX(visitNumber) as maxNumber FROM visits WHERE patientId = ?',
      [patientId],
    );
    final maxNumber = result.first['maxNumber'] as int?;
    return (maxNumber ?? 0) + 1;
  }

  Future<List<Visit>> getVisitsWithEmergencyInfo() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visits',
      where: 'isEmergency = 1 OR emergencySeverity != ?',
      whereArgs: ['EmergencySeverity.low'],
      orderBy: 'dateTime DESC',
    );
    return List.generate(maps.length, (i) {
      return Visit.fromJson(maps[i]);
    });
  }
}
