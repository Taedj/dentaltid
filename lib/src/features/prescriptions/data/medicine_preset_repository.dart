import 'package:dentaltid/src/core/database_service.dart';
import '../domain/medicine_preset.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MedicinePresetRepository {
  final DatabaseService _dbService;

  MedicinePresetRepository(this._dbService);

  Future<Database> get _db async => await _dbService.database;

  Future<int> insert(MedicinePreset preset) async {
    final db = await _db;
    return await db.insert('medicine_presets', preset.toJson());
  }

  Future<List<MedicinePreset>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'medicine_presets',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) {
      return MedicinePreset.fromJson(maps[i]);
    });
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete(
      'medicine_presets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> update(MedicinePreset preset) async {
    final db = await _db;
    return await db.update(
      'medicine_presets',
      preset.toJson(),
      where: 'id = ?',
      whereArgs: [preset.id],
    );
  }
}
