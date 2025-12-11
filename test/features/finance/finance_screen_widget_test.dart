import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:dentaltid/src/features/finance/presentation/finance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:go_router/go_router.dart'; // Import go_router

import 'finance_screen_widget_test.mocks.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dentaltid/src/features/finance/application/recurring_charge_service.dart';

@GenerateMocks([FinanceService, RecurringChargeService])
void main() {
  group('FinanceScreen Widget Test', () {
    late MockFinanceService mockFinanceService;
    late MockRecurringChargeService mockRecurringChargeService;

    setUp(() {
      mockFinanceService = MockFinanceService();
      mockRecurringChargeService = MockRecurringChargeService();

      // Stub getTransactions to return an empty list initially
      when(
        mockFinanceService.getTransactions(),
      ).thenAnswer((_) async => Future.value([]));
      when(
        mockRecurringChargeService.generateTransactionsForRecurringCharges(
          any,
          any,
        ),
      ).thenAnswer((_) async => Future.value());
    });

    Widget createFinanceScreen() {
      return ProviderScope(
        overrides: [
          financeServiceProvider.overrideWithValue(mockFinanceService),
          recurringChargeServiceProvider.overrideWithValue(
            mockRecurringChargeService,
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            initialLocation: '/finance',
            routes: [
              GoRoute(
                path: '/finance',
                builder: (context, state) => const FinanceScreen(),
                routes: [
                  GoRoute(
                    path: 'recurring-charges',
                    builder: (context, state) =>
                        const Text('Recurring Charges Screen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('FinanceScreen displays app bar title', (tester) async {
      await tester.pumpWidget(createFinanceScreen());
      await tester.pumpAndSettle(); // Allow initial FutureBuilders to complete

      expect(find.text('Finance'), findsOneWidget);
    });

    testWidgets('FinanceScreen displays "No transactions found" when no data', (
      tester,
    ) async {
      when(
        mockFinanceService.getTransactions(),
      ).thenAnswer((_) async => Future.value([]));
      await tester.pumpWidget(createFinanceScreen());
      await tester.pumpAndSettle();

      expect(find.text('No transactions found'), findsOneWidget);
    });

    testWidgets(
      'FinanceScreen displays transactions list when data is available',
      (tester) async {
        final mockTransactions = [
          Transaction(
            id: 1,
            description: 'Test Income',
            totalAmount: 100.0,
            type: TransactionType.income,
            date: DateTime.now(),
            sourceType: TransactionSourceType.appointment,
            category: 'Consultation',
          ),
          Transaction(
            id: 2,
            description: 'Test Expense',
            totalAmount: 50.0,
            type: TransactionType.expense,
            date: DateTime.now(),
            sourceType: TransactionSourceType.inventory,
            category: 'Supplies',
          ),
        ];

        when(
          mockFinanceService.getTransactions(),
        ).thenAnswer((_) async => Future.value(mockTransactions));
        when(
          mockRecurringChargeService.generateTransactionsForRecurringCharges(
            any,
            any,
          ),
        ).thenAnswer((_) async => Future.value());

        await tester.pumpWidget(createFinanceScreen());
        await tester.pumpAndSettle();

        expect(find.text('Test Income'), findsOneWidget);
        expect(find.text('Test Expense'), findsOneWidget);
        expect(find.text('No transactions found'), findsNothing);
      },
    );

    testWidgets('FinanceScreen navigates to Recurring Charges screen', (
      tester,
    ) async {
      await tester.pumpWidget(createFinanceScreen());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Recurring Charges'), findsOneWidget);
      await tester.tap(find.byTooltip('Recurring Charges'));
      await tester.pumpAndSettle(); // Allow navigation to complete

      expect(find.text('Recurring Charges Screen'), findsOneWidget);
    });
  });
}
