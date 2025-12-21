import 'dart:async';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/finance/data/finance_repository.dart';

import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:dentaltid/src/features/settings/application/finance_settings_provider.dart';
import 'package:dentaltid/src/features/settings/domain/finance_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';

import 'package:dentaltid/src/features/finance/data/recurring_charge_repository.dart';
import 'package:dentaltid/src/features/finance/domain/recurring_charge.dart';
import 'package:dentaltid/src/features/finance/domain/finance_filters.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(DatabaseService.instance);
});

final financeServiceProvider = Provider<FinanceService>((ref) {
  return FinanceService(
    ref.watch(financeRepositoryProvider),
    ref.watch(recurringChargeRepositoryProvider),
    ref.watch(auditServiceProvider),
    ref.watch(financeSettingsProvider),
  );
});

Set<TransactionSourceType> _getIncludedSourceTypesFromFilters(
  FinanceFilters filters,
) {
  final Set<TransactionSourceType> includedSourceTypes = {};
  if (filters.includeRecurringCharges) {
    includedSourceTypes.add(TransactionSourceType.recurringCharge);
  }
  if (filters.includeInventoryExpenses) {
    includedSourceTypes.add(TransactionSourceType.inventory);
  }
  if (filters.includeStaffSalaries) {
    includedSourceTypes.add(TransactionSourceType.salary);
  }
  if (filters.includeRent) {
    includedSourceTypes.add(TransactionSourceType.rent);
  }
  // Always include appointments/other as they are primary income sources unless explicitly filtered out
  includedSourceTypes.add(TransactionSourceType.appointment);
  includedSourceTypes.add(TransactionSourceType.other);
  return includedSourceTypes;
}

final filteredTransactionsProvider =
    FutureProvider.family<List<Transaction>, FinanceFilters>((ref, filters) {
      final service = ref.read(financeServiceProvider);
      
      final subscription = service.onDataChanged.listen((_) {
        ref.invalidateSelf();
      });
      ref.onDispose(() => subscription.cancel());
      
      // Use adjusted transactions to handle pro-rata recurring charges
      return service.getAdjustedTransactionsFiltered(
        startDate: filters.dateRange.start,
        endDate: filters.dateRange.end,
        includedSourceTypes: _getIncludedSourceTypesFromFilters(filters),
        showProRated: true,
      );
    });

final actualTransactionsProvider =
    FutureProvider.family<List<Transaction>, FinanceFilters>((ref, filters) {
      final service = ref.read(financeServiceProvider);
      
      final subscription = service.onDataChanged.listen((_) {
        ref.invalidateSelf();
      });
      ref.onDispose(() => subscription.cancel());

      return service.getAdjustedTransactionsFiltered(
        startDate: filters.dateRange.start,
        endDate: filters.dateRange.end,
        includedSourceTypes: _getIncludedSourceTypesFromFilters(filters),
        showProRated: false,
      );
    });

final dailySummaryProvider =
    FutureProvider.family<Map<String, double>, FinanceFilters>((
      ref,
      filters,
    ) async {
      final service = ref.read(financeServiceProvider);
      
      final subscription = service.onDataChanged.listen((_) {
        ref.invalidateSelf();
      });
      ref.onDispose(() => subscription.cancel());

      return service.getDailySummary(
        filters.dateRange.end, // Use end date to get summary for that day
        includedSourceTypes: _getIncludedSourceTypesFromFilters(filters),
      );
    });

final weeklySummaryProvider =
    FutureProvider.family<Map<String, double>, FinanceFilters>((
      ref,
      filters,
    ) async {
      final service = ref.read(financeServiceProvider);
      
      final subscription = service.onDataChanged.listen((_) {
        ref.invalidateSelf();
      });
      ref.onDispose(() => subscription.cancel());

      return service.getWeeklySummary(
        filters.dateRange.end, // Use end date to get summary for that week
        includedSourceTypes: _getIncludedSourceTypesFromFilters(filters),
      );
    });

final monthlySummaryProvider =
    FutureProvider.family<Map<String, double>, FinanceFilters>((
      ref,
      filters,
    ) async {
      final service = ref.read(financeServiceProvider);
      
      final subscription = service.onDataChanged.listen((_) {
        ref.invalidateSelf();
      });
      ref.onDispose(() => subscription.cancel());

      return service.getMonthlySummary(
        filters.dateRange.end, // Use end date to get summary for that month
        includedSourceTypes: _getIncludedSourceTypesFromFilters(filters),
      );
    });

final yearlySummaryProvider =
    FutureProvider.family<Map<String, double>, FinanceFilters>((
      ref,
      filters,
    ) async {
      final service = ref.read(financeServiceProvider);
      
      final subscription = service.onDataChanged.listen((_) {
        ref.invalidateSelf();
      });
      ref.onDispose(() => subscription.cancel());

      return service.getYearlySummary(
        filters.dateRange.end, // Use end date to get summary for that year
        includedSourceTypes: _getIncludedSourceTypesFromFilters(filters),
      );
    });

