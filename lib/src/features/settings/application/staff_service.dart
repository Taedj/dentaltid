import 'dart:async';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/settings/domain/staff_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class StaffService {
  final DatabaseService _dbService;

  StaffService(this._dbService);

  Future<Database> get _db async => await _dbService.database;

  final _dataChangeController = StreamController<void>.broadcast();
  Stream<void> get onDataChanged => _dataChangeController.stream;

  void notifyDataChanged() {
    _dataChangeController.add(null);
  }

  Future<List<StaffUser>> getAllStaff() async {
    final db = await _db;
    final result = await db.query('staff_users', orderBy: 'fullName ASC');
    return result.map((json) => StaffUser.fromJson(json)).toList();
  }

  Future<int> addStaff(StaffUser staff) async {
    final db = await _db;
    try {
      final id = await db.insert('staff_users', staff.toJson());
      notifyDataChanged();
      return id;
    } catch (e) {
      if (e is DatabaseException && e.isUniqueConstraintError()) {
        throw Exception('Username already exists');
      }
      rethrow;
    }
  }

  Future<int> updateStaff(StaffUser staff) async {
    final db = await _db;
    final result = await db.update(
      'staff_users',
      staff.toJson(),
      where: 'id = ?',
      whereArgs: [staff.id],
    );
    notifyDataChanged();
    return result;
  }

  Future<int> deleteStaff(int id) async {
    final db = await _db;
    final result = await db.delete(
      'staff_users',
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyDataChanged();
    return result;
  }

  Future<StaffUser?> authenticateStaff(String username, String pin) async {
    final db = await _db;
    final result = await db.query(
      'staff_users',
      where: 'username = ? AND pin = ?',
      whereArgs: [username, pin],
    );

    if (result.isNotEmpty) {
      return StaffUser.fromJson(result.first);
    }
    return null;
  }
}

final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService(DatabaseService.instance);
});

final staffListProvider = FutureProvider<List<StaffUser>>((ref) async {
  final service = ref.watch(staffServiceProvider);
  final subscription = service.onDataChanged.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());
  return await service.getAllStaff();
});
