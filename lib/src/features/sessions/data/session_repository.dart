import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/sessions/domain/session.dart';

class SessionRepository {
  final DatabaseService _databaseService;

  SessionRepository(this._databaseService);

  static const String _tableName = 'sessions';

  Future<int> createSession(Session session) async {
    final db = await _databaseService.database;
    return await db.insert(_tableName, session.toJson());
  }

  Future<List<Session>> getSessions() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) {
      return Session.fromJson(maps[i]);
    });
  }

  Future<List<Session>> getSessionsByVisitId(int visitId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'visitId = ?',
      whereArgs: [visitId],
      orderBy: 'sessionNumber ASC',
    );
    return List.generate(maps.length, (i) {
      return Session.fromJson(maps[i]);
    });
  }

  Future<Session?> getSessionById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Session.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<void> updateSession(Session session) async {
    final db = await _databaseService.database;
    await db.update(
      _tableName,
      session.toJson(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(int id) async {
    final db = await _databaseService.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Session>> getUpcomingSessions() async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'dateTime >= ?',
      whereArgs: [now.toIso8601String()],
      orderBy: 'dateTime ASC',
    );
    return List.generate(maps.length, (i) {
      return Session.fromJson(maps[i]);
    });
  }

  Future<List<Session>> getTodaysSessions() async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfDay = today.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'dateTime >= ? AND dateTime < ?',
      whereArgs: [today.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dateTime ASC',
    );
    return List.generate(maps.length, (i) {
      return Session.fromJson(maps[i]);
    });
  }

  Future<double> getTotalAmountForVisit(int visitId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT SUM(totalAmount) as total FROM $_tableName WHERE visitId = ?',
      [visitId],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> getPaidAmountForVisit(int visitId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT SUM(paidAmount) as total FROM $_tableName WHERE visitId = ?',
      [visitId],
    );
    return result.first['total'] as double? ?? 0.0;
  }
}
