import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:flutter/material.dart';
import 'package:dentaltid/src/features/inventory/presentation/add_inventory_dialog.dart';
import 'package:dentaltid/src/features/inventory/presentation/use_inventory_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

enum InventorySortOption {
  nameAsc,
  nameDesc,
  quantityAsc,
  quantityDesc,
  expiryAsc,
  expiryDesc,
}

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  InventorySortOption _sortOption = InventorySortOption.nameAsc;
  String _searchQuery = '';
  bool _showExpiredOnly = false;
  bool _showLowStockOnly = false;

  Future<void> _showAddEditDialog({InventoryItem? item}) async {
    final l10n = AppLocalizations.of(context)!;

    if (item == null) {
      final userProfile = ref.read(userProfileProvider).value;
      if (userProfile != null && !userProfile.isPremium) {
          if (userProfile.cumulativeInventory >= 100) {
              _showLimitDialog(context);
              return;
          }
      }
    }

    await showDialog(
      context: context,
      builder: (context) => AddInventoryItemDialog(
        item: item,
        onSave: (newItem) async {
          try {
            if (newItem.id == null) {
              await ref
                  .read(inventoryServiceProvider)
                  .addInventoryItem(newItem);
              
              if (!mounted) return;

              // Increment
              final userProfile = ref.read(userProfileProvider).value;
              if (userProfile != null) {
                  ref.read(firebaseServiceProvider).incrementInventoryCount(userProfile.uid).then((_) {
                       if (mounted) ref.invalidate(userProfileProvider);
                  });
              }
            } else {
              await ref
                  .read(inventoryServiceProvider)
                  .updateInventoryItem(newItem);
              if (!mounted) return;
            }
            ref.invalidate(inventoryItemsProvider);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n.failedToSaveItemError}: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showUseDialog(InventoryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (context) => UseInventoryItemDialog(
        item: item,
        onUse: (quantity) async {
          try {
            final updatedItem = item.copyWith(
              quantity: item.quantity - quantity,
            );
            await ref
                .read(inventoryServiceProvider)
                .updateInventoryItem(updatedItem);
            if (!mounted) return;
            ref.invalidate(inventoryItemsProvider);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n.failedToUseItemError}: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showLimitDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Limit Reached'),
          content: const Text('You have reached the limit of 100 inventory items for the Trial version.\nPlease upgrade to Premium to continue adding items.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            )
          ],
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryItemsAsyncValue = ref.watch(inventoryItemsProvider);
    final inventoryService = ref.watch(inventoryServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    final userProfile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(l10n.inventory),
            if (userProfile != null && !userProfile.isPremium)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      '${userProfile.cumulativeInventory}/100',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showExpiredOnly ? Icons.warning : Icons.inventory),
            onPressed: () {
              setState(() {
                _showExpiredOnly = !_showExpiredOnly;
                if (_showExpiredOnly) _showLowStockOnly = false;
              });
            },
            tooltip: _showExpiredOnly
                ? l10n.showAllItems
                : l10n.showExpiredOnly,
          ),
          IconButton(
            icon: Icon(
              _showLowStockOnly ? Icons.warning_amber : Icons.inventory_2,
            ),
            onPressed: () {
              setState(() {
                _showLowStockOnly = !_showLowStockOnly;
                if (_showLowStockOnly) _showExpiredOnly = false;
              });
            },
            tooltip: _showLowStockOnly
                ? l10n.showAllItems
                : l10n.showLowStockOnly,
          ),
          PopupMenuButton<InventorySortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (InventorySortOption option) {
              setState(() {
                _sortOption = option;
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<InventorySortOption>>[
                  PopupMenuItem<InventorySortOption>(
                    value: InventorySortOption.nameAsc,
                    child: Text(l10n.nameAZ),
                  ),
                  PopupMenuItem<InventorySortOption>(
                    value: InventorySortOption.nameDesc,
                    child: Text(l10n.nameZA),
                  ),
                  PopupMenuItem<InventorySortOption>(
                    value: InventorySortOption.quantityAsc,
                    child: Text(l10n.quantityLowToHigh),
                  ),
                  PopupMenuItem<InventorySortOption>(
                    value: InventorySortOption.quantityDesc,
                    child: Text(l10n.quantityHighToLow),
                  ),
                  PopupMenuItem<InventorySortOption>(
                    value: InventorySortOption.expiryAsc,
                    child: Text(l10n.expirySoonestFirst),
                  ),
                  PopupMenuItem<InventorySortOption>(
                    value: InventorySortOption.expiryDesc,
                    child: Text(l10n.expiryLatestFirst),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchInventoryItems,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
                    .withAlpha((255 * 0.3).round()),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Items List
          Expanded(
            child: inventoryItemsAsyncValue.when(
              data: (items) {
                // Filter items
                var filteredItems = items.where((item) {
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      item.name.toLowerCase().contains(_searchQuery) ||
                      item.supplier.toLowerCase().contains(_searchQuery);

                  final isExpired = item.expirationDate.isBefore(
                    DateTime.now(),
                  );
                  final isLowStock = item.quantity <= item.lowStockThreshold;

                  final matchesFilter =
                      (!_showExpiredOnly && !_showLowStockOnly) ||
                      (_showExpiredOnly && isExpired) ||
                      (_showLowStockOnly && isLowStock);

                  return matchesSearch && matchesFilter;
                }).toList();

                // Sort items
                filteredItems.sort((a, b) {
                  switch (_sortOption) {
                    case InventorySortOption.nameAsc:
                      return a.name.compareTo(b.name);
                    case InventorySortOption.nameDesc:
                      return b.name.compareTo(a.name);
                    case InventorySortOption.quantityAsc:
                      return a.quantity.compareTo(b.quantity);
                    case InventorySortOption.quantityDesc:
                      return b.quantity.compareTo(a.quantity);
                    case InventorySortOption.expiryAsc:
                      return a.expirationDate.compareTo(b.expirationDate);
                    case InventorySortOption.expiryDesc:
                      return b.expirationDate.compareTo(a.expirationDate);
                  }
                });

                if (filteredItems.isEmpty) {
                  return Center(child: Text(l10n.noItemsFound));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isExpired = item.expirationDate.isBefore(
                      DateTime.now(),
                    );
                    final isLowStock = item.quantity <= item.lowStockThreshold;
                    final daysUntilExpiry = item.expirationDate
                        .difference(DateTime.now())
                        .inDays;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      color: isExpired
                          ? Colors.red.withAlpha((255 * 0.1).round())
                          : isLowStock
                          ? Colors.orange.withAlpha((255 * 0.1).round())
                          : null,
                      child: ListTile(
                        leading: Icon(
                          isExpired
                              ? Icons.warning
                              : isLowStock
                              ? Icons.warning_amber
                              : Icons.inventory,
                          color: isExpired
                              ? Colors.red
                              : isLowStock
                              ? Colors.orange
                              : Theme.of(context).primaryColor,
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isExpired ? Colors.red[700] : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${l10n.quantity}: ${item.quantity}'),
                            Text('${l10n.supplier}: ${item.supplier}'),
                            Text(
                              '${l10n.expires} ${item.expirationDate.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(
                                color: isExpired
                                    ? Colors.red
                                    : daysUntilExpiry <= item.thresholdDays
                                    ? Colors.orange
                                    : null,
                              ),
                            ),
                            if (isExpired)
                              Text(
                                l10n.expired,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                            else if (isLowStock)
                              Text(
                                l10n.lowStock,
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.green,
                              ),
                              tooltip: l10n.useTooltip,
                              onPressed: () => _showUseDialog(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditDialog(item: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(l10n.deleteItem),
                                    content: Text(l10n.confirmDeleteItem),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: Text(
                                          l10n.deleteItemButton,
                                        ), // Delete button
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true && item.id != null) {
                                  try {
                                    await inventoryService.deleteInventoryItem(
                                      item.id!,
                                    );
                                    ref.invalidate(inventoryItemsProvider);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${l10n.failedToDeleteItemError}: ${e.toString()}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('${l10n.error}$error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: Text(l10n.addItem),
      ),
    );
  }
}
