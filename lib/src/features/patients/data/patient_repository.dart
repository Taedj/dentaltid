import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:sqflite/sqflite.dart';

class PatientRepository {
  final DatabaseService _databaseService;

  PatientRepository(this._databaseService);

  static const String _tableName = 'patients';

  Future<int> createPatient(Patient patient) async {
    final db = await _databaseService.database;
    return await db.insert(_tableName, patient.toJson());
  }

  List<String> _getColumnsWithDue() {
    return [
      'patients.*', // Select all columns from patients table
      '(SELECT SUM(t.totalAmount - t.paidAmount) FROM transactions t JOIN appointments a ON t.sessionId = a.id WHERE a.sessionId = patients.id) as totalDue', // Corrected JOIN for totalDue
      '(SELECT MAX(dateTime) FROM appointments WHERE sessionId = patients.id) as lastVisitDate', // Corrected for lastVisitDate
      '(SELECT COUNT(*) FROM appointments WHERE sessionId = patients.id) as visitCount', // Corrected for visitCount
    ];
  }

  Future<PaginatedPatients> getPatients({
    PatientFilter filter = PatientFilter.all,
    String? searchQuery,
    int page = 1,
    int pageSize = 20,
  }) async {
    final db = await _databaseService.database;
    String? where;
    List<dynamic>? whereArgs;
    final now = DateTime.now();

    // 1. Build Filter Clause
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
      case PatientFilter.todayByExternal:
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        where = "source = 'nanopix' AND createdAt >= ? AND createdAt < ?";
        whereArgs = [startOfDay.toIso8601String(), endOfDay.toIso8601String()];
        break;
      case PatientFilter.allByExternal:
        where = "source = 'nanopix'";
        whereArgs = [];
        break;
    }

    // 2. Append Search Query if present
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchClause =
          '(name LIKE ? OR familyName LIKE ? OR phoneNumber LIKE ?)';
      final searchArgs = ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%'];

      if (where != null) {
        where = '$where AND $searchClause';
        whereArgs = [...whereArgs!, ...searchArgs];
      } else {
        where = searchClause;
        whereArgs = searchArgs;
      }
    }

    // 3. Get Total Count
    final countResult = await db.query(
      _tableName,
      columns: ['COUNT(*) as count'],
      where: where,
      whereArgs: whereArgs,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    // 4. Get Paginated Data
    final offset = (page - 1) * pageSize;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      columns: _getColumnsWithDue(),
      where: where,
      whereArgs: whereArgs,
      limit: pageSize,
      offset: offset,
      orderBy: 'createdAt DESC', // Default sort
    );

    final patients = List.generate(maps.length, (i) {
      return Patient.fromJson(maps[i]);
    });

    return PaginatedPatients(
      patients: patients,
      totalCount: totalCount,
      currentPage: page,
      totalPages: (totalCount / pageSize).ceil(),
    );
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
      columns: _getColumnsWithDue(),
      where: 'name = ? COLLATE NOCASE AND familyName = ? COLLATE NOCASE',
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
      columns: _getColumnsWithDue(),
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Patient.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Patient>> getBlacklistedPatients() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      columns: _getColumnsWithDue(),
      where: 'isBlacklisted = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) {
      return Patient.fromJson(maps[i]);
    });
  }

  Future<List<Patient>> searchPatients(String query) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      columns: _getColumnsWithDue(),
      where: 'name LIKE ? OR familyName LIKE ? OR phoneNumber LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) {
      return Patient.fromJson(maps[i]);
    });
  }
}
