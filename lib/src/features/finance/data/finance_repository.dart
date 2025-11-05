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

  Future<List<Transaction>> getTransactions() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) {
      return Transaction.fromJson(maps[i]);
    });
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

  Future<List<Transaction>> getTransactionsByPatientId(int patientId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromJson(maps[i]);
    });
  }
}
