import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:dentaltid/src/core/language_provider.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:dentaltid/src/features/finance/presentation/finance_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/features/finance/application/recurring_charge_service.dart';
import 'package:dentaltid/src/features/finance/domain/finance_filters.dart';
import 'package:dentaltid/src/features/settings/application/finance_settings_provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dentaltid/src/core/app_colors.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  final bool _includeRecurringCharges = true;
  final bool _includeInventoryExpenses = true;
  final bool _includeStaffSalaries = true;
  final bool _includeRent = true;
  late DateTimeRange _selectedDateRange;
  String _selectedFilterKey = 'month';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateRecurringTransactions();
    });
  }

  Future<void> _generateRecurringTransactions() async {
    final recurringChargeService = ref.read(recurringChargeServiceProvider);
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month - 12, now.day);
    final periodEnd = DateTime(now.year, now.month + 12, 0);
    await recurringChargeService.generateTransactionsForRecurringCharges(periodStart, periodEnd);
  }

  void _setDuration(String key) {
    if (!mounted) return;
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (key) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'week':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'global':
        start = DateTime(2000);
        end = DateTime(2100);
        break;
      default:
        return;
    }

    setState(() {
      _selectedFilterKey = key;
      _selectedDateRange = DateTimeRange(start: start, end: end);
    });
  }

  void _showDateRangePicker() async {
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    if (newDateRange != null) {
      setState(() {
        _selectedFilterKey = 'custom';
        _selectedDateRange = newDateRange;
      });
    }
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTransaction),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && transaction.id != null) {
      final financeService = ref.read(financeServiceProvider);
      await financeService.deleteTransaction(transaction.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted successfully')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = FinanceFilters(
      dateRange: _selectedDateRange,
      includeRecurringCharges: _includeRecurringCharges,
      includeInventoryExpenses: _includeInventoryExpenses,
      includeStaffSalaries: _includeStaffSalaries,
      includeRent: _includeRent,
    );
    final transactionsAsyncValue = ref.watch(filteredTransactionsProvider(filters));
    final actualTransactionsAsyncValue = ref.watch(actualTransactionsProvider(filters));
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final financeSettings = ref.watch(financeSettingsProvider);
    final monthlyBudget = financeSettings.monthlyBudgetCap;
    final currentLocale = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.finance),
        actions: [
          IconButton(icon: const Icon(LucideIcons.repeat), onPressed: () => context.go('/finance/recurring-charges')),
          IconButton(icon: const Icon(LucideIcons.settings), onPressed: () => context.go('/settings')),
        ],
      ),
      body: transactionsAsyncValue.when(
        data: (transactions) {
          double totalIncome = 0;
          double totalExpense = 0;
          for (var t in transactions) {
            if (t.type == TransactionType.income) {
              totalIncome += t.paidAmount;
            } else {
              totalExpense += t.totalAmount;
            }
          }
          double netProfit = totalIncome - totalExpense;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Period Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var entry in {'today': l10n.periodToday, 'week': l10n.periodThisWeek, 'month': l10n.periodThisMonth, 'year': l10n.periodThisYear, 'global': l10n.periodGlobal}.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(entry.value),
                          selected: _selectedFilterKey == entry.key,
                          onSelected: (selected) { if (selected) _setDuration(entry.key); },
                          checkmarkColor: Colors.white,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: _selectedFilterKey == entry.key ? Colors.white : theme.textTheme.bodyMedium?.color),
                        ),
                      ),
                     ActionChip(
                      label: Text(_selectedFilterKey == 'custom' ? '${DateFormat.MMMd().format(_selectedDateRange.start)} - ${DateFormat.MMMd().format(_selectedDateRange.end)}' : l10n.periodCustomDate),
                      avatar: const Icon(LucideIcons.calendar, size: 16),
                      onPressed: _showDateRangePicker,
                      backgroundColor: _selectedFilterKey == 'custom' ? AppColors.primary.withValues(alpha: 0.2) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // KPI Cards
              Row(
                children: [
                  Expanded(child: _buildGlassKpiCard(l10n.incomeTitle, totalIncome, AppColors.success, currency, currentLocale, LucideIcons.trendingUp, financeSettings.useCompactNumbers)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildGlassKpiCard(l10n.expensesTitle, totalExpense, AppColors.error, currency, currentLocale, LucideIcons.trendingDown, financeSettings.useCompactNumbers)),
                ],
              ),
              const SizedBox(height: 12),
              _buildGlassKpiCard(
                  l10n.netProfitTitle, netProfit, netProfit >= 0 ? AppColors.primary : AppColors.warning, currency, currentLocale, LucideIcons.wallet, financeSettings.useCompactNumbers,
                  subtitle: financeSettings.taxRatePercentage > 0 ? '${l10n.taxLabel}: ${financeSettings.taxRatePercentage}%' : null
              ),
              
              const SizedBox(height: 24),

              if (monthlyBudget != null && monthlyBudget > 0) ...[
                _buildModernBudgetCard(totalExpense, monthlyBudget, currency, currentLocale, financeSettings.useCompactNumbers, l10n),
                const SizedBox(height: 24),
              ],

              Card(
                elevation: 0,
                color: theme.cardTheme.color,
                child: Padding(padding: const EdgeInsets.all(16.0), child: FinanceChart(transactions: transactions)),
              ),
              const SizedBox(height: 24),

              Text(l10n.transactions, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              actualTransactionsAsyncValue.when(
                data: (actualTransactions) {
                  if (actualTransactions.isEmpty) return Center(child: Text(l10n.noTransactionsFound, style: const TextStyle(color: Colors.grey)));
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: actualTransactions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final transaction = actualTransactions[index];
                      final isIncome = transaction.type == TransactionType.income;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (isIncome ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                          child: Icon(isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight, color: isIncome ? AppColors.success : AppColors.error, size: 20),
                        ),
                        title: Text(transaction.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${DateFormat.yMMMd().format(transaction.date)} • ${transaction.category}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isIncome ? '+' : '-'}${_formatCurrency(transaction.totalAmount, currency, currentLocale, useCompact: false)}',
                              style: TextStyle(color: isIncome ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(LucideIcons.moreVertical, size: 18),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  context.go('/finance/edit-transaction', extra: transaction);
                                } else if (value == 'delete') {
                                  _deleteTransaction(transaction);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'edit', child: Row(children: [const Icon(LucideIcons.edit, size: 18), const SizedBox(width: 8), Text(l10n.edit)])),
                                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(LucideIcons.trash2, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.delete, style: const TextStyle(color: Colors.red))])),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => context.go('/finance/add-transaction'),
        label: Text(l10n.addTransaction, style: const TextStyle(color: Colors.white)),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildGlassKpiCard(String title, double amount, Color color, String currency, Locale locale, IconData icon, bool useCompact, {String? subtitle}) {
    final formattedAmount = _formatCurrency(amount, currency, locale, useCompact: useCompact);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(formattedAmount, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)],
        ],
      ),
    );
  }

  Widget _buildModernBudgetCard(double current, double max, String currency, Locale locale, bool useCompact, AppLocalizations l10n) {
     final percent = (current / max).clamp(0.0, 1.0);
     final isOver = current > max;
     
     return Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         gradient: LinearGradient(colors: [AppColors.darkCard.withValues(alpha: 0.05), AppColors.darkCard.withValues(alpha: 0.1)]),
         borderRadius: BorderRadius.circular(16),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(l10n.monthlyBudgetTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
               Text('${(percent * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: isOver ? AppColors.error : AppColors.primary)),
             ],
           ),
           const SizedBox(height: 12),
           LinearProgressIndicator(
             value: percent, 
             backgroundColor: Colors.grey.withValues(alpha: 0.2), 
             color: isOver ? AppColors.error : AppColors.success,
             minHeight: 8,
             borderRadius: BorderRadius.circular(4),
           ),
           const SizedBox(height: 8),
           Text(
             '${_formatCurrency(current, currency, locale, useCompact: useCompact)} / ${_formatCurrency(max, currency, locale, useCompact: useCompact)}',
             style: const TextStyle(fontSize: 12, color: Colors.grey),
           ),
         ],
       ),
     );
  }

  String _formatCurrency(double amount, String currency, Locale locale, {bool useCompact = true}) {
    final formatter = useCompact ? NumberFormat.compact(locale: locale.languageCode) : NumberFormat.decimalPattern(locale.languageCode);
    final formatted = formatter.format(amount);
    return locale.languageCode == 'ar' ? '$currency $formatted' : '$formatted $currency';
  }
}