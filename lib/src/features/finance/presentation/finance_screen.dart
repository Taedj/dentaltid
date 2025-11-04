import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/finance/presentation/finance_chart.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _selectedType = TransactionType.income;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                              decoration: const InputDecoration(labelText: 'Description'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _amountController,
                              decoration: const InputDecoration(labelText: 'Amount'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an amount';
                                }
                                return null;
                              },
                            ),
                            DropdownButton<TransactionType>(
                              value: _selectedType,
                              onChanged: (TransactionType? newValue) {
                                setState(() {
                                  _selectedType = newValue!;
                                });
                              },
                              items: TransactionType.values
                                  .map<DropdownMenuItem<TransactionType>>((TransactionType value) {
                                return DropdownMenuItem<TransactionType>(
                                  value: value,
                                  child: Text(value.toString().split('.').last),
                                );
                              }).toList(),
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
                        final newTransaction = Transaction(
                          description: _descriptionController.text,
                          amount: double.parse(_amountController.text),
                          type: _selectedType,
                          date: DateTime.now(),
                        );
                        await financeService.addTransaction(newTransaction);
                        ref.invalidate(financeServiceProvider);
                        _descriptionController.clear();
                        _amountController.clear();
                      }
                    },
                    child: const Text('Add Transaction'),
                  ),
                ),
              ],
            ),

            // Financial Summary Tab
            FutureBuilder(
              future: financeService.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No transactions yet.'));
                } else {
                  final transactions = snapshot.data!;
                  double totalIncome = 0;
                  double totalExpense = 0;
                  for (var t in transactions) {
                    if (t.type == TransactionType.income) {
                      totalIncome += t.amount;
                    } else {
                      totalExpense += t.amount;
                    }
                  }
                  final balance = totalIncome - totalExpense;

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
                            Text('Income: \$${totalIncome.toStringAsFixed(2)}'),
                            Text('Expense: \$${totalExpense.toStringAsFixed(2)}'),
                            Text('Balance: \$${balance.toStringAsFixed(2)}'),
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
                                    'Date: ${transaction.date.toLocal().toString().split(' ')[0]}'),
                                trailing: Text(
                                  '\$${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: transaction.type == TransactionType.income
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
