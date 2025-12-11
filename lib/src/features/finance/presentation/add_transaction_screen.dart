import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  String _selectedCategory = 'Other';

  final List<String> _expenseCategories = [
    'Rent',
    'Salaries',
    'Inventory',
    'Equipment',
    'Marketing',
    'Utilities',
    'Maintenance',
    'Taxes',
    'Other',
  ];

  final List<String> _incomeCategories = [
    'Consultation',
    'Procedure',
    'Product Sales',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final financeService = ref.read(financeServiceProvider);
      final l10n = AppLocalizations.of(context)!;

      try {
        final amount = double.parse(_amountController.text);
        final transaction = Transaction(
          description: _descriptionController.text.isEmpty
              ? _selectedCategory
              : _descriptionController.text,
          totalAmount: amount,
          paidAmount: amount, // Assume fully paid for manual entry
          type: _type,
          date: _date,
          sourceType: TransactionSourceType.other, // Manual entry
          category: _selectedCategory,
          status: TransactionStatus.paid,
        );

        await financeService.addTransaction(transaction);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.transactionAddedSuccess)),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = _type == TransactionType.expense
        ? _expenseCategories
        : _incomeCategories;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addTransaction)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Selection
              SegmentedButton<TransactionType>(
                segments: [
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text(l10n.incomeType),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text(l10n.expenseType),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                    _selectedCategory = _type == TransactionType.expense
                        ? _expenseCategories.first
                        : _incomeCategories.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return _type == TransactionType.income
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2);
                    }
                    return Colors.transparent;
                  }),
                  side: WidgetStateProperty.all(
                    BorderSide(
                      color: _type == TransactionType.income
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.dateLabel,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat.yMMMd().format(_date)),
                ),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: l10n.categoryLabel,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(_getLocalizedCategory(category, l10n)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterAmount;
                  }
                  if (double.tryParse(value) == null) {
                    return l10n.invalidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.description,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _saveTransaction,
                  icon: const Icon(Icons.save),
                  label: Text(l10n.save),
                  style: FilledButton.styleFrom(
                    backgroundColor: _type == TransactionType.income
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _getLocalizedCategory(String category, AppLocalizations l10n) {
    switch (category) {
      case 'Rent':
        return l10n.catRent;
      case 'Salaries':
        return l10n.catSalaries;
      case 'Inventory':
        return l10n.catInventory;
      case 'Equipment':
        return l10n.catEquipment;
      case 'Marketing':
        return l10n.catMarketing;
      case 'Utilities':
        return l10n.catUtilities;
      case 'Maintenance':
        return l10n.catMaintenance;
      case 'Taxes':
        return l10n.catTaxes;
      case 'Other':
        return l10n.catOther;
      case 'Consultation':
        return l10n.consultationType;
      case 'Procedure':
        return l10n.procedureType;
      case 'Product Sales':
        return l10n.catProductSales;
      default:
        return category;
    }
  }
}
