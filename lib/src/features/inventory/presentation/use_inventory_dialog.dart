import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:flutter/material.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

class UseInventoryItemDialog extends StatefulWidget {
  final InventoryItem item;
  final Function(int) onUse;

  const UseInventoryItemDialog({
    super.key,
    required this.item,
    required this.onUse,
  });

  @override
  State<UseInventoryItemDialog> createState() => _UseInventoryItemDialogState();
}

class _UseInventoryItemDialogState extends State<UseInventoryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  int _useQuantity = 1;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.useItemTitle(widget.item.name)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.currentStock(widget.item.quantity),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: l10n.quantityToUse,
                suffixText: l10n.unitsSuffix,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterQuantity;
                }
                final quantity = int.tryParse(value);
                if (quantity == null || quantity <= 0) {
                  return l10n.enterValidPositiveNumber;
                }
                if (quantity > widget.item.quantity) {
                  return l10n.cannotUseMoreThanStock;
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _useQuantity = int.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              l10n.remainingStock(widget.item.quantity - _useQuantity),
              style: TextStyle(
                color:
                    (widget.item.quantity - _useQuantity) <
                        widget.item.lowStockThreshold
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
              widget.onUse(int.parse(_quantityController.text));
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n.confirmUse),
        ),
      ],
    );
  }
}
