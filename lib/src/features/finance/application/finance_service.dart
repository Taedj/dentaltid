import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/finance/data/finance_repository.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(DatabaseService.instance);
});

final financeServiceProvider = Provider<FinanceService>((ref) {
  return FinanceService(
    ref.watch(financeRepositoryProvider),
    ref.watch(auditServiceProvider),
    ref,
  );
});

final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final service = ref.watch(financeServiceProvider);
  return service.getTransactions();
});

class FinanceService {
  final FinanceRepository _repository;
  final AuditService _auditService;
  final Ref _ref;

  FinanceService(this._repository, this._auditService, this._ref);

  Future<void> addTransaction(Transaction transaction) async {
    await _repository.createTransaction(transaction);
    _auditService.logEvent(
      AuditAction.createTransaction,
      details:
          'Transaction of type ${transaction.type} for amount ${transaction.totalAmount} added.',
    );
    // Invalidate transaction providers to refresh the UI
    _ref.invalidate(transactionsProvider);
  }

  Future<List<Transaction>> getTransactions() async {
    return await _repository.getTransactions();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _repository.updateTransaction(transaction);
    _auditService.logEvent(
      AuditAction.updateTransaction,
      details: 'Transaction updated.',
    );
    // Invalidate transaction providers to refresh the UI
    _ref.invalidate(transactionsProvider);
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.deleteTransaction(id);
    _auditService.logEvent(
      AuditAction.deleteTransaction,
      details: 'Transaction with ID $id deleted.',
    );
    // Invalidate transaction providers to refresh the UI
    _ref.invalidate(transactionsProvider);
  }

  Future<List<Transaction>> getTransactionsBySessionId(int sessionId) async {
    return await _repository.getTransactionsBySessionId(sessionId);
  }
}
