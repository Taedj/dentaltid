import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';

class PatientRepository {
  final DatabaseService _databaseService;

  PatientRepository(this._databaseService);

  static const String _tableName = 'patients';

  Future<void> createPatient(Patient patient) async {
    final db = await _databaseService.database;
    await db.insert(_tableName, patient.toJson());
  }

  Future<List<Patient>> getPatients([
    PatientFilter filter = PatientFilter.all,
  ]) async {
    final db = await _databaseService.database;
    String? where;
    List<dynamic>? whereArgs;
    final now = DateTime.now();

    switch (filter) {
      case PatientFilter.today:
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        where = 'createdAt >= ? AND createdAt < ?';
        whereArgs = [startOfDay.toIso8601String(), endOfDay.toIso8601String()];
        break;
      case PatientFilter.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        where = 'createdAt BETWEEN ? AND ?';
        whereArgs = [
          startOfWeek.toIso8601String(),
          endOfWeek.toIso8601String(),
        ];
        break;
      case PatientFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        where = 'createdAt BETWEEN ? AND ?';
        whereArgs = [
          startOfMonth.toIso8601String(),
          endOfMonth.toIso8601String(),
        ];
        break;
      case PatientFilter.all:
        break;
      case PatientFilter.emergency:
        where = 'isEmergency = ?';
        whereArgs = [1];
        break;
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: where,
      whereArgs: whereArgs,
    );
    return List.generate(maps.length, (i) {
      return Patient.fromJson(maps[i]);
    });
  }

  Future<void> updatePatient(Patient patient) async {
    final db = await _databaseService.database;
    await db.update(
      _tableName,
      patient.toJson(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<void> deletePatient(int id) async {
    final db = await _databaseService.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<Patient?> getPatientByNameAndFamilyName(
    String name,
    String familyName,
  ) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'name = ? AND familyName = ?',
      whereArgs: [name, familyName],
    );
    if (maps.isNotEmpty) {
      return Patient.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<Patient?> getPatientById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Patient.fromJson(maps.first);
    } else {
      return null;
    }
  }
}
