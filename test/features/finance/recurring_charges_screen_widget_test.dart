import 'package:dentaltid/src/features/finance/application/recurring_charge_service.dart';
import 'package:dentaltid/src/features/finance/domain/recurring_charge.dart';
import 'package:dentaltid/src/features/finance/presentation/recurring_charges_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';

import 'recurring_charges_screen_widget_test.mocks.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

@GenerateMocks([RecurringChargeService])
void main() {
  group('RecurringChargesScreen Widget Test', () {
    late MockRecurringChargeService mockRecurringChargeService;

    setUp(() {
      mockRecurringChargeService = MockRecurringChargeService();
      when(
        mockRecurringChargeService.getAllRecurringCharges(),
      ).thenAnswer((_) async => Future.value([])); // Default to empty list
    });

    Widget createRecurringChargesScreen() {
      return ProviderScope(
        overrides: [
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
            initialLocation: '/finance/recurring-charges',
            routes: [
              GoRoute(
                path: '/finance/recurring-charges',
                builder: (context, state) => const RecurringChargesScreen(),
              ),
              GoRoute(
                path: '/finance/recurring-charges/add',
                builder: (context, state) =>
                    const Text('Add Recurring Charge Screen'),
              ),
              GoRoute(
                path: '/finance/recurring-charges/edit',
                builder: (context, state) =>
                    const Text('Edit Recurring Charge Screen'),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('RecurringChargesScreen displays app bar title', (
      tester,
    ) async {
      await tester.pumpWidget(createRecurringChargesScreen());
      await tester.pumpAndSettle();

      expect(find.text('Recurring Charges'), findsOneWidget);
    });

    testWidgets(
      'RecurringChargesScreen displays "No recurring charges found" when no data',
      (tester) async {
        when(
          mockRecurringChargeService.getAllRecurringCharges(),
        ).thenAnswer((_) async => Future.value([]));
        await tester.pumpWidget(createRecurringChargesScreen());
        await tester.pumpAndSettle();

        expect(find.text('No recurring charges found'), findsOneWidget);
      },
    );

    testWidgets(
      'RecurringChargesScreen displays charges list when data is available',
      (tester) async {
        final mockCharges = [
          RecurringCharge(
            id: 1,
            name: 'Monthly Rent',
            amount: 1000.0,
            frequency: RecurringChargeFrequency.monthly,
            startDate: DateTime(2023, 1, 1),
            isActive: true,
            description: 'Office Rent',
          ),
          RecurringCharge(
            id: 2,
            name: 'Yearly Insurance',
            amount: 1200.0,
            frequency: RecurringChargeFrequency.yearly,
            startDate: DateTime(2023, 1, 1),
            isActive: true,
            description: 'Annual Insurance Policy',
          ),
        ];

        when(
          mockRecurringChargeService.getAllRecurringCharges(),
        ).thenAnswer((_) async => Future.value(mockCharges));

        await tester.pumpWidget(createRecurringChargesScreen());
        await tester.pumpAndSettle();

        expect(find.text('Monthly Rent'), findsOneWidget);
        expect(find.text('Yearly Insurance'), findsOneWidget);
        expect(find.text('No recurring charges found'), findsNothing);
      },
    );

    testWidgets(
      'RecurringChargesScreen navigates to Add Recurring Charge screen',
      (tester) async {
        await tester.pumpWidget(createRecurringChargesScreen());
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('Add Recurring Charge Screen'), findsOneWidget);
      },
    );

    testWidgets(
      'RecurringChargesScreen navigates to Edit Recurring Charge screen',
      (tester) async {
        final mockCharges = [
          RecurringCharge(
            id: 1,
            name: 'Monthly Rent',
            amount: 1000.0,
            frequency: RecurringChargeFrequency.monthly,
            startDate: DateTime(2023, 1, 1),
            isActive: true,
            description: 'Office Rent',
          ),
        ];

        when(
          mockRecurringChargeService.getAllRecurringCharges(),
        ).thenAnswer((_) async => Future.value(mockCharges));
        await tester.pumpWidget(createRecurringChargesScreen());
        await tester.pumpAndSettle();

        expect(find.text('Monthly Rent'), findsOneWidget);
        await tester.tap(find.text('Monthly Rent'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Recurring Charge Screen'), findsOneWidget);
      },
    );
  });
}
