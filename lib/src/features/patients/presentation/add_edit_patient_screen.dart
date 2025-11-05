import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:dentaltid/src/core/currency_provider.dart';

class AddEditPatientScreen extends ConsumerStatefulWidget {
  const AddEditPatientScreen({super.key, this.patient});

  final Patient? patient;

  @override
  ConsumerState<AddEditPatientScreen> createState() =>
      _AddEditPatientScreenState();
}

class _AddEditPatientScreenState extends ConsumerState<AddEditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _familyNameController;
  late TextEditingController _ageController;
  late TextEditingController _healthStateController;
  late TextEditingController _diagnosisController;
  late TextEditingController _treatmentController;
  late TextEditingController _paymentController;
  late TextEditingController _phoneNumberController;
  late bool _isEmergency;
  late EmergencySeverity _severity;
  late TextEditingController _healthAlertsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient?.name ?? '');
    _familyNameController = TextEditingController(
      text: widget.patient?.familyName ?? '',
    );
    _ageController = TextEditingController(
      text: widget.patient?.age.toString() ?? '',
    );
    _healthStateController = TextEditingController(
      text: widget.patient?.healthState ?? '',
    );
    _diagnosisController = TextEditingController(
      text: widget.patient?.diagnosis ?? '',
    );
    _treatmentController = TextEditingController(
      text: widget.patient?.treatment ?? '',
    );
    _paymentController = TextEditingController(
      text: widget.patient?.payment.toString() ?? '',
    );
    _isEmergency = widget.patient?.isEmergency ?? false;
    _severity = widget.patient?.severity ?? EmergencySeverity.low;
    _healthAlertsController = TextEditingController(
      text: widget.patient?.healthAlerts ?? '',
    );
    _phoneNumberController = TextEditingController(
      text: widget.patient?.phoneNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _familyNameController.dispose();
    _ageController.dispose();
    _healthStateController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _paymentController.dispose();
    _healthAlertsController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _showAddTransactionDialog(
    BuildContext context,
    int patientId,
  ) async {
    final descriptionController = TextEditingController();
    final totalAmountController = TextEditingController();
    final paidAmountController = TextEditingController();
    TransactionType selectedType = TransactionType.income;
    PaymentMethod selectedPaymentMethod = PaymentMethod.cash;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: totalAmountController,
                  decoration: const InputDecoration(labelText: 'Total Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a total amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid positive amount';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: paidAmountController,
                  decoration: const InputDecoration(labelText: 'Paid Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a paid amount';
                    }
                    final paidAmount = double.tryParse(value);
                    if (paidAmount == null || paidAmount < 0) {
                      return 'Please enter a valid non-negative amount';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<TransactionType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: TransactionType.values.map((type) {
                    return DropdownMenuItem<TransactionType>(
                      value: type,
                      child: Text(type.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      selectedType = newValue;
                    }
                  },
                ),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: selectedPaymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                  ),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem<PaymentMethod>(
                      value: method,
                      child: Text(method.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      selectedPaymentMethod = newValue;
                    }
                  },
                ),
                // Removed TransactionStatus dropdown as it will be calculated
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                descriptionController.dispose();
                totalAmountController.dispose();
                paidAmountController.dispose();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                // TODO: Add validation and save logic
                final financeService = ref.read(financeServiceProvider);
                final totalAmount = double.parse(totalAmountController.text);
                final paidAmount = double.parse(paidAmountController.text);
                final status = paidAmount >= totalAmount
                    ? TransactionStatus.paid
                    : TransactionStatus.unpaid;

                final newTransaction = Transaction(
                  patientId: patientId,
                  description: descriptionController.text,
                  totalAmount: totalAmount,
                  paidAmount: paidAmount,
                  type: selectedType,
                  date: DateTime.now(),
                  status: status,
                  paymentMethod: selectedPaymentMethod,
                );
                await financeService.addTransaction(newTransaction);
                ref.invalidate(transactionsByPatientProvider(patientId));
                if (context.mounted) {
                  descriptionController.dispose();
                  totalAmountController.dispose();
                  paidAmountController.dispose();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showReceiptDialog(
    BuildContext context,
    Transaction transaction,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Receipt'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Description: ${transaction.description}'),
                Text('Total Amount: \${transaction.totalAmount}'),
                Text('Paid Amount: \${transaction.paidAmount}'),
                Text(
                  'Outstanding Amount: \${transaction.totalAmount - transaction.paidAmount}',
                ),
                Text('Type: ${transaction.type.toString().split('.').last}'),
                Text(
                  'Date: ${transaction.date.toLocal().toString().split(' ')[0]}',
                ),
                Text(
                  'Status: ${transaction.status.toString().split('.').last}',
                ),
                Text(
                  'Payment Method: ${transaction.paymentMethod.toString().split('.').last}',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientService = ref.watch(patientServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient == null ? 'Add Patient' : 'Edit Patient'),
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
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _familyNameController,
                  decoration: const InputDecoration(labelText: 'Family Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a family name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an age';
                    }
                    final age = int.tryParse(value);
                    if (age == null) {
                      return 'Please enter a valid number';
                    }
                    if (age < 0 || age > 150) {
                      return 'Please enter an age between 0 and 150';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _healthStateController,
                  decoration: const InputDecoration(labelText: 'Health State'),
                ),
                TextFormField(
                  controller: _diagnosisController,
                  decoration: const InputDecoration(labelText: 'Diagnosis'),
                ),
                TextFormField(
                  controller: _treatmentController,
                  decoration: const InputDecoration(labelText: 'Treatment'),
                ),
                TextFormField(
                  controller: _paymentController,
                  decoration: const InputDecoration(labelText: 'Payment'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a payment amount';
                    }
                    final payment = double.tryParse(value);
                    if (payment == null) {
                      return 'Please enter a valid number';
                    }
                    if (payment < 0) {
                      return 'Payment amount cannot be negative';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Phone number is optional
                    }
                    // Regex for phone number validation (e.g., +1234567890, 123-456-7890, etc.)
                    // This regex allows for an optional '+' at the beginning, followed by 7 to 15 digits.
                    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
                    if (!phoneRegex.hasMatch(value)) {
                      return 'Please enter a valid phone number (7-15 digits)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.red.withAlpha((255 * 0.8).round()),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emergency Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          title: const Text('Is Emergency'),
                          value: _isEmergency,
                          onChanged: (bool? value) {
                            setState(() {
                              _isEmergency = value ?? false;
                            });
                          },
                        ),
                        if (_isEmergency) ...[
                          DropdownButtonFormField<EmergencySeverity>(
                            initialValue: _severity,
                            decoration: const InputDecoration(
                              labelText: 'Severity',
                            ),
                            items: EmergencySeverity.values.map((
                              EmergencySeverity severity,
                            ) {
                              return DropdownMenuItem<EmergencySeverity>(
                                value: severity,
                                child: Text(
                                  severity.toString().split('.').last,
                                ),
                              );
                            }).toList(),
                            onChanged: (EmergencySeverity? newValue) {
                              setState(() {
                                _severity = newValue!;
                              });
                            },
                          ),
                          TextFormField(
                            controller: _healthAlertsController,
                            decoration: const InputDecoration(
                              labelText: 'Health Alerts',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (widget.patient != null) ...[
                  const SizedBox(height: 20),
                  _PatientPaymentHistory(
                    patientId: widget.patient!.id!,
                    onAddTransaction: _showAddTransactionDialog,
                    onShowReceipt: _showReceiptDialog,
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          final newPatient = Patient(
                            id: widget.patient?.id,
                            name: _nameController.text,
                            familyName: _familyNameController.text,
                            age: int.tryParse(_ageController.text) ?? 0,
                            healthState: _healthStateController.text,
                            diagnosis: _diagnosisController.text,
                            treatment: _treatmentController.text,
                            payment:
                                double.tryParse(_paymentController.text) ?? 0.0,
                            createdAt:
                                widget.patient?.createdAt ?? DateTime.now(),
                            isEmergency: _isEmergency,
                            severity: _severity,
                            healthAlerts: _healthAlertsController.text,
                            phoneNumber: _phoneNumberController.text,
                          );

                          if (widget.patient == null) {
                            await patientService.addPatient(newPatient);
                            ref.invalidate(patientsProvider(PatientFilter.all));
                          } else {
                            await patientService.updatePatient(newPatient);
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
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
                    child: Text(widget.patient == null ? 'Add' : 'Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientPaymentHistory extends ConsumerWidget {
  final int patientId;
  final Function(BuildContext, int) onAddTransaction;
  final Function(BuildContext, Transaction) onShowReceipt;

  const _PatientPaymentHistory({
    required this.patientId,
    required this.onAddTransaction,
    required this.onShowReceipt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final transactionsAsyncValue = ref.watch(
      transactionsByPatientProvider(patientId),
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    onAddTransaction(context, patientId);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            transactionsAsyncValue.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Text('No payment history for this patient.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return ListTile(
                      leading: transaction.totalAmount > transaction.paidAmount
                          ? const Icon(Icons.warning, color: Colors.orange)
                          : null,
                      title: Text(transaction.description),
                      subtitle: Text(
                        'Total: $currency${transaction.totalAmount} - Paid: $currency${transaction.paidAmount} - Outstanding: $currency${transaction.totalAmount - transaction.paidAmount}\nMethod: ${transaction.paymentMethod.toString().split('.').last}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.receipt),
                            onPressed: () {
                              onShowReceipt(context, transaction);
                            },
                          ),
                          Text(transaction.status.toString().split('.').last),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: ${error.toString()}'),
            ),
          ],
        ),
      ),
    );
  }
}

final transactionsByPatientProvider =
    FutureProvider.family<List<Transaction>, int>(((ref, patientId) async {
      final service = ref.watch(financeServiceProvider);
      return service.getTransactionsByPatientId(patientId);
    }));
