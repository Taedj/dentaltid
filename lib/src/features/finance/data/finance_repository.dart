import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';

class FinanceRepository {
  final DatabaseService _databaseService;

  FinanceRepository(this._databaseService);

  static const String _tableName = 'transactions';

  Future<void> createTransaction(Transaction transaction) async {
    final db = await _databaseService.database;
    await db.insert(_tableName, transaction.toJson());
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final db = await _databaseService.database;
    await db.update(
      _tableName,
      transaction.toJson(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _databaseService.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Transaction>> getTransactionsFiltered({
    DateTime? startDate,
    DateTime? endDate,
    Set<TransactionSourceType>? includedSourceTypes,
    String? category,
  }) async {
    final db = await _databaseService.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    if (includedSourceTypes != null && includedSourceTypes.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      final placeholders = ('?' * includedSourceTypes.length)
          .split('')
          .join(',');
      whereClause += 'sourceType IN ($placeholders)';
      whereArgs.addAll(includedSourceTypes.map((e) => e.toString()));
    }
    if (category != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromJson(maps[i]);
    });
  }

  Future<List<Transaction>> getTransactionsBySessionId(int sessionId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromJson(maps[i]);
    });
  }
}
