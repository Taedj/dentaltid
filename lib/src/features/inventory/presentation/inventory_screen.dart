import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _expirationDateController = TextEditingController();
  final _supplierController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _expirationDateController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryItemsAsyncValue = ref.watch(inventoryItemsProvider);
    final inventoryService = ref.watch(inventoryServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a quantity';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _expirationDateController,
                    decoration: const InputDecoration(
                      labelText: 'Expiration Date (YYYY-MM-DD)',
                    ),
                    keyboardType: TextInputType.datetime,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an expiration date';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _supplierController,
                    decoration: const InputDecoration(labelText: 'Supplier'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a supplier';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
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
                          );
                          await inventoryService.addInventoryItem(newItem);
                          ref.invalidate(
                            inventoryItemsProvider,
                          ); // Invalidate to refresh
                          _nameController.clear();
                          _quantityController.clear();
                          _expirationDateController.clear();
                          _supplierController.clear();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Add Item'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: inventoryItemsAsyncValue.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No items yet.'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          'Quantity: ${item.quantity} - Expires: ${item.expirationDate.toLocal().toString().split(' ')[0]}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Item'),
                                content: const Text(
                                  'Are you sure you want to delete this item?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && item.id != null) {
                              try {
                                await inventoryService.deleteInventoryItem(
                                  item.id!,
                                );
                                ref.invalidate(
                                  inventoryItemsProvider,
                                ); // Invalidate to refresh
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
