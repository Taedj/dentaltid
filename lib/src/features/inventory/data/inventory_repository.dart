import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:sqflite/sqflite.dart';

class InventoryRepository {
  final DatabaseService _databaseService;

  InventoryRepository(this._databaseService);

  static const String _tableName = 'inventory';

  Future<InventoryItem> createInventoryItem(InventoryItem item) async {
    final db = await _databaseService.database;
    final id = await db.insert(_tableName, item.toJson());
    return item.copyWith(id: id);
  }

  Future<PaginatedInventoryItems> getInventoryItems({
    String? searchQuery,
    InventorySortOption? sortOption,
    bool showExpiredOnly = false,
    bool showLowStockOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final db = await _databaseService.database;

    List<String> conditions = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(name LIKE ? OR supplier LIKE ?)');
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
    }

    if (showExpiredOnly) {
      conditions.add('expirationDate < ?');
      whereArgs.add(DateTime.now().toIso8601String());
    }

    if (showLowStockOnly) {
      conditions.add('quantity <= lowStockThreshold');
    }

    final whereClause = conditions.isEmpty ? null : conditions.join(' AND ');

    // Count query
    final countResult = await db.query(
      _tableName,
      columns: ['COUNT(*)'],
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    // Sorting
    String orderBy = 'name ASC';
    if (sortOption != null) {
      switch (sortOption) {
        case InventorySortOption.nameAsc:
          orderBy = 'name ASC';
          break;
        case InventorySortOption.nameDesc:
          orderBy = 'name DESC';
          break;
        case InventorySortOption.quantityAsc:
          orderBy = 'quantity ASC';
          break;
        case InventorySortOption.quantityDesc:
          orderBy = 'quantity DESC';
          break;
        case InventorySortOption.expiryAsc:
          orderBy = 'expirationDate ASC';
          break;
        case InventorySortOption.expiryDesc:
          orderBy = 'expirationDate DESC';
          break;
      }
    }

    // Data query
    final int offset = (page - 1) * pageSize;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
      limit: pageSize,
      offset: offset,
    );

    final items = List.generate(maps.length, (i) {
      return InventoryItem.fromJson(maps[i]);
    });

    return PaginatedInventoryItems(
      items: items,
      totalCount: totalCount,
      currentPage: page,
      totalPages: (totalCount / pageSize).ceil(),
    );
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
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<InventoryItem?> getInventoryItemById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return InventoryItem.fromJson(maps.first);
    }
    return null;
  }
}
