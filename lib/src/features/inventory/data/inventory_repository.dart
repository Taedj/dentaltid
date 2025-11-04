import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';

class InventoryRepository {
  final DatabaseService _databaseService;

  InventoryRepository(this._databaseService);

  static const String _tableName = 'inventory';

  Future<void> createInventoryItem(InventoryItem item) async {
    final db = await _databaseService.database;
    await db.insert(_tableName, item.toJson());
  }

  Future<List<InventoryItem>> getInventoryItems() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) {
      return InventoryItem.fromJson(maps[i]);
    });
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    final db = await _databaseService.database;
    await db.update(
      _tableName,
      item.toJson(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteInventoryItem(int id) async {
    final db = await _databaseService.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
