import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/finance/domain/recurring_charge.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringChargeRepositoryProvider = Provider<RecurringChargeRepository>((
  ref,
) {
  return RecurringChargeRepository(DatabaseService.instance);
});

class RecurringChargeRepository {
  final DatabaseService _databaseService;

  RecurringChargeRepository(this._databaseService);

  Future<void> createRecurringCharge(RecurringCharge recurringCharge) async {
    final db = await _databaseService.database;
    await db.insert(
      'recurring_charges',
      recurringCharge.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RecurringCharge>> getAllRecurringCharges() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('recurring_charges');
    return List.generate(maps.length, (i) {
      return RecurringCharge.fromMap(maps[i]);
    });
  }

  Future<RecurringCharge?> getRecurringChargeById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recurring_charges',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return RecurringCharge.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateRecurringCharge(RecurringCharge recurringCharge) async {
    final db = await _databaseService.database;
    await db.update(
      'recurring_charges',
      recurringCharge.toMap(),
      where: 'id = ?',
      whereArgs: [recurringCharge.id],
    );
  }

  Future<void> deleteRecurringCharge(int id) async {
    final db = await _databaseService.database;
    await db.delete('recurring_charges', where: 'id = ?', whereArgs: [id]);
  }
}