class FinanceService {
  final FinanceRepository _repository;
  final RecurringChargeRepository _recurringChargeRepository;
  final AuditService _auditService;
  final FinanceSettings _settings;

  // Reactive Stream
  final StreamController<void> _dataChangeController = StreamController.broadcast();
  Stream<void> get onDataChanged => _dataChangeController.stream;

  FinanceService(
    this._repository,
    this._recurringChargeRepository,
    this._auditService,
    this._settings,
  );

  void _notifyDataChanged() {
    _dataChangeController.add(null);
  }

  /// Returns transactions with recurring charges pro-rated for the selected period.
  Future<List<Transaction>> getAdjustedTransactionsFiltered({
    required DateTime startDate,
    required DateTime endDate,
    Set<TransactionSourceType>? includedSourceTypes,
    bool showProRated = true,
  }) async {
    // 1. Fetch One-Off Transactions (Regular range)
    var effectiveIncluded =
        includedSourceTypes ?? TransactionSourceType.values.toSet();

    // Apply Settings Filters
    if (!_settings.includeInventory) {
      effectiveIncluded = effectiveIncluded.difference({
        TransactionSourceType.inventory,
      });
    }
    if (!_settings.includeAppointments) {
      effectiveIncluded = effectiveIncluded.difference({
        TransactionSourceType.appointment,
      });
    }
    // Recurring is handled separately below, but if disabled in settings, we treat it as excluded
    bool includeRecurring = _settings.includeRecurring;
    if (includedSourceTypes != null &&
        !includedSourceTypes.contains(TransactionSourceType.recurringCharge)) {
      includeRecurring = false;
    }

    if (!showProRated) {
        // Return actual transactions as they are in the DB
        return await _repository.getTransactionsFiltered(
          startDate: startDate,
          endDate: endDate,
          includedSourceTypes: effectiveIncluded,
        );
    }

    final oneOffs = await _repository.getTransactionsFiltered(
      startDate: startDate,
      endDate: endDate,
      includedSourceTypes: effectiveIncluded
          .where((t) => t != TransactionSourceType.recurringCharge)
          .toSet(),
    );

    if (!includeRecurring) {
      return oneOffs;
    }

    // 2. Dynamic Pro-rating for Recurring Charges
    // We calculate the contribution of each recurring charge to the current window
    final recurringCharges = await _recurringChargeRepository.getAllRecurringCharges();
    final proRatedTransactions = <Transaction>[];

    
    
    for (final charge in recurringCharges) {
      if (!charge.isActive) continue;
      
      // Check if the charge's lifetime overlaps with our window
      if (charge.startDate.isAfter(endDate)) continue;
      if (charge.endDate != null && charge.endDate!.isBefore(startDate)) continue;

      // Calculate daily rate
      double dailyRate = 0;
      switch (charge.frequency) {
        case RecurringChargeFrequency.daily:
          dailyRate = charge.amount;
          break;
        case RecurringChargeFrequency.weekly:
          dailyRate = charge.amount / 7;
          break;
        case RecurringChargeFrequency.monthly:
          dailyRate = charge.amount / 30; // Approximation
          break;
        case RecurringChargeFrequency.quarterly:
          dailyRate = charge.amount / 91;
          break;
        case RecurringChargeFrequency.yearly:
          dailyRate = charge.amount / 365;
          break;
        case RecurringChargeFrequency.custom:
          if (charge.endDate != null) {
             final totalDays = charge.endDate!.difference(charge.startDate).inDays + 1;
             dailyRate = totalDays > 0 ? charge.amount / totalDays : charge.amount;
          } else {
             dailyRate = charge.amount / 30;
          }
          break;
      }

      // Calculate how many days of this charge fall into our window
      final effectiveStart = charge.startDate.isAfter(startDate) ? charge.startDate : startDate;
      final effectiveEnd = (charge.endDate != null && charge.endDate!.isBefore(endDate)) ? charge.endDate! : endDate;
      
      final overlappingDays = effectiveEnd.difference(effectiveStart).inDays + 1;
      
      if (overlappingDays > 0) {
          final proRatedAmount = dailyRate * overlappingDays;
          proRatedTransactions.add(
            Transaction(
              description: '${charge.name} (Pro-rated)',
              totalAmount: proRatedAmount,
              paidAmount: proRatedAmount, // Treat as "paid" for profit calculation
              type: TransactionType.expense,
              date: effectiveStart,
              sourceType: TransactionSourceType.recurringCharge,
              sourceId: charge.id,
              category: charge.name,
            ),
          );
      }
    }

    return [...oneOffs, ...proRatedTransactions];
  }

  Future<void> addTransaction(
    Transaction transaction, {
    bool invalidate = true,
  }) async {
    final newId = await _repository.createTransaction(transaction);
    final newTransaction = transaction.copyWith(id: newId);

    _auditService.logEvent(
      AuditAction.createTransaction,
      details:
          'Transaction of type ${newTransaction.type} for amount ${newTransaction.totalAmount} added.',
    );
    
    // Trigger reactive listener
    _notifyDataChanged();
  }

