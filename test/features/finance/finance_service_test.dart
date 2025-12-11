import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/data/finance_repository.dart';
import 'package:dentaltid/src/features/finance/data/recurring_charge_repository.dart';

import 'package:dentaltid/src/features/finance/domain/recurring_charge.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/settings/domain/finance_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'finance_service_test.mocks.dart';

@GenerateMocks([FinanceRepository, RecurringChargeRepository, AuditService])
void main() {
  group('FinanceService Summary Calculations', () {
    late MockFinanceRepository mockFinanceRepository;
    late MockRecurringChargeRepository mockRecurringChargeRepository;
    late MockAuditService mockAuditService;
    late FinanceService financeService;
    late ProviderContainer container;

    final testTransactions = [
      Transaction(
        id: 1,
        description: 'Consultation Fee',
        totalAmount: 100.0,
        paidAmount: 100.0,
        type: TransactionType.income,
        date: DateTime(2023, 11, 20),
        sourceType: TransactionSourceType.appointment,
        category: 'Consultation',
      ),
      Transaction(
        id: 2,
        description: 'Material Purchase',
        totalAmount: 50.0,
        paidAmount: 50.0,
        type: TransactionType.expense,
        date: DateTime(2023, 11, 20),
        sourceType: TransactionSourceType.inventory,
        category: 'Supplies',
      ),
      Transaction(
        id: 3,
        description: 'Follow-up Payment',
        totalAmount: 75.0,
        paidAmount: 75.0,
        type: TransactionType.income,
        date: DateTime(2023, 11, 21),
        sourceType: TransactionSourceType.appointment,
        category: 'Follow-up',
      ),
      Transaction(
        id: 4,
        description: 'Rent Payment',
        totalAmount: 1000.0,
        paidAmount: 1000.0,
        type: TransactionType.expense,
        date: DateTime(2023, 11, 15),
        sourceType: TransactionSourceType.recurringCharge,
        sourceId: 100,
        category: 'Rent',
      ),
      Transaction(
        id: 5,
        description: 'New Patient Visit',
        totalAmount: 120.0,
        paidAmount: 120.0,
        type: TransactionType.income,
        date: DateTime(2023, 11, 22),
        sourceType: TransactionSourceType.appointment,
        category: 'Consultation',
      ),
      // Future transaction outside test periods
      Transaction(
        id: 6,
        description: 'Future Income',
        totalAmount: 200.0,
        paidAmount: 200.0,
        type: TransactionType.income,
        date: DateTime(2024, 1, 1),
        sourceType: TransactionSourceType.appointment,
        category: 'Consultation',
      ),
    ];

    setUp(() {
      mockFinanceRepository = MockFinanceRepository();
      mockRecurringChargeRepository = MockRecurringChargeRepository();
      mockAuditService = MockAuditService();

      container = ProviderContainer(
        overrides: [
          financeRepositoryProvider.overrideWithValue(mockFinanceRepository),
          recurringChargeRepositoryProvider.overrideWithValue(
            mockRecurringChargeRepository,
          ),
          auditServiceProvider.overrideWithValue(mockAuditService),
          // We need to provide FinanceService with the mocked dependencies
          financeServiceProvider.overrideWith(
            (ref) => FinanceService(
              mockFinanceRepository,
              mockRecurringChargeRepository,
              mockAuditService,
              const FinanceSettings(),
              ref,
            ),
          ),
        ],
      );
      financeService = container.read(financeServiceProvider);

      // Mock recurring charges
      when(mockRecurringChargeRepository.getAllRecurringCharges()).thenAnswer(
        (_) async => [
          RecurringCharge(
            id: 100,
            name: 'Rent',
            amount: 1000.0,
            frequency: RecurringChargeFrequency.monthly,
            startDate: DateTime(2023, 1, 1),
            isActive: true,
            description: 'Office Rent',
          ),
        ],
      );

      // Smart mock for getTransactionsFiltered
      when(
        mockFinanceRepository.getTransactionsFiltered(
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          includedSourceTypes: anyNamed('includedSourceTypes'),
          category: anyNamed('category'),
        ),
      ).thenAnswer((invocation) async {
        final startDate =
            invocation.namedArguments[Symbol('startDate')] as DateTime?;
        final endDate =
            invocation.namedArguments[Symbol('endDate')] as DateTime?;
        final includedSourceTypes =
            invocation.namedArguments[Symbol('includedSourceTypes')]
                as Set<TransactionSourceType>?;
        final category =
            invocation.namedArguments[Symbol('category')] as String?;

        return testTransactions.where((t) {
          if (startDate != null && t.date.isBefore(startDate)) {
            return false;
          }
          // As per daily/weekly logic, endDate is usually exclusive (next day/week start)
          // But rawRecurring might rely on different logic.
          // Let's assume strict inequality for end date if it's midnight?
          // Actually, let's just interpret as [start, end).
          if (endDate != null &&
              (t.date.isAfter(endDate) || t.date.isAtSameMomentAs(endDate))) {
            return false;
          }

          if (includedSourceTypes != null &&
              !includedSourceTypes.contains(t.sourceType)) {
            return false;
          }
          if (category != null && t.category != category) return false;

          return true;
        }).toList();
      });
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'getDailySummary returns correct income, expense, and profit',
      () async {
        final targetDate = DateTime(2023, 11, 20);
        final summary = await financeService.getDailySummary(targetDate);

        expect(summary['income'], 100.0);
        // Expense: 50 (Supplies) + 33.33 (1 day rent pro-rated)
        // 1000 * (1/30) = 33.3333...
        expect(summary['expense'], closeTo(83.33, 0.01));
        expect(summary['profit'], closeTo(16.67, 0.01));
      },
    );

    test(
      'getWeeklySummary returns correct income, expense, and profit',
      () async {
        // Assuming week starts on Monday (weekday 1)
        final targetDate = DateTime(2023, 11, 22); // Wednesday

        final summary = await financeService.getWeeklySummary(targetDate);

        // Transactions for this week: 1, 2, 3, 5
        // Income: 100 (Nov 20) + 75 (Nov 21) + 120 (Nov 22) = 295
        // Expense: 50 (Nov 20) = 50
        expect(summary['income'], 295.0);
        // Expense: 50 (Supplies) + 233.33 (7 days rent)
        // 1000 * (7/30) = 233.333...
        expect(summary['expense'], closeTo(283.33, 0.01));
        expect(summary['profit'], closeTo(11.67, 0.01));
      },
    );

    test(
      'getMonthlySummary returns correct income, expense, and profit',
      () async {
        final targetDate = DateTime(2023, 11, 10);

        final summary = await financeService.getMonthlySummary(targetDate);

        // All transactions except future one are in November 2023
        // Income: 100 + 75 + 120 = 295
        // Expense: 50 + 1000 = 1050
        expect(summary['income'], 295.0);
        // Expense: 50 (Supplies) + 533.33 (16 days rent: Nov 15-30 + Dec 1? No Nov 15-Dec 1 exclusive)
        // 1000 * 16/30 = 533.33...
        expect(summary['expense'], closeTo(583.33, 0.01));
        expect(summary['profit'], closeTo(-288.33, 0.01));
      },
    );

    test(
      'getYearlySummary returns correct income, expense, and profit',
      () async {
        final targetDate = DateTime(2023, 6, 15);

        final summary = await financeService.getYearlySummary(targetDate);

        // All transactions except future one are in 2023
        // Income: 100 + 75 + 120 = 295
        // Expense: 50 + 1000 = 1050
        expect(summary['income'], 295.0);
        expect(summary['expense'], 1050.0);
        expect(summary['profit'], -755.0);
      },
    );

    test('getDailySummary filters by category correctly', () async {
      final targetDate = DateTime(2023, 11, 20);
      final summary = await financeService.getDailySummary(
        targetDate,
        includedCategories: {'Consultation'},
      );

      expect(summary['income'], 100.0);
      expect(summary['expense'], 0.0);
      expect(summary['profit'], 100.0);
    });

    test('getDailySummary filters by sourceType correctly', () async {
      final targetDate = DateTime(2023, 11, 20);
      final summary = await financeService.getDailySummary(
        targetDate,
        includedSourceTypes: {TransactionSourceType.inventory},
      );

      expect(summary['income'], 0.0);
      expect(summary['expense'], 50.0);
      expect(summary['profit'], -50.0);
    });
  });
}
