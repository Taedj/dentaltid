import 'dart:async';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/sync_manager.dart';
import 'package:dentaltid/src/core/data_sync_service.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/features/inventory/data/inventory_repository.dart';
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/user_model.dart';
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
    ref.watch(inventoryRepositoryProvider),
    ref.watch(auditServiceProvider),
    ref.watch(financeServiceProvider),
    ref,
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
  final StreamController<void> _dataChangeController = StreamController.broadcast();
  Stream<void> get onDataChanged => _dataChangeController.stream;

  InventoryService(this._repository, this._auditService, this._financeService, this._ref);

  void _notifyDataChanged() {
    _dataChangeController.add(null);
  }

  Future<InventoryItem> addInventoryItem(InventoryItem item, {bool broadcast = true}) async {
    final newItem = await _repository.createInventoryItem(item);
    _auditService.logEvent(
      AuditAction.createInventoryItem,
      details: 'Inventory item ${item.name} added.',
    );

    _notifyDataChanged();

    if (broadcast) {
      _syncLocalChange(SyncDataType.inventory, 'create', newItem.toJson());
    }

    final transaction = Transaction(
      description: 'Purchase of ${item.name}',
      totalAmount: item.cost * item.quantity,
      type: TransactionType.expense,
      date: DateTime.now(),
      sourceType: TransactionSourceType.inventory,
      sourceId: newItem.id,
      category: 'Inventory',
    );
    await _financeService.addTransaction(transaction, broadcast: broadcast);
    return newItem;
  }

  Future<List<InventoryItem>> getInventoryItems() async {
    return await _repository.getInventoryItems();
  }

  Future<InventoryItem?> getInventoryItem(int id) async {
    return await _repository.getInventoryItemById(id);
  }

  Future<void> updateInventoryItem(InventoryItem item, {bool broadcast = true}) async {
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

    if (broadcast) {
      _syncLocalChange(SyncDataType.inventory, 'update', item.toJson());
    }

    final quantityDiff = item.quantity - oldItem.quantity;
    if (quantityDiff != 0) {
      if (quantityDiff > 0) {
        // Only create a transaction if we are adding stock (Purchase)
        // Reducing stock (Usage) is not an expense, as the cost was already incurred upon purchase.
        final transaction = Transaction(
          description: 'Purchase of ${item.name}',
          totalAmount: item.cost * quantityDiff,
          type: TransactionType.expense,
          date: DateTime.now(),
          sourceType: TransactionSourceType.inventory,
          sourceId: item.id,
          category: 'Inventory',
        );
        await _financeService.addTransaction(transaction, broadcast: broadcast);
      }
      // If quantityDiff < 0, it's usage, no financial transaction needed.
    }
  }

  Future<void> deleteInventoryItem(int id, {bool broadcast = true}) async {
    await _repository.deleteInventoryItem(id);
    _auditService.logEvent(
      AuditAction.deleteInventoryItem,
      details: 'Inventory item with ID $id deleted.',
    );

    _notifyDataChanged();

    if (broadcast) {
      _syncLocalChange(SyncDataType.inventory, 'delete', {'id': id});
    }
  }

  void _syncLocalChange(SyncDataType type, String operation, Map<String, dynamic> data) {
    try {
      final userProfile = _ref.read(userProfileProvider).value;
      if (userProfile == null) return;

      final syncManager = _ref.read(syncManagerProvider);
      if (userProfile.role == UserRole.dentist) {
        syncManager.broadcastLocalChange(
          type: type,
          operation: operation,
          data: data,
        );
      } else {
        syncManager.sendToServer(
          type: type,
          operation: operation,
          data: data,
        );
      }
    } catch (_) {}
  }
}
