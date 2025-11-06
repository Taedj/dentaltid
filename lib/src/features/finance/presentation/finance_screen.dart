import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/finance/presentation/finance_chart.dart';
import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

enum TransactionSortOption { dateDesc, dateAsc, amountDesc, amountAsc, type }

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
  TransactionSortOption _sortOption = TransactionSortOption.dateDesc;
  String _searchQuery = '';
  TransactionType? _filterType;

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
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.finance),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.addTransaction),
              Tab(text: l10n.financialSummary),
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
                              decoration: InputDecoration(
                                labelText: l10n.description,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.enterDescription;
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _totalAmountController,
                              decoration: InputDecoration(
                                labelText: l10n.totalAmount,
                              ),
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
                              controller: _paidAmountController,
                              decoration: InputDecoration(
                                labelText: l10n.paidAmount,
                              ),
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
                              initialValue: _selectedType,
                              decoration: InputDecoration(labelText: l10n.type),
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
                                        value == TransactionType.income
                                            ? l10n.income
                                            : l10n.expense,
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                            DropdownButtonFormField<PaymentMethod>(
                              initialValue: _selectedPaymentMethod,
                              decoration: InputDecoration(
                                labelText: l10n.paymentMethod,
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
                                        value == PaymentMethod.cash
                                            ? l10n.cash
                                            : value == PaymentMethod.card
                                            ? l10n.card
                                            : l10n.bankTransfer,
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
                                content: Text('${l10n.error}${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Text(l10n.addTransaction),
                  ),
                ),
              ],
            ),

            // Financial Summary Tab
            Column(
              children: [
                // Controls Row
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: l10n.searchTransactions,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<TransactionType?>(
                        icon: const Icon(Icons.filter_list),
                        onSelected: (TransactionType? type) {
                          setState(() {
                            _filterType = type;
                          });
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<TransactionType?>(
                            value: null,
                            child: Text(l10n.allTypes),
                          ),
                          ...TransactionType.values.map(
                            (type) => PopupMenuItem<TransactionType?>(
                              value: type,
                              child: Text(
                                type == TransactionType.income
                                    ? l10n.income
                                    : l10n.expense,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<TransactionSortOption>(
                        icon: const Icon(Icons.sort),
                        onSelected: (TransactionSortOption option) {
                          setState(() {
                            _sortOption = option;
                          });
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<TransactionSortOption>>[
                              PopupMenuItem<TransactionSortOption>(
                                value: TransactionSortOption.dateDesc,
                                child: Text(l10n.dateNewestFirst),
                              ),
                              PopupMenuItem<TransactionSortOption>(
                                value: TransactionSortOption.dateAsc,
                                child: Text(l10n.dateOldestFirst),
                              ),
                              PopupMenuItem<TransactionSortOption>(
                                value: TransactionSortOption.amountDesc,
                                child: Text(l10n.amountHighestFirst),
                              ),
                              PopupMenuItem<TransactionSortOption>(
                                value: TransactionSortOption.amountAsc,
                                child: Text(l10n.amountLowestFirst),
                              ),
                              PopupMenuItem<TransactionSortOption>(
                                value: TransactionSortOption.type,
                                child: Text(l10n.type),
                              ),
                            ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: transactionsAsyncValue.when(
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return Center(child: Text(l10n.noTransactionsYet));
                      }

                      // Filter transactions
                      var filteredTransactions = transactions.where((
                        transaction,
                      ) {
                        final matchesSearch =
                            _searchQuery.isEmpty ||
                            transaction.description.toLowerCase().contains(
                              _searchQuery,
                            ) ||
                            transaction.totalAmount.toString().contains(
                              _searchQuery,
                            );

                        final matchesFilter =
                            _filterType == null ||
                            transaction.type == _filterType;

                        return matchesSearch && matchesFilter;
                      }).toList();

                      // Sort transactions
                      filteredTransactions.sort((a, b) {
                        switch (_sortOption) {
                          case TransactionSortOption.dateDesc:
                            return b.date.compareTo(a.date);
                          case TransactionSortOption.dateAsc:
                            return a.date.compareTo(b.date);
                          case TransactionSortOption.amountDesc:
                            return b.totalAmount.compareTo(a.totalAmount);
                          case TransactionSortOption.amountAsc:
                            return a.totalAmount.compareTo(b.totalAmount);
                          case TransactionSortOption.type:
                            return a.type.toString().compareTo(
                              b.type.toString(),
                            );
                        }
                      });

                      double totalPaid = 0;
                      double totalUnpaid = 0;
                      for (var t in filteredTransactions) {
                        totalPaid += t.paidAmount;
                        totalUnpaid += (t.totalAmount - t.paidAmount);
                      }

                      return Column(
                        children: [
                          Expanded(
                            flex: 2,
                            child: FinanceChart(
                              transactions: filteredTransactions,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(
                                  '${l10n.paid} $currency${totalPaid.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  '${l10n.unpaid} $currency${totalUnpaid.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: ListView.builder(
                              itemCount: filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final transaction = filteredTransactions[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: Icon(
                                      transaction.type == TransactionType.income
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      color:
                                          transaction.type ==
                                              TransactionType.income
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    title: Text(
                                      transaction.description,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${l10n.date} ${transaction.date.toLocal().toString().split(' ')[0]}',
                                        ),
                                        Text(
                                          '${l10n.method} ${transaction.paymentMethod == PaymentMethod.cash
                                              ? l10n.cash
                                              : transaction.paymentMethod == PaymentMethod.card
                                              ? l10n.card
                                              : l10n.bankTransfer}',
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$currency${transaction.totalAmount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                transaction.type ==
                                                    TransactionType.income
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        Text(
                                          transaction.status
                                              .toString()
                                              .split('.')
                                              .last,
                                          style: TextStyle(
                                            fontSize: 12,
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
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
