import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/inventory/data/inventory_repository.dart';
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(DatabaseService.instance);
});

final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService(
    ref.watch(inventoryRepositoryProvider),
    ref.watch(auditServiceProvider),
    ref,
  );
});

final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getInventoryItems();
});

class InventoryService {
  final InventoryRepository _repository;
  final AuditService _auditService;
  final Ref _ref;

  InventoryService(this._repository, this._auditService, this._ref);

  Future<void> addInventoryItem(InventoryItem item) async {
    await _repository.createInventoryItem(item);
    _auditService.logEvent(
      AuditAction.createInventoryItem,
      details: 'Inventory item ${item.name} added.',
    );
    // Invalidate inventory providers to refresh the UI
    _ref.invalidate(inventoryItemsProvider);
  }

  Future<List<InventoryItem>> getInventoryItems() async {
    return await _repository.getInventoryItems();
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await _repository.updateInventoryItem(item);
    _auditService.logEvent(
      AuditAction.updateInventoryItem,
      details: 'Inventory item ${item.name} updated.',
    );
    // Invalidate inventory providers to refresh the UI
    _ref.invalidate(inventoryItemsProvider);
  }

  Future<void> deleteInventoryItem(int id) async {
    await _repository.deleteInventoryItem(id);
    _auditService.logEvent(
      AuditAction.deleteInventoryItem,
      details: 'Inventory item with ID $id deleted.',
    );
    // Invalidate inventory providers to refresh the UI
    _ref.invalidate(inventoryItemsProvider);
  }
}
