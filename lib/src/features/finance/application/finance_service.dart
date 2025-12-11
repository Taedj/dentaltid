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
    ref,
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
      final service = ref.watch(financeServiceProvider);
      // Use adjusted transactions to handle pro-rata recurring charges
      return service.getAdjustedTransactionsFiltered(
        startDate: filters.dateRange.start,
        endDate: filters.dateRange.end,
        includedSourceTypes: _getIncludedSourceTypesFromFilters(filters),
      );
    });

final dailySummaryProvider =
    FutureProvider.family<Map<String, double>, FinanceFilters>((
      ref,
      filters,
    ) async {
      final service = ref.watch(financeServiceProvider);
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
      final service = ref.watch(financeServiceProvider);
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
      final service = ref.watch(financeServiceProvider);
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
      final service = ref.watch(financeServiceProvider);
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
  final Ref _ref;

  FinanceService(
    this._repository,
    this._recurringChargeRepository,
    this._auditService,
    this._settings,
    this._ref,
  );

  /// Returns transactions with recurring charges pro-rated for the selected period.
  Future<List<Transaction>> getAdjustedTransactionsFiltered({
    required DateTime startDate,
    required DateTime endDate,
    Set<TransactionSourceType>? includedSourceTypes,
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

    final oneOffs = await _repository.getTransactionsFiltered(
      startDate: startDate,
      endDate: endDate,
      includedSourceTypes: effectiveIncluded
          .where((t) => t != TransactionSourceType.recurringCharge)
          .toSet(),
    );

    // 2. Processing Recurring Transactions
    // If recurring charges are excluded, return early
    if (!includeRecurring) {
      return oneOffs;
    }

    final adjustedRecurring = <Transaction>[];

    // Fetch definitions to know frequency
    final recurringChargeDefs = await _recurringChargeRepository
        .getAllRecurringCharges();
    final defsMap = {for (var d in recurringChargeDefs) d.id: d};

    // Look back up to 1 year to find active recurring charges that might cover this period
    // (e.g., A yearly charge starting Jan 1st covers Dec 31st)
    final recurringSearchStart = startDate.subtract(const Duration(days: 366));

    final rawRecurring = await _repository.getTransactionsFiltered(
      startDate: recurringSearchStart,
      endDate: endDate,
      includedSourceTypes: {TransactionSourceType.recurringCharge},
    );

    // Filter Window (The Range user wants to see)
    final filterWindowStart = startDate;
    final filterWindowEnd = endDate;

    for (final txn in rawRecurring) {
      if (txn.sourceId == null || !defsMap.containsKey(txn.sourceId)) continue;
      final definition = defsMap[txn.sourceId]!;

      // Determine the "Billing Cycle" of this specific transaction
      // e.g., if Monthly on Jan 1: Cycle is Jan 1 - Jan 31.
      DateTime cycleStart = txn.date;
      DateTime cycleEnd;

      switch (definition.frequency) {
        case RecurringChargeFrequency.daily:
          cycleEnd = cycleStart
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1));
          break;
        case RecurringChargeFrequency.weekly:
          cycleEnd = cycleStart
              .add(const Duration(days: 7))
              .subtract(const Duration(seconds: 1));
          break;
        case RecurringChargeFrequency.monthly:
          // Careful with month overflow
          cycleEnd = DateTime(
            cycleStart.year,
            cycleStart.month + 1,
            cycleStart.day,
          ).subtract(const Duration(seconds: 1));
          break;
        case RecurringChargeFrequency.quarterly:
          cycleEnd = DateTime(
            cycleStart.year,
            cycleStart.month + 3,
            cycleStart.day,
          ).subtract(const Duration(seconds: 1));
          break;
        case RecurringChargeFrequency.yearly:
          cycleEnd = DateTime(
            cycleStart.year + 1,
            cycleStart.month,
            cycleStart.day,
          ).subtract(const Duration(seconds: 1));
          break;
        case RecurringChargeFrequency.custom:
          cycleEnd = definition.endDate ?? cycleStart;
          break;
      }

      // Calculate Intersection between Cycle and Filter Window
      // Intersection Start = Max(CycleStart, FilterStart)
      // Intersection End   = Min(CycleEnd, FilterEnd)

      final intersectStart = cycleStart.isAfter(filterWindowStart)
          ? cycleStart
          : filterWindowStart;
      final intersectEnd = cycleEnd.isBefore(filterWindowEnd)
          ? cycleEnd
          : filterWindowEnd;

      if (intersectStart.isBefore(intersectEnd)) {
        // Valid overlap
        final overlapDuration = intersectEnd
            .difference(intersectStart)
            .inMilliseconds;
        final cycleDuration = cycleEnd.difference(cycleStart).inMilliseconds;

        if (cycleDuration > 0) {
          final ratio = overlapDuration / cycleDuration;
          final adjustedAmount = txn.totalAmount * ratio;

          if (adjustedAmount > 0.01) {
            // Filter distinct minimal amounts
            adjustedRecurring.add(
              txn.copyWith(
                totalAmount: adjustedAmount,
                description: '${txn.description} (Pro-rated)',
              ),
            );
          }
        }
      }
    }

    return [...oneOffs, ...adjustedRecurring];
  }

  Future<void> addTransaction(
    Transaction transaction, {
    bool invalidate = true,
  }) async {
    await _repository.createTransaction(transaction);
    _auditService.logEvent(
      AuditAction.createTransaction,
      details:
          'Transaction of type ${transaction.type} for amount ${transaction.totalAmount} added.',
    );
    if (invalidate) {
      // Invalidate all data providers
      _ref.invalidate(filteredTransactionsProvider);
      _ref.invalidate(dailySummaryProvider);
      _ref.invalidate(weeklySummaryProvider);
      _ref.invalidate(monthlySummaryProvider);
      _ref.invalidate(yearlySummaryProvider);
    }
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
    if (invalidate) {
      _ref.invalidate(filteredTransactionsProvider);
      _ref.invalidate(dailySummaryProvider);
      _ref.invalidate(weeklySummaryProvider);
      _ref.invalidate(monthlySummaryProvider);
      _ref.invalidate(yearlySummaryProvider);
    }
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.deleteTransaction(id);
    _auditService.logEvent(
      AuditAction.deleteTransaction,
      details: 'Transaction with ID $id deleted.',
    );
    _ref.invalidate(filteredTransactionsProvider);
    _ref.invalidate(dailySummaryProvider);
    _ref.invalidate(weeklySummaryProvider);
    _ref.invalidate(monthlySummaryProvider);
    _ref.invalidate(yearlySummaryProvider);
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
          income += transaction.totalAmount;
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
