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

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  // State for filters
  bool _includeRecurringCharges = true;
  bool _includeInventoryExpenses = true;
  bool _includeStaffSalaries = true;
  bool _includeRent = true;
  late DateTimeRange _selectedDateRange;
  String _selectedFilterKey = 'month'; // 'today', 'week', 'month', 'year', 'global', 'custom'

  @override
  void initState() {
    super.initState();
    // Initialize with 'This Month' logic directly
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
    // Generate for a reasonable window around "now" to ensure data exists
    final periodStart = DateTime(now.year, now.month - 12, now.day);
    final periodEnd = DateTime(now.year, now.month + 12, 0);
    await recurringChargeService.generateTransactionsForRecurringCharges(
      periodStart,
      periodEnd,
    );
    // Optional: Refresh if needed, but usually the stream updates automatically
    // ref.invalidate(financeServiceProvider);
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
        // Find the last Monday (or Sunday depending on locale, using Monday here)
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
        start = DateTime(2000); // Far past
        end = DateTime(2100); // Far future
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

  @override
  Widget build(BuildContext context) {
    final filters = FinanceFilters(
      dateRange: _selectedDateRange,
      includeRecurringCharges: _includeRecurringCharges,
      includeInventoryExpenses: _includeInventoryExpenses,
      includeStaffSalaries: _includeStaffSalaries,
      includeRent: _includeRent,
    );
    final transactionsAsyncValue = ref.watch(
      filteredTransactionsProvider(filters),
    );
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final financeSettings = ref.watch(financeSettingsProvider);
    final monthlyBudget = financeSettings.monthlyBudgetCap;
    final currentLocale = ref.watch(languageProvider);
    // Removed currentLocale from here

    // Budget Alert Logic

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.finance),
        actions: [
          IconButton(
            icon: const Icon(Icons.credit_card),
            onPressed: () => context.go('/finance/recurring-charges'),
            tooltip: l10n.recurringChargesTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
            tooltip: l10n.financeSettingsTooltip,
          ),
        ],
      ),
      body: transactionsAsyncValue.when(
        data: (transactions) {
          // Calculate Summaries
          double totalIncome = 0;
          double totalExpense = 0;
          for (var t in transactions) {
            if (t.type == TransactionType.income) {
              totalIncome += t.totalAmount;
            } else {
              totalExpense += t.totalAmount;
            }
          }
          double netProfit = totalIncome - totalExpense;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              // 1. Duration Selectors (Chips)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var entry in {
                      'today': l10n.periodToday,
                      'week': l10n.periodThisWeek,
                      'month': l10n.periodThisMonth,
                      'year': l10n.periodThisYear,
                      'global': l10n.periodGlobal,
                    }.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: _selectedFilterKey == entry.key,
                          onSelected: (selected) {
                            if (selected) _setDuration(entry.key);
                          },
                        ),
                      ),
                    ActionChip(
                      label: Text(
                        _selectedFilterKey == 'custom'
                            ? '${DateFormat.MMMd().format(_selectedDateRange.start)} - ${DateFormat.MMMd().format(_selectedDateRange.end)}'
                            : l10n.periodCustomDate,
                      ),
                      avatar: const Icon(Icons.calendar_today, size: 16),
                      onPressed: _showDateRangePicker,
                      backgroundColor: _selectedFilterKey == 'custom'
                          ? theme.colorScheme.secondaryContainer
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. KPI Cards (Overview)
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      l10n.incomeTitle,
                      totalIncome,
                      Colors.green,
                      currency,
                      currentLocale,
                      useCompactNumbers: financeSettings.useCompactNumbers,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      l10n.expensesTitle,
                      totalExpense,
                      Colors.red,
                      currency,
                      currentLocale,
                      useCompactNumbers: financeSettings.useCompactNumbers,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      l10n.netProfitTitle,
                      netProfit,
                      netProfit >= 0
                          ? theme.colorScheme.primary
                          : Colors.orange,
                      currency,
                      currentLocale,
                      isBold: true,
                      useCompactNumbers: financeSettings.useCompactNumbers,
                      subtitle: financeSettings.taxRatePercentage > 0
                          ? '${l10n.taxLabel}: ${financeSettings.taxRatePercentage}% (${_formatCurrency(netProfit * (financeSettings.taxRatePercentage / 100), currency, currentLocale, useCompact: financeSettings.useCompactNumbers)})'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2.5 Budget Progress (If Enabled)
              if (monthlyBudget != null && monthlyBudget > 0) ...[
                _buildBudgetCard(
                  context,
                  totalExpense,
                  monthlyBudget,
                  currency,
                  currentLocale,
                  useCompactNumbers: financeSettings.useCompactNumbers,
                ),
                const SizedBox(height: 24),
              ],

              // 3. New Advanced Charts
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FinanceChart(transactions: transactions),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Detailed Transaction List
              Text(l10n.transactions, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              if (transactions.isEmpty)
                Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(l10n.noTransactionsFound),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final isIncome = transaction.type == TransactionType.income;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isIncome ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          transaction.description,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${DateFormat.yMMMd().format(transaction.date.toLocal())} • ${transaction.category}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Text(
                          '${isIncome ? '+' : '-'}${_formatCurrency(transaction.totalAmount, currency, currentLocale, useCompact: false)}',
                          style: TextStyle(
                            color: isIncome ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/finance/add-transaction'),
        label: Text(l10n.addTransaction),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
    String currency,
    Locale locale, {
    bool isBold = false,
    String? subtitle,
    bool useCompactNumbers = true,
  }) {
    final theme = Theme.of(context);
    final formattedAmount = _formatCurrency(
      amount,
      currency,
      locale,
      useCompact: useCompactNumbers,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formattedAmount,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    double currentExpense,
    double budgetCap,
    String currency,
    Locale locale, {
    bool useCompactNumbers = true,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final percent = (currentExpense / budgetCap).clamp(0.0, 1.0);
    final isOverBudget = currentExpense > budgetCap;

    final formattedExpense = _formatCurrency(
      currentExpense,
      currency,
      locale,
      useCompact: useCompactNumbers,
    );
    final formattedBudget = _formatCurrency(
      budgetCap,
      currency,
      locale,
      useCompact: useCompactNumbers,
    );

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.monthlyBudgetTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$formattedExpense / $formattedBudget',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isOverBudget
                        ? Colors.red
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent,
              borderRadius: BorderRadius.circular(8),
              minHeight: 12,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: isOverBudget
                  ? Colors.red
                  : (percent > 0.8 ? Colors.orange : Colors.green),
            ),
            if (isOverBudget)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.budgetExceededAlert,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(
    double amount,
    String currency,
    Locale locale, {
    bool useCompact = true,
  }) {
    final formatter = useCompact
        ? NumberFormat.compact(locale: locale.languageCode)
        : NumberFormat.decimalPattern(locale.languageCode);

    final formattedNumber = formatter.format(amount);

    if (locale.languageCode == 'ar') {
      return '$currency $formattedNumber'; // Left for AR
    } else {
      return '$formattedNumber $currency'; // Right for EN/FR
    }
  }
}
