import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/user_model.dart';

class StaffRepository {
  final DatabaseService _databaseService;

  StaffRepository(this._databaseService);

  static const String _tableName = 'managed_users';

  Future<void> createStaff(UserProfile staff) async {
    final db = await _databaseService.database;
    await db.insert(_tableName, staff.toJson());
  }

  Future<List<UserProfile>> getStaffByDentist(String dentistUid) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'managedByDentistId = ?',
      whereArgs: [dentistUid],
    );
    return List.generate(maps.length, (i) {
      return UserProfile.fromJson(maps[i]);
    });
  }

  Future<void> updateStaff(UserProfile staff) async {
    final db = await _databaseService.database;
    await db.update(
      _tableName,
      staff.toJson(),
      where: 'uid = ?',
      whereArgs: [staff.uid],
    );
  }

  Future<void> deleteStaff(String staffUid) async {
    final db = await _databaseService.database;
    await db.delete(_tableName, where: 'uid = ?', whereArgs: [staffUid]);
  }

  Future<UserProfile?> getStaffByUsernameAndPin(String dentistUid, String username, String pin) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'managedByDentistId = ? AND username = ? AND pin = ?',
      whereArgs: [dentistUid, username, pin],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserProfile.fromJson(maps.first);
    }
    return null;
  }
}
