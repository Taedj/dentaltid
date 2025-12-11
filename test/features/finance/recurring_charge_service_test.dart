import 'package:dentaltid/src/features/finance/application/recurring_charge_service.dart';
import 'package:dentaltid/src/features/finance/domain/recurring_charge.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/data/recurring_charge_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'recurring_charge_service_test.mocks.dart';

@GenerateMocks([RecurringChargeRepository, FinanceService])
void main() {
  group('RecurringChargeService', () {
    late MockRecurringChargeRepository mockRecurringChargeRepository;
    late MockFinanceService mockFinanceService;
    late RecurringChargeService recurringChargeService;
    late ProviderContainer container;

    setUp(() {
      mockRecurringChargeRepository = MockRecurringChargeRepository();
      mockFinanceService = MockFinanceService();

      container = ProviderContainer(
        overrides: [
          recurringChargeRepositoryProvider.overrideWithValue(
            mockRecurringChargeRepository,
          ),
          financeServiceProvider.overrideWithValue(mockFinanceService),
        ],
      );

      recurringChargeService = container.read(recurringChargeServiceProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('addRecurringCharge calls repository create method', () async {
      final charge = RecurringCharge(
        name: 'Test Charge',
        amount: 100.0,
        frequency: RecurringChargeFrequency.monthly,
        startDate: DateTime(2023, 1, 1),
        isActive: true,
        description: 'Test Description',
      );

      when(
        mockRecurringChargeRepository.createRecurringCharge(charge),
      ).thenAnswer((_) async => Future.value());

      await recurringChargeService.addRecurringCharge(charge);

      verify(
        mockRecurringChargeRepository.createRecurringCharge(charge),
      ).called(1);
    });

    test('getAllRecurringCharges calls repository getAll method', () async {
      when(
        mockRecurringChargeRepository.getAllRecurringCharges(),
      ).thenAnswer((_) async => []);

      await recurringChargeService.getAllRecurringCharges();

      verify(mockRecurringChargeRepository.getAllRecurringCharges()).called(1);
    });

    test('updateRecurringCharge calls repository update method', () async {
      final charge = RecurringCharge(
        id: 1,
        name: 'Updated Charge',
        amount: 150.0,
        frequency: RecurringChargeFrequency.monthly,
        startDate: DateTime(2023, 1, 1),
        isActive: true,
        description: 'Updated Description',
      );

      when(
        mockRecurringChargeRepository.updateRecurringCharge(charge),
      ).thenAnswer((_) async => Future.value());

      await recurringChargeService.updateRecurringCharge(charge);

      verify(
        mockRecurringChargeRepository.updateRecurringCharge(charge),
      ).called(1);
    });

    test('deleteRecurringCharge calls repository delete method', () async {
      when(
        mockRecurringChargeRepository.deleteRecurringCharge(1),
      ).thenAnswer((_) async => Future.value());

      await recurringChargeService.deleteRecurringCharge(1);

      verify(mockRecurringChargeRepository.deleteRecurringCharge(1)).called(1);
    });

    group('generateTransactionsForRecurringCharges', () {
      final mockCharge = RecurringCharge(
        id: 1,
        name: 'Rent',
        amount: 500.0,
        frequency: RecurringChargeFrequency.monthly,
        startDate: DateTime(2023, 1, 15),
        isActive: true,
        description: 'Monthly Office Rent',
      );

      test(
        'should generate monthly transactions if none exist for the period',
        () async {
          when(
            mockRecurringChargeRepository.getAllRecurringCharges(),
          ).thenAnswer((_) async => [mockCharge]);
          when(
            mockFinanceService.getTransactionsFiltered(
              startDate: anyNamed('startDate'),
              endDate: anyNamed('endDate'),
              includedSourceTypes: anyNamed('includedSourceTypes'),
              category: anyNamed('category'),
            ),
          ).thenAnswer((_) async => []); // No existing transactions

          final periodStart = DateTime(2023, 1, 1);
          final periodEnd = DateTime(2023, 3, 31); // Jan, Feb, Mar

          await recurringChargeService.generateTransactionsForRecurringCharges(
            periodStart,
            periodEnd,
          );

          // Expect transactions for Jan 15, Feb 15, Mar 15
          verify(
            mockFinanceService.addTransaction(
              argThat(
                isA<Transaction>()
                    .having((t) => t.date.month, 'date month', 1)
                    .having((t) => t.date.day, 'date day', 15)
                    .having((t) => t.sourceId, 'sourceId', 1)
                    .having((t) => t.category, 'category', 'Rent'),
              ),
            ),
          ).called(1);
          verify(
            mockFinanceService.addTransaction(
              argThat(
                isA<Transaction>()
                    .having((t) => t.date.month, 'date month', 2)
                    .having((t) => t.date.day, 'date day', 15)
                    .having((t) => t.sourceId, 'sourceId', 1)
                    .having((t) => t.category, 'category', 'Rent'),
              ),
            ),
          ).called(1);
          verify(
            mockFinanceService.addTransaction(
              argThat(
                isA<Transaction>()
                    .having((t) => t.date.month, 'date month', 3)
                    .having((t) => t.date.day, 'date day', 15)
                    .having((t) => t.sourceId, 'sourceId', 1)
                    .having((t) => t.category, 'category', 'Rent'),
              ),
            ),
          ).called(1);
        },
      );

      test('should not duplicate transactions if they already exist', () async {
        when(
          mockRecurringChargeRepository.getAllRecurringCharges(),
        ).thenAnswer((_) async => [mockCharge]);

        final existingTransaction = Transaction(
          sessionId: 0,
          description: 'Monthly Office Rent',
          totalAmount: 500.0,
          paidAmount: 500.0,
          type: TransactionType.expense,
          date: DateTime(2023, 2, 15), // Already exists for Feb 15
          status: TransactionStatus.paid,
          paymentMethod: PaymentMethod.bankTransfer,
          sourceType: TransactionSourceType.recurringCharge,
          sourceId: 1,
          category: 'Rent',
        );
        when(
          mockFinanceService.getTransactionsFiltered(
            startDate: argThat(
              isA<DateTime>().having((d) => d.month, 'month', 2),
              named: 'startDate',
            ),
            endDate: argThat(
              isA<DateTime>().having((d) => d.month, 'month', 2),
              named: 'endDate',
            ),
            includedSourceTypes: {TransactionSourceType.recurringCharge},
            category: 'Rent',
          ),
        ).thenAnswer((_) async => [existingTransaction]);

        when(
          mockFinanceService.getTransactionsFiltered(
            startDate: argThat(
              isA<DateTime>().having((d) => d.month, 'month', 1),
              named: 'startDate',
            ),
            endDate: argThat(
              isA<DateTime>().having((d) => d.month, 'month', 1),
              named: 'endDate',
            ),
            includedSourceTypes: {TransactionSourceType.recurringCharge},
            category: 'Rent',
          ),
        ).thenAnswer((_) async => []);

        when(
          mockFinanceService.getTransactionsFiltered(
            startDate: argThat(
              isA<DateTime>().having((d) => d.month, 'month', 3),
              named: 'startDate',
            ),
            endDate: argThat(
              isA<DateTime>().having((d) => d.month, 'month', 3),
              named: 'endDate',
            ),
            includedSourceTypes: {TransactionSourceType.recurringCharge},
            category: 'Rent',
          ),
        ).thenAnswer((_) async => []);

        final periodStart = DateTime(2023, 1, 1);
        final periodEnd = DateTime(2023, 3, 31);

        await recurringChargeService.generateTransactionsForRecurringCharges(
          periodStart,
          periodEnd,
        );

        // Expect transactions for Jan 15 and Mar 15 only
        verify(
          mockFinanceService.addTransaction(
            argThat(
              isA<Transaction>()
                  .having((t) => t.date.month, 'date month', 1)
                  .having((t) => t.date.day, 'date day', 15),
            ),
          ),
        ).called(1);
        verify(
          mockFinanceService.addTransaction(
            argThat(
              isA<Transaction>()
                  .having((t) => t.date.month, 'date month', 3)
                  .having((t) => t.date.day, 'date day', 15),
            ),
          ),
        ).called(1);
        verifyNever(
          mockFinanceService.addTransaction(
            argThat(
              isA<Transaction>().having((t) => t.date.month, 'date month', 2),
            ),
          ),
        );
      });

      test(
        'should generate quarterly transactions if none exist for the period',
        () async {
          final quarterlyCharge = mockCharge.copyWith(
            frequency: RecurringChargeFrequency.quarterly,
            startDate: DateTime(2023, 1, 1), // Jan 1, Apr 1, Jul 1, Oct 1
          );
          when(
            mockRecurringChargeRepository.getAllRecurringCharges(),
          ).thenAnswer((_) async => [quarterlyCharge]);
          when(
            mockFinanceService.getTransactionsFiltered(
              startDate: anyNamed('startDate'),
              endDate: anyNamed('endDate'),
              includedSourceTypes: anyNamed('includedSourceTypes'),
              category: anyNamed('category'),
            ),
          ).thenAnswer((_) async => []); // No existing transactions

          final periodStart = DateTime(2023, 1, 1);
          final periodEnd = DateTime(
            2023,
            6,
            30,
          ); // Jan-June (expect Jan 1, Apr 1)

          await recurringChargeService.generateTransactionsForRecurringCharges(
            periodStart,
            periodEnd,
          );

          verify(
            mockFinanceService.addTransaction(
              argThat(
                isA<Transaction>()
                    .having((t) => t.date.month, 'date month', 1)
                    .having((t) => t.date.day, 'date day', 1),
              ),
            ),
          ).called(1);
          verify(
            mockFinanceService.addTransaction(
              argThat(
                isA<Transaction>()
                    .having((t) => t.date.month, 'date month', 4)
                    .having((t) => t.date.day, 'date day', 1),
              ),
            ),
          ).called(1);
        },
      );

      test(
        'should generate yearly transactions if none exist for the period',
        () async {
          final yearlyCharge = mockCharge.copyWith(
            frequency: RecurringChargeFrequency.yearly,
            startDate: DateTime(2023, 1, 1), // Jan 1, 2023, Jan 1, 2024
          );
          when(
            mockRecurringChargeRepository.getAllRecurringCharges(),
          ).thenAnswer((_) async => [yearlyCharge]);
          when(
            mockFinanceService.getTransactionsFiltered(
              startDate: anyNamed('startDate'),
              endDate: anyNamed('endDate'),
              includedSourceTypes: anyNamed('includedSourceTypes'),
              category: anyNamed('category'),
            ),
          ).thenAnswer((_) async => []); // No existing transactions

          final periodStart = DateTime(2023, 1, 1);
          final periodEnd = DateTime(
            2024,
            1,
            31,
          ); // Covers Jan 1, 2023 and Jan 1, 2024

          await recurringChargeService.generateTransactionsForRecurringCharges(
            periodStart,
            periodEnd,
          );

          verify(
            mockFinanceService.addTransaction(
              argThat(
                isA<Transaction>()
                    .having((t) => t.date.year, 'date year', 2023)
                    .having((t) => t.date.month, 'date month', 1)
                    .having((t) => t.date.day, 'date day', 1),
              ),
            ),
          ).called(1);
          verify(
            mockFinanceService.addTransaction(
              argThat(
                isA<Transaction>()
                    .having((t) => t.date.year, 'date year', 2024)
                    .having((t) => t.date.month, 'date month', 1)
                    .having((t) => t.date.day, 'date day', 1),
              ),
            ),
          ).called(1);
        },
      );
    });
  });
}
