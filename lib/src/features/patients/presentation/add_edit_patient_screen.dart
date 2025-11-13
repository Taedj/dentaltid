import 'package:dentaltid/src/core/exceptions.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final descriptionController = TextEditingController();
    final totalAmountController = TextEditingController();
    final paidAmountController = TextEditingController();
    TransactionType selectedType = TransactionType.income;
    PaymentMethod selectedPaymentMethod = PaymentMethod.cash;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.addTransaction),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: l10n.description),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterDescription;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: totalAmountController,
                  decoration: InputDecoration(labelText: l10n.totalAmount),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterTotalAmount;
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return l10n.enterValidPositiveAmount;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: paidAmountController,
                  decoration: InputDecoration(labelText: l10n.paidAmount),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterPaidAmount;
                    }
                    final paidAmount = double.tryParse(value);
                    if (paidAmount == null || paidAmount < 0) {
                      return l10n.enterValidNonNegativeAmount;
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<TransactionType>(
                  initialValue: selectedType,
                  decoration: InputDecoration(labelText: l10n.type),
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
                  decoration: InputDecoration(labelText: l10n.paymentMethod),
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
              child: Text(l10n.cancel),
              onPressed: () {
                descriptionController.dispose();
                totalAmountController.dispose();
                paidAmountController.dispose();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(l10n.add),
              onPressed: () async {
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
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.receipt),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${l10n.description}: ${transaction.description}'),
                Text('${l10n.total}: \$${transaction.totalAmount}'),
                Text('${l10n.paid}: \$${transaction.paidAmount}'),
                Text(
                  '${l10n.outstandingAmount}: \$${transaction.totalAmount - transaction.paidAmount}',
                ),
                Text(
                  '${l10n.type}: ${transaction.type.toString().split('.').last}',
                ),
                Text(
                  '${l10n.date}: ${transaction.date.toLocal().toString().split(' ')[0]}',
                ),
                Text(
                  '${l10n.paid}: ${transaction.status.toString().split('.').last}',
                ),
                Text(
                  '${l10n.method}: ${transaction.paymentMethod.toString().split('.').last}',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.close),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patient == null ? l10n.addPatient : l10n.editPatient,
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
                  controller: _familyNameController,
                  decoration: InputDecoration(labelText: l10n.familyName),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterFamilyName;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: l10n.age),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterAge;
                    }
                    final age = int.tryParse(value);
                    if (age == null) {
                      return l10n.enterValidNumber;
                    }
                    if (age < 0 || age > 150) {
                      return l10n.enterAgeBetween;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _healthStateController,
                  decoration: InputDecoration(labelText: l10n.healthState),
                ),
                TextFormField(
                  controller: _diagnosisController,
                  decoration: InputDecoration(labelText: l10n.diagnosis),
                ),
                TextFormField(
                  controller: _treatmentController,
                  decoration: InputDecoration(labelText: l10n.treatment),
                ),
                TextFormField(
                  controller: _paymentController,
                  decoration: InputDecoration(labelText: l10n.payment),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterPaymentAmount;
                    }
                    final payment = double.tryParse(value);
                    if (payment == null) {
                      return l10n.enterValidNumber;
                    }
                    if (payment < 0) {
                      return l10n.paymentCannotBeNegative;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(labelText: l10n.phoneNumber),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Phone number is optional
                    }
                    // Regex for phone number validation (e.g., +1234567890, 123-456-7890, etc.)
                    // This regex allows for an optional '+' at the beginning, followed by 7 to 15 digits.
                    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
                    if (!phoneRegex.hasMatch(value)) {
                      return l10n.enterValidPhoneNumber;
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
                        Text(
                          l10n.emergencyDetails,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          title: Text(l10n.isEmergency),
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
                            decoration: InputDecoration(
                              labelText: l10n.severity,
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
                            decoration: InputDecoration(
                              labelText: l10n.healthAlerts,
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
                            ref.invalidate(
                              patientsProvider(PatientFilter.today),
                            );
                            ref.invalidate(
                              patientsProvider(PatientFilter.emergency),
                            );
                          } else {
                            await patientService.updatePatient(newPatient);
                            ref.invalidate(patientsProvider(PatientFilter.all));
                            ref.invalidate(
                              patientsProvider(PatientFilter.today),
                            );
                            ref.invalidate(
                              patientsProvider(PatientFilter.emergency),
                            );
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final errorMessage =
                                ErrorHandler.getUserFriendlyMessage(e);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                                action: SnackBarAction(
                                  label: 'OK',
                                  onPressed: () {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar();
                                  },
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Text(
                      widget.patient == null ? l10n.add : l10n.update,
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
    final l10n = AppLocalizations.of(context)!;

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
                Text(
                  l10n.paymentHistory,
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
                  return Text(l10n.noPaymentHistory);
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
