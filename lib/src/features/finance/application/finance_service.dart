import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/finance/data/finance_repository.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(DatabaseService.instance);
});

final financeServiceProvider = Provider<FinanceService>((ref) {
  return FinanceService(ref.watch(financeRepositoryProvider));
});

class FinanceService {
  final FinanceRepository _repository;

  FinanceService(this._repository);

  Future<void> addTransaction(Transaction transaction) async {
    await _repository.createTransaction(transaction);
  }

  Future<List<Transaction>> getTransactions() async {
    return await _repository.getTransactions();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _repository.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.deleteTransaction(id);
  }
}
