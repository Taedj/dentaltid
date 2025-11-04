import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/inventory/data/inventory_repository.dart';
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(DatabaseService.instance);
});

final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService(ref.watch(inventoryRepositoryProvider));
});

final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getInventoryItems();
});

class InventoryService {
  final InventoryRepository _repository;

  InventoryService(this._repository);

  Future<void> addInventoryItem(InventoryItem item) async {
    await _repository.createInventoryItem(item);
  }

  Future<List<InventoryItem>> getInventoryItems() async {
    return await _repository.getInventoryItems();
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await _repository.updateInventoryItem(item);
  }

  Future<void> deleteInventoryItem(int id) async {
    await _repository.deleteInventoryItem(id);
  }
}
