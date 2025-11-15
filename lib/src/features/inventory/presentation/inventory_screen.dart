import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _expirationDateController = TextEditingController();
  final _supplierController = TextEditingController();
  final _thresholdDaysController = TextEditingController(text: '30');
  final _lowStockThresholdController = TextEditingController(text: '5');
  InventorySortOption _sortOption = InventorySortOption.nameAsc;
  String _searchQuery = '';
  bool _showExpiredOnly = false;
  bool _showLowStockOnly = false;
  InventoryItem? _editingItem;

  void _showEditDialog(InventoryItem item) {
    setState(() {
      _editingItem = item;
      _nameController.text = item.name;
      _quantityController.text = item.quantity.toString();
      _expirationDateController.text = item.expirationDate
          .toIso8601String()
          .split('T')[0];
      _supplierController.text = item.supplier;
      _thresholdDaysController.text = item.thresholdDays.toString();
      _lowStockThresholdController.text = item.lowStockThreshold.toString();
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Form(
          key: _editFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _expirationDateController,
                  decoration: InputDecoration(
                    labelText: 'Expiration Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.parse(
                            _expirationDateController.text,
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            _expirationDateController.text = picked
                                .toIso8601String()
                                .split('T')[0];
                          });
                        }
                      },
                    ),
                  ),
                  keyboardType: TextInputType.datetime,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _supplierController,
                  decoration: InputDecoration(labelText: 'Supplier'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter supplier';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _thresholdDaysController,
                  decoration: InputDecoration(labelText: 'Threshold Days'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter threshold days';
                    }
                    final days = int.tryParse(value);
                    if (days == null || days <= 0) {
                      return 'Enter a positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lowStockThresholdController,
                  decoration: InputDecoration(labelText: 'Low Stock Threshold'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter low stock threshold';
                    }
                    final threshold = int.tryParse(value);
                    if (threshold == null || threshold < 0) {
                      return 'Enter a non-negative number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _editingItem = null;
                _nameController.clear();
                _quantityController.clear();
                _expirationDateController.clear();
                _supplierController.clear();
                _thresholdDaysController.text = '30';
                _lowStockThresholdController.text = '5';
                _lowStockThresholdController.text = '5';
                _lowStockThresholdController.text = '5';
              });
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_editFormKey.currentState!.validate()) {
                try {
                  final updatedItem = InventoryItem(
                    id: _editingItem!.id,
                    name: _nameController.text,
                    quantity: int.parse(_quantityController.text),
                    expirationDate: DateTime.parse(
                      _expirationDateController.text,
                    ),
                    supplier: _supplierController.text,
                    thresholdDays: int.parse(_thresholdDaysController.text),
                    lowStockThreshold: int.parse(
                      _lowStockThresholdController.text,
                    ),
                  );
                  await ref
                      .read(inventoryServiceProvider)
                      .updateInventoryItem(updatedItem);
                  ref.invalidate(inventoryItemsProvider);
                  setState(() {
                    _editingItem = null;
                    _nameController.clear();
                    _quantityController.clear();
                    _expirationDateController.clear();
                    _supplierController.clear();
                    _thresholdDaysController.text = '30';
                    _lowStockThresholdController.text = '5';
                  });
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update item: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _expirationDateController.dispose();
    _supplierController.dispose();
    _thresholdDaysController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryItemsAsyncValue = ref.watch(inventoryItemsProvider);
    final inventoryService = ref.watch(inventoryServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventory),
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
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Add Item Form
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: l10n.name),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.enterName;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(labelText: l10n.quantity),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.enterQuantity;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expirationDateController,
                          decoration: InputDecoration(
                            labelText: l10n.expirationDate,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(
                                    const Duration(days: 30),
                                  ), // Default to 30 days from now
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2101),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _expirationDateController.text = picked
                                        .toIso8601String()
                                        .split('T')[0];
                                  });
                                }
                              },
                            ),
                          ),
                          keyboardType: TextInputType.datetime,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.enterDate; // Reusing this key
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _supplierController,
                          decoration: InputDecoration(labelText: l10n.supplier),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.enterSupplier;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _thresholdDaysController,
                          decoration: InputDecoration(
                            labelText: 'Threshold Days',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter threshold days';
                            }
                            final days = int.tryParse(value);
                            if (days == null || days <= 0) {
                              return 'Enter a positive number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _lowStockThresholdController,
                          decoration: InputDecoration(
                            labelText: 'Low Stock Threshold',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter low stock threshold';
                            }
                            final threshold = int.tryParse(value);
                            if (threshold == null || threshold < 0) {
                              return 'Enter a non-negative number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            final newItem = InventoryItem(
                              name: _nameController.text,
                              quantity: int.parse(_quantityController.text),
                              expirationDate: DateTime.parse(
                                _expirationDateController.text,
                              ),
                              supplier: _supplierController.text,
                              thresholdDays: int.parse(
                                _thresholdDaysController.text,
                              ),
                              lowStockThreshold: int.parse(
                                _lowStockThresholdController.text,
                              ),
                            );
                            await inventoryService.addInventoryItem(newItem);
                            ref.invalidate(inventoryItemsProvider);
                            _nameController.clear();
                            _quantityController.clear();
                            _expirationDateController.clear();
                            _supplierController.clear();
                            _thresholdDaysController.text = '30';
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to add item: ${e.toString()}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: Text(l10n.addItem),
                    ),
                  ),
                ],
              ),
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
                          ? Colors.red.withValues(alpha: 0.1)
                          : isLowStock
                          ? Colors.orange.withValues(alpha: 0.1)
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
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditDialog(item),
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
                                            'Failed to delete item: ${e.toString()}',
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
    );
  }
}
