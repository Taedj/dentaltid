import 'package:dentaltid/src/features/finance/data/recurring_charge_repository.dart';
import 'package:dentaltid/src/features/finance/domain/recurring_charge.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringChargeServiceProvider = Provider<RecurringChargeService>((ref) {
  return RecurringChargeService(
    ref.watch(recurringChargeRepositoryProvider),
    ref.watch(financeServiceProvider),
  );
});

class RecurringChargeService {
  final RecurringChargeRepository _recurringChargeRepository;
  final FinanceService _financeService;

  RecurringChargeService(this._recurringChargeRepository, this._financeService);

  Future<void> addRecurringCharge(RecurringCharge recurringCharge) async {
    await _recurringChargeRepository.createRecurringCharge(recurringCharge);
  }

  Future<List<RecurringCharge>> getAllRecurringCharges() async {
    return await _recurringChargeRepository.getAllRecurringCharges();
  }

  Future<void> updateRecurringCharge(RecurringCharge recurringCharge) async {
    await _recurringChargeRepository.updateRecurringCharge(recurringCharge);
  }

  Future<void> deleteRecurringCharge(int id) async {
    await _recurringChargeRepository.deleteRecurringCharge(id);
  }

  Future<void> generateTransactionsForRecurringCharges(
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final recurringCharges = await getAllRecurringCharges();
    for (final charge in recurringCharges) {
      if (!charge.isActive) continue; // Only process active charges

      DateTime currentChargeDate = charge.startDate;
      // Adjust currentChargeDate to be within or just before periodStart
      if (currentChargeDate.isBefore(periodStart)) {
        while (currentChargeDate.isBefore(periodStart)) {
          if (charge.frequency == RecurringChargeFrequency.monthly) {
            currentChargeDate = DateTime(
              currentChargeDate.year,
              currentChargeDate.month + 1,
              currentChargeDate.day,
            );
          } else if (charge.frequency == RecurringChargeFrequency.quarterly) {
            currentChargeDate = DateTime(
              currentChargeDate.year,
              currentChargeDate.month + 3,
              currentChargeDate.day,
            );
          } else if (charge.frequency == RecurringChargeFrequency.yearly) {
            currentChargeDate = DateTime(
              currentChargeDate.year + 1,
              currentChargeDate.month,
              currentChargeDate.day,
            );
          } else {
            // For custom frequency, skip for now or require specific custom logic
            break;
          }
        }
      }

      while ((charge.endDate == null ||
              currentChargeDate.isBefore(charge.endDate!)) &&
          currentChargeDate.isBefore(periodEnd.add(const Duration(days: 1)))) {
        // Include transactions up to periodEnd
        // Check if a transaction for this charge on this date already exists
        final existingTransactions = await _financeService
            .getTransactionsFiltered(
              startDate: currentChargeDate,
              endDate: currentChargeDate,
              includedSourceTypes: {TransactionSourceType.recurringCharge},
              category: charge.name, // Using name as category for consistency
            );

        final transactionAlreadyExists = existingTransactions.any(
          (t) =>
              t.sourceId == charge.id &&
              t.date.year == currentChargeDate.year &&
              t.date.month == currentChargeDate.month &&
              t.date.day == currentChargeDate.day,
        );

        if (!transactionAlreadyExists &&
            (currentChargeDate.isAfter(periodStart) ||
                currentChargeDate.isAtSameMomentAs(periodStart))) {
          final transaction = Transaction(
            description: charge.description,
            totalAmount: charge.amount,
            type: TransactionType.expense,
            date: currentChargeDate,
            sourceType: TransactionSourceType.recurringCharge,
            sourceId: charge.id,
            category: charge.name,
          );
          await _financeService.addTransaction(transaction);
        }

        // Move to the next charge date based on frequency
        if (charge.frequency == RecurringChargeFrequency.monthly) {
          currentChargeDate = DateTime(
            currentChargeDate.year,
            currentChargeDate.month + 1,
            currentChargeDate.day,
          );
        } else if (charge.frequency == RecurringChargeFrequency.quarterly) {
          currentChargeDate = DateTime(
            currentChargeDate.year,
            currentChargeDate.month + 3,
            currentChargeDate.day,
          );
        } else if (charge.frequency == RecurringChargeFrequency.yearly) {
          currentChargeDate = DateTime(
            currentChargeDate.year + 1,
            currentChargeDate.month,
            currentChargeDate.day,
          );
        } else {
          // Handle custom frequency or break if not supported
          break;
        }
      }
    }
  }
}
