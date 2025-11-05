import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/finance/presentation/finance_chart.dart';
import 'package:dentaltid/src/core/currency_provider.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  TransactionType _selectedType = TransactionType.income;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  @override
  void dispose() {
    _descriptionController.dispose();
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final transactionsAsyncValue = ref.watch(transactionsProvider);
    final financeService = ref.watch(financeServiceProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Add Transaction'),
              Tab(text: 'Financial Summary'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Add Transaction Tab
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _totalAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Total Amount',
                              ),
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
                              controller: _paidAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Paid Amount',
                              ),
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
                              initialValue: _selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Type',
                              ),
                              onChanged: (TransactionType? newValue) {
                                setState(() {
                                  _selectedType = newValue!;
                                });
                              },
                              items: TransactionType.values
                                  .map<DropdownMenuItem<TransactionType>>((
                                    TransactionType value,
                                  ) {
                                    return DropdownMenuItem<TransactionType>(
                                      value: value,
                                      child: Text(
                                        value.toString().split('.').last,
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                            DropdownButtonFormField<PaymentMethod>(
                              initialValue: _selectedPaymentMethod,
                              decoration: const InputDecoration(
                                labelText: 'Payment Method',
                              ),
                              onChanged: (PaymentMethod? newValue) {
                                setState(() {
                                  _selectedPaymentMethod = newValue!;
                                });
                              },
                              items: PaymentMethod.values
                                  .map<DropdownMenuItem<PaymentMethod>>((
                                    PaymentMethod value,
                                  ) {
                                    return DropdownMenuItem<PaymentMethod>(
                                      value: value,
                                      child: Text(
                                        value.toString().split('.').last,
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          final totalAmount = double.parse(
                            _totalAmountController.text,
                          );
                          final paidAmount = double.parse(
                            _paidAmountController.text,
                          );
                          final status = paidAmount >= totalAmount
                              ? TransactionStatus.paid
                              : TransactionStatus.unpaid;

                          final newTransaction = Transaction(
                            description: _descriptionController.text,
                            totalAmount: totalAmount,
                            paidAmount: paidAmount,
                            type: _selectedType,
                            date: DateTime.now(),
                            status: status,
                            paymentMethod: _selectedPaymentMethod,
                          );
                          await financeService.addTransaction(newTransaction);
                          ref.invalidate(transactionsProvider);
                          _descriptionController.clear();
                          _totalAmountController.clear();
                          _paidAmountController.clear();
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
                    child: const Text('Add Transaction'),
                  ),
                ),
              ],
            ),

            // Financial Summary Tab
            transactionsAsyncValue.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(child: Text('No transactions yet.'));
                }
                double totalPaid = 0;
                double totalUnpaid = 0;
                for (var t in transactions) {
                  totalPaid += t.paidAmount;
                  totalUnpaid += (t.totalAmount - t.paidAmount);
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: FinanceChart(transactions: transactions),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'Paid: $currency${totalPaid.toStringAsFixed(2)}',
                          ),
                          Text(
                            'Unpaid: $currency${totalUnpaid.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text(transaction.description),
                              subtitle: Text(
                                'Total: $currency${transaction.totalAmount} - Paid: $currency${transaction.paidAmount} - Outstanding: $currency${transaction.totalAmount - transaction.paidAmount}\nMethod: ${transaction.paymentMethod.toString().split('.').last}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$currency${transaction.totalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color:
                                          transaction.type ==
                                              TransactionType.income
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    transaction.status
                                        .toString()
                                        .split('.')
                                        .last,
                                    style: TextStyle(
                                      color:
                                          transaction.status ==
                                              TransactionStatus.paid
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ],
        ),
      ),
    );
  }
}
