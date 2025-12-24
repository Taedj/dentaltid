import 'dart:async';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/network/sync_broadcaster.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:dentaltid/src/features/inventory/data/inventory_repository.dart';
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(DatabaseService.instance);
});

final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService(
    ref,
    ref.watch(inventoryRepositoryProvider),
    ref.watch(auditServiceProvider),
    ref.watch(financeServiceProvider),
  );
});

final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final service = ref.read(inventoryServiceProvider);

  final subscription = service.onDataChanged.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());

  return service.getInventoryItems();
});

class InventoryService {
  final InventoryRepository _repository;
  final AuditService _auditService;
  final FinanceService _financeService;
  final Ref _ref;

  // Reactive Stream
  final StreamController<void> _dataChangeController =
      StreamController.broadcast();
  Stream<void> get onDataChanged => _dataChangeController.stream;

  InventoryService(
    this._ref,
    this._repository,
    this._auditService,
    this._financeService,
  );

  void _notifyDataChanged() {
    _dataChangeController.add(null);
  }

  void _broadcastChange(SyncAction action, InventoryItem data) {
    _ref
        .read(syncBroadcasterProvider)
        .broadcast(table: 'inventory', action: action, data: data.toJson());
  }

  Future<InventoryItem> addInventoryItem(InventoryItem item) async {
    final newItem = await _repository.createInventoryItem(item);
    _auditService.logEvent(
      AuditAction.createInventoryItem,
      details: 'Inventory item ${item.name} added.',
    );

    _notifyDataChanged();
    _broadcastChange(SyncAction.create, newItem);

    final transaction = Transaction(
      description: 'Purchase of ${item.name}',
      totalAmount: item.cost * item.quantity,
      type: TransactionType.expense,
      date: DateTime.now(),
      sourceType: TransactionSourceType.inventory,
      sourceId: newItem.id,
      category: 'Inventory',
    );
    await _financeService.addTransaction(transaction);
    return newItem;
  }

  Future<List<InventoryItem>> getInventoryItems() async {
    return await _repository.getInventoryItems();
  }

  Future<InventoryItem?> getInventoryItem(int id) async {
    return await _repository.getInventoryItemById(id);
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    final oldItem = await getInventoryItem(item.id!);
    if (oldItem == null) {
      throw Exception('Item not found');
    }

    await _repository.updateInventoryItem(item);
    _auditService.logEvent(
      AuditAction.updateInventoryItem,
      details: 'Inventory item ${item.name} updated.',
    );

    _notifyDataChanged();
    _broadcastChange(SyncAction.update, item);

    final quantityDiff = item.quantity - oldItem.quantity;
    if (quantityDiff != 0) {
      if (quantityDiff > 0) {
        // Only create a transaction if we are adding stock (Purchase)
        final transaction = Transaction(
          description: 'Purchase of ${item.name}',
          totalAmount: item.cost * quantityDiff,
          type: TransactionType.expense,
          date: DateTime.now(),
          sourceType: TransactionSourceType.inventory,
          sourceId: item.id,
          category: 'Inventory',
        );
        await _financeService.addTransaction(transaction);
      }
    }
  }

  Future<void> deleteInventoryItem(int id) async {
    final item = await _repository.getInventoryItemById(id);
    if (item == null) {
      throw Exception('Item not found');
    }
    await _repository.deleteInventoryItem(id);
    _auditService.logEvent(
      AuditAction.deleteInventoryItem,
      details: 'Inventory item with ID $id deleted.',
    );

    _notifyDataChanged();
    _broadcastChange(SyncAction.delete, item);
  }
}