  Future<List<Transaction>> getTransactions() async {
    return await _repository.getTransactionsFiltered();
  }

  Future<void> updateTransaction(
    Transaction transaction, {
    bool invalidate = true,
  }) async {
    await _repository.updateTransaction(transaction);
    _auditService.logEvent(
      AuditAction.updateTransaction,
      details: 'Transaction updated.',
    );
    
    // Trigger reactive listener
    _notifyDataChanged();
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.deleteTransaction(id);
    _auditService.logEvent(
      AuditAction.deleteTransaction,
      details: 'Transaction with ID $id deleted.',
    );
    
    // Trigger reactive listener
    _notifyDataChanged();
  }

  Future<List<Transaction>> getTransactionsBySessionId(int sessionId) async {
    return await _repository.getTransactionsBySessionId(sessionId);
  }

  Future<String> getPaymentStatusForAppointment(int appointmentId) async {
    final transactions = await getTransactionsBySessionId(appointmentId);
    if (transactions.isEmpty) {
      return 'Unpaid';
    }
    final latestTransaction = transactions.reduce(
      (a, b) => a.date.isAfter(b.date) ? a : b,
    );
    return latestTransaction.status.toString().split('.').last;
  }

  Future<List<Transaction>> getTransactionsFiltered({
    DateTime? startDate,
    DateTime? endDate,
    Set<TransactionSourceType>? includedSourceTypes,
    String? category,
  }) async {
    return await _repository.getTransactionsFiltered(
      startDate: startDate,
      endDate: endDate,
      includedSourceTypes: includedSourceTypes,
      category: category,
    );
  }

  Future<Map<String, double>> _generateSummary(
    List<Transaction> transactions, {
    Set<String>? includedCategories,
  }) async {
    double income = 0;
    double expense = 0;

    for (final transaction in transactions) {
      bool categoryMatch =
          includedCategories == null ||
          includedCategories.isEmpty ||
          includedCategories.contains(transaction.category);

      if (categoryMatch) {
        if (transaction.type == TransactionType.income) {
          income += transaction.paidAmount;
        } else {
          expense += transaction.totalAmount;
        }
      }
    }
    return {'income': income, 'expense': expense, 'profit': income - expense};
  }

  Future<Map<String, double>> getSummary(
    DateTime date,
    String period, {
    Set<String>? includedCategories,
    Set<TransactionSourceType>? includedSourceTypes,
  }) async {
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 'daily':
        startDate = DateTime(date.year, date.month, date.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'weekly':
        startDate = date.subtract(Duration(days: date.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'monthly':
        startDate = DateTime(date.year, date.month, 1);
        endDate = DateTime(date.year, date.month + 1, 1);
        break;
      case 'yearly':
        startDate = DateTime(date.year, 1, 1);
        endDate = DateTime(date.year + 1, 1, 1);
        break;
      default:
        throw ArgumentError('Invalid period: $period');
    }

    final transactions = await getAdjustedTransactionsFiltered(
      startDate: startDate,
      endDate: endDate,
      includedSourceTypes: includedSourceTypes,
    );

    return _generateSummary(
      transactions,
      includedCategories: includedCategories,
    );
  }

  Future<Map<String, double>> getDailySummary(
    DateTime date, {
    Set<String>? includedCategories,
    Set<TransactionSourceType>? includedSourceTypes,
  }) async {
    return await getSummary(
      date,
      'daily',
      includedCategories: includedCategories,
      includedSourceTypes: includedSourceTypes,
    );
  }

  Future<Map<String, double>> getWeeklySummary(
    DateTime date, {
    Set<String>? includedCategories,
    Set<TransactionSourceType>? includedSourceTypes,
  }) async {
    return await getSummary(
      date,
      'weekly',
      includedCategories: includedCategories,
      includedSourceTypes: includedSourceTypes,
    );
  }

  Future<Map<String, double>> getMonthlySummary(
    DateTime date, {
    Set<String>? includedCategories,
    Set<TransactionSourceType>? includedSourceTypes,
  }) async {
    return await getSummary(
      date,
      'monthly',
      includedCategories: includedCategories,
      includedSourceTypes: includedSourceTypes,
    );
  }

  Future<Map<String, double>> getYearlySummary(
    DateTime date, {
    Set<String>? includedCategories,
    Set<TransactionSourceType>? includedSourceTypes,
  }) async {
    return await getSummary(
      date,
      'yearly',
      includedCategories: includedCategories,
      includedSourceTypes: includedSourceTypes,
    );
  }

  Future<List<Transaction>> getTransactionsForChart({
    DateTime? startDate,
    DateTime? endDate,
    Set<TransactionSourceType>? includedSourceTypes,
  }) async {
    return await _repository.getTransactionsFiltered(
      startDate: startDate,
      endDate: endDate,
      includedSourceTypes: includedSourceTypes,
    );
  }
}
