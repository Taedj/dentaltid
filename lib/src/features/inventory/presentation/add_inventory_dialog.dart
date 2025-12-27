import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dentaltid/l10n/app_localizations.dart'; // Add import

class AddInventoryItemDialog extends ConsumerStatefulWidget {
  final InventoryItem? item;
  final Function(InventoryItem) onSave;

  const AddInventoryItemDialog({super.key, this.item, required this.onSave});

  @override
  ConsumerState<AddInventoryItemDialog> createState() =>
      _AddInventoryItemDialogState();
}

class _AddInventoryItemDialogState
    extends ConsumerState<AddInventoryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _costController;
  late TextEditingController _supplierController;
  late TextEditingController _supplierContactController;
  late TextEditingController _thresholdController;
  late TextEditingController _lowStockController;
  late DateTime _expirationDate;

  bool _isTotalCost = false; // Toggle state: false = Per Unit, true = Total

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.item?.quantity.toString() ?? '',
    );
    _costController = TextEditingController(
      text: widget.item?.cost.toString() ?? '',
    );
    _supplierController = TextEditingController(
      text: widget.item?.supplier ?? '',
    );
    _supplierContactController = TextEditingController(
      text: widget.item?.supplierContact ?? '',
    );
    _thresholdController = TextEditingController(
      text: widget.item?.thresholdDays.toString() ?? '30',
    );
    _lowStockController = TextEditingController(
      text: widget.item?.lowStockThreshold.toString() ?? '5',
    );
    _expirationDate = widget.item?.expirationDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _supplierController.dispose();
    _supplierContactController.dispose();
    _thresholdController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  double _calculateUnitCost() {
    final inputCost = double.tryParse(_costController.text) ?? 0.0;
    if (!_isTotalCost) return inputCost;
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) return 0.0;
    return inputCost / quantity;
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final l10n = AppLocalizations.of(context)!; // Get localization

    return AlertDialog(
      title: Text(widget.item == null ? l10n.addItem : l10n.editItem),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.itemName),
                validator: (value) => value!.isEmpty ? l10n.enterName : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: l10n.quantity),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? l10n.enterQuantity : null,
                onChanged: (_) => setState(() {}), // Refresh calculated cost
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: InputDecoration(
                        labelText: _isTotalCost
                            ? l10n.totalCost
                            : l10n.costPerUnit,
                        prefixText: currency,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? l10n.enterCost : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Text(l10n.costType),
                      Switch(
                        value: _isTotalCost,
                        onChanged: (value) {
                          setState(() {
                            _isTotalCost = value;
                          });
                        },
                      ),
                      Text(
                        _isTotalCost ? l10n.total : l10n.costPerUnit,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              if (_isTotalCost &&
                  _costController.text.isNotEmpty &&
                  _quantityController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    l10n.calculatedUnitCost(
                      currency,
                      _calculateUnitCost().toStringAsFixed(2),
                    ),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _supplierController,
                decoration: InputDecoration(labelText: l10n.supplier),
                validator: (value) =>
                    value!.isEmpty ? l10n.enterSupplier : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _supplierContactController,
                decoration: InputDecoration(
                  labelText: l10n.supplierContact,
                  prefixIcon: const Icon(Icons.contact_phone_outlined),
                ),
                validator: (value) =>
                    value!.isEmpty ? l10n.enterSupplierContact : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _thresholdController,
                      decoration: InputDecoration(labelText: l10n.expiresDays),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lowStockController,
                      decoration: InputDecoration(
                        labelText: l10n.lowStockLevel,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(l10n.expirationDate),
                subtitle: Text(
                  '${_expirationDate.year}-${_expirationDate.month}-${_expirationDate.day}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expirationDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) {
                    setState(() {
                      _expirationDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final item = InventoryItem(
                id: widget.item?.id,
                name: _nameController.text,
                quantity: int.parse(_quantityController.text),
                cost: _calculateUnitCost(), // Use logic to set unit cost
                supplier: _supplierController.text,
                supplierContact: _supplierContactController.text,
                expirationDate: _expirationDate,
                thresholdDays: int.parse(_thresholdController.text),
                lowStockThreshold: int.parse(_lowStockController.text),
              );
              widget.onSave(item);
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
