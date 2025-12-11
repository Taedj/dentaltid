import 'package:dentaltid/src/features/finance/application/recurring_charge_service.dart';
import 'package:dentaltid/src/features/finance/domain/recurring_charge.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/features/finance/presentation/recurring_charges_screen.dart'; // Add this import here

class AddEditRecurringChargeScreen extends ConsumerStatefulWidget {
  const AddEditRecurringChargeScreen({super.key, this.recurringCharge});

  final RecurringCharge? recurringCharge;

  @override
  ConsumerState<AddEditRecurringChargeScreen> createState() =>
      _AddEditRecurringChargeScreenState();
}

class _AddEditRecurringChargeScreenState
    extends ConsumerState<AddEditRecurringChargeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late RecurringChargeFrequency _selectedFrequency;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  late bool _isActive;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.recurringCharge?.name ?? '',
    );
    _amountController = TextEditingController(
      text: widget.recurringCharge?.amount.toString() ?? '',
    );
    _selectedFrequency =
        widget.recurringCharge?.frequency ?? RecurringChargeFrequency.monthly;
    _startDateController = TextEditingController(
      text:
          widget.recurringCharge?.startDate.toIso8601String().split('T')[0] ??
          '',
    );
    _endDateController = TextEditingController(
      text:
          widget.recurringCharge?.endDate?.toIso8601String().split('T')[0] ??
          '',
    );
    _isActive = widget.recurringCharge?.isActive ?? true;
    _descriptionController = TextEditingController(
      text: widget.recurringCharge?.description ?? '',
    );

    if (widget.recurringCharge != null) {
      // Logic for loading patient if needed is removed
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateTime.parse(controller.text)
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _saveRecurringCharge() async {
    if (!_formKey.currentState!.validate()) return;

    final recurringChargeService = ref.read(recurringChargeServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    try {
      final newCharge = RecurringCharge(
        id: widget.recurringCharge?.id,
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        frequency: _selectedFrequency,
        startDate: DateTime.parse(_startDateController.text),
        endDate: _endDateController.text.isNotEmpty
            ? DateTime.parse(_endDateController.text)
            : null,

        isActive: _isActive,
        description: _descriptionController.text,
      );

      if (widget.recurringCharge == null) {
        await recurringChargeService.addRecurringCharge(newCharge);
      } else {
        await recurringChargeService.updateRecurringCharge(newCharge);
      }
      ref.invalidate(recurringChargesProvider); // Invalidate the provider
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorSavingRecurringCharge}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    //     final patientsAsyncValue = ref.watch(patientsProvider(PatientFilter.all));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recurringCharge == null
              ? l10n.addRecurringCharge
              : l10n.editRecurringCharge,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.name),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterName;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: l10n.amount),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterValidPositiveAmount;
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return l10n.enterValidPositiveAmount;
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<RecurringChargeFrequency>(
                  initialValue: _selectedFrequency,
                  decoration: InputDecoration(labelText: l10n.frequency),
                  items: RecurringChargeFrequency.values.map((frequency) {
                    return DropdownMenuItem(
                      value: frequency,
                      child: Text(_getLocalizedFrequency(frequency, l10n)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFrequency = value;
                      });
                    }
                  },
                ),
                TextFormField(
                  controller: _startDateController,
                  decoration: InputDecoration(
                    labelText: l10n.startDate,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () =>
                          _selectDate(context, _startDateController),
                    ),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterDate;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _endDateController,
                  decoration: InputDecoration(
                    labelText: l10n.endDate,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context, _endDateController),
                    ),
                  ),
                  readOnly: true,
                ),

                CheckboxListTile(
                  title: Text(l10n.isActive),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? false;
                    });
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: l10n.description),
                  maxLines: 3,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: _saveRecurringCharge,
                    child: Text(
                      widget.recurringCharge == null ? l10n.add : l10n.update,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  String _getLocalizedFrequency(
      RecurringChargeFrequency frequency, AppLocalizations l10n) {
    switch (frequency) {
      case RecurringChargeFrequency.daily:
        return l10n.freqDaily;
      case RecurringChargeFrequency.weekly:
        return l10n.freqWeekly;
      case RecurringChargeFrequency.monthly:
        return l10n.freqMonthly;
      case RecurringChargeFrequency.quarterly:
        return l10n.freqQuarterly;
      case RecurringChargeFrequency.yearly:
        return l10n.freqYearly;
      case RecurringChargeFrequency.custom:
        return l10n.freqCustom;
    }
  }
}
