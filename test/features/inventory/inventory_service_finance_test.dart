import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/inventory/data/inventory_repository.dart';
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'inventory_service_finance_test.mocks.dart';

@GenerateMocks([InventoryRepository, AuditService, FinanceService])
void main() {
  group('InventoryService Finance Integration', () {
    late MockInventoryRepository mockInventoryRepository;
    late MockAuditService mockAuditService;
    late MockFinanceService mockFinanceService;
    late InventoryService inventoryService;
    late ProviderContainer container;

    setUp(() {
      mockInventoryRepository = MockInventoryRepository();
      mockAuditService = MockAuditService();
      mockFinanceService = MockFinanceService();

      container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(
            mockInventoryRepository,
          ),
          auditServiceProvider.overrideWithValue(mockAuditService),
          financeServiceProvider.overrideWithValue(mockFinanceService),
        ],
      );

      inventoryService = container.read(inventoryServiceProvider);
    });

    tearDown(() {
      container.dispose();
      reset(mockInventoryRepository);
      reset(mockAuditService);
      reset(mockFinanceService);
    });

    final testItem = InventoryItem(
      id: 1,
      name: 'Gloves',
      quantity: 100,
      expirationDate: DateTime(2024, 12, 31),
      supplier: 'Medical Supplies Inc.',
      cost: 0.50,
    );

    test('addInventoryItem creates an expense transaction', () async {
      when(
        mockInventoryRepository.createInventoryItem(any),
      ).thenAnswer((_) async => testItem);
      when(
        mockAuditService.logEvent(any, details: anyNamed('details')),
      ).thenAnswer((_) async => Future.value());
      when(
        mockFinanceService.addTransaction(
          any,
          invalidate: anyNamed('invalidate'),
        ),
      ).thenAnswer((_) async => Future.value());

      await inventoryService.addInventoryItem(testItem);

      verify(mockInventoryRepository.createInventoryItem(testItem)).called(1);
      verify(
        mockFinanceService.addTransaction(
          argThat(
            isA<Transaction>()
                .having(
                  (t) => t.description,
                  'description',
                  'Purchase of Gloves',
                )
                .having((t) => t.totalAmount, 'totalAmount', 50.0) // 100 * 0.50
                .having((t) => t.type, 'type', TransactionType.expense)
                .having(
                  (t) => t.sourceType,
                  'sourceType',
                  TransactionSourceType.inventory,
                )
                .having((t) => t.sourceId, 'sourceId', 1)
                .having((t) => t.category, 'category', 'Inventory'),
          ),
          invalidate: true,
        ),
      ).called(1);
    });

    test(
      'updateInventoryItem creates an expense transaction for quantity decrease',
      () async {
        final oldItem = testItem.copyWith(quantity: 100);
        final newItem = testItem.copyWith(quantity: 80); // 20 used

        when(
          mockInventoryRepository.getInventoryItemById(1),
        ).thenAnswer((_) async => oldItem);
        when(
          mockInventoryRepository.updateInventoryItem(any),
        ).thenAnswer((_) async => Future.value());
        when(
          mockAuditService.logEvent(any, details: anyNamed('details')),
        ).thenAnswer((_) async => Future.value());
        when(
          mockFinanceService.addTransaction(
            any,
            invalidate: anyNamed('invalidate'),
          ),
        ).thenAnswer((_) async => Future.value());

        await inventoryService.updateInventoryItem(newItem);

        verify(mockInventoryRepository.updateInventoryItem(newItem)).called(1);
        verify(
          mockFinanceService.addTransaction(
            argThat(
              isA<Transaction>()
                  .having((t) => t.description, 'description', 'Use of Gloves')
                  .having(
                    (t) => t.totalAmount,
                    'totalAmount',
                    10.0,
                  ) // 20 * 0.50
                  .having((t) => t.type, 'type', TransactionType.expense)
                  .having(
                    (t) => t.sourceType,
                    'sourceType',
                    TransactionSourceType.inventory,
                  )
                  .having((t) => t.sourceId, 'sourceId', 1)
                  .having((t) => t.category, 'category', 'Inventory'),
            ),
            invalidate: true,
          ),
        ).called(1);
      },
    );

    test(
      'updateInventoryItem creates an expense transaction for quantity increase',
      () async {
        final oldItem = testItem.copyWith(quantity: 100);
        final newItem = testItem.copyWith(quantity: 120); // 20 purchased

        when(
          mockInventoryRepository.getInventoryItemById(1),
        ).thenAnswer((_) async => oldItem);
        when(
          mockInventoryRepository.updateInventoryItem(any),
        ).thenAnswer((_) async => Future.value());
        when(
          mockAuditService.logEvent(any, details: anyNamed('details')),
        ).thenAnswer((_) async => Future.value());
        when(
          mockFinanceService.addTransaction(
            any,
            invalidate: anyNamed('invalidate'),
          ),
        ).thenAnswer((_) async => Future.value());

        await inventoryService.updateInventoryItem(newItem);

        verify(mockInventoryRepository.updateInventoryItem(newItem)).called(1);
        verify(
          mockFinanceService.addTransaction(
            argThat(
              isA<Transaction>()
                  .having(
                    (t) => t.description,
                    'description',
                    'Purchase of Gloves',
                  )
                  .having(
                    (t) => t.totalAmount,
                    'totalAmount',
                    10.0,
                  ) // 20 * 0.50
                  .having((t) => t.type, 'type', TransactionType.expense)
                  .having(
                    (t) => t.sourceType,
                    'sourceType',
                    TransactionSourceType.inventory,
                  )
                  .having((t) => t.sourceId, 'sourceId', 1)
                  .having((t) => t.category, 'category', 'Inventory'),
            ),
            invalidate: true,
          ),
        ).called(1);
      },
    );

    test(
      'updateInventoryItem does not create transaction if quantity is unchanged',
      () async {
        final oldItem = testItem.copyWith(quantity: 100);
        final newItem = testItem.copyWith(quantity: 100); // quantity unchanged

        when(
          mockInventoryRepository.getInventoryItemById(1),
        ).thenAnswer((_) async => oldItem);
        when(
          mockInventoryRepository.updateInventoryItem(any),
        ).thenAnswer((_) async => Future.value());
        when(
          mockAuditService.logEvent(any, details: anyNamed('details')),
        ).thenAnswer((_) async => Future.value());

        await inventoryService.updateInventoryItem(newItem);

        verify(mockInventoryRepository.updateInventoryItem(newItem)).called(1);
        verifyZeroInteractions(mockFinanceService);
      },
    );

    test(
      'deleteInventoryItem does not create transaction but logs audit event',
      () async {
        when(
          mockInventoryRepository.deleteInventoryItem(1),
        ).thenAnswer((_) async => Future.value());
        when(
          mockAuditService.logEvent(any, details: anyNamed('details')),
        ).thenAnswer((_) async => Future.value());

        await inventoryService.deleteInventoryItem(1);

        verify(mockInventoryRepository.deleteInventoryItem(1)).called(1);
        verifyZeroInteractions(mockFinanceService);
      },
    );
  });
}
