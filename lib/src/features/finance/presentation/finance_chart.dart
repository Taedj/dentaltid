import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

class FinanceChart extends ConsumerStatefulWidget {
  final List<Transaction> transactions;

  const FinanceChart({super.key, required this.transactions});

  @override
  ConsumerState<FinanceChart> createState() => _FinanceChartState();
}

class _FinanceChartState extends ConsumerState<FinanceChart>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context);
    // Fallback if l10n fails (though it shouldn't in a properly set up app)
    // Actually, force unwrap is standard pattern here if we are sure.
    // However, if we are in a test or strange state, it might be null.
    // Let's assume ! is safe or handle it.  Typically ! is used.
    if (l10n == null) return const SizedBox.shrink();

    if (widget.transactions.isEmpty) {
      return Center(child: Text(l10n.noDataToDisplay));
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.profitTrend, icon: const Icon(Icons.show_chart)),
            Tab(text: l10n.expenseBreakdown, icon: const Icon(Icons.pie_chart)),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [
              _ProfitTrendChart(transactions: widget.transactions),
              _ExpenseBreakdownChart(transactions: widget.transactions),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfitTrendChart extends ConsumerWidget {
  final List<Transaction> transactions;

  const _ProfitTrendChart({required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Group transactions by date
    Map<DateTime, double> dailyIncome = {};
    Map<DateTime, double> dailyExpense = {};

    for (var transaction in transactions) {
      final dateKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      if (transaction.type == TransactionType.income) {
        dailyIncome[dateKey] =
            (dailyIncome[dateKey] ?? 0) + transaction.paidAmount;
      } else {
        dailyExpense[dateKey] =
            (dailyExpense[dateKey] ?? 0) + transaction.totalAmount;
      }
    }

    final sortedDates =
        (dailyIncome.keys.toList() + dailyExpense.keys.toList())
            .toSet()
            .toList()
          ..sort();

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      incomeSpots.add(FlSpot(i.toDouble(), dailyIncome[date] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), dailyExpense[date] ?? 0));
    }

    return Padding(
      padding: const EdgeInsets.only(
        right: 16.0,
        left: 0.0,
        top: 24.0,
        bottom: 12.0,
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1000,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < sortedDates.length) {
                    final date = sortedDates[value.toInt()];
                    // Show minimal labels to avoid overcrowding
                    if (sortedDates.length > 7 &&
                        value.toInt() % (sortedDates.length ~/ 5) != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat.MMMd().format(date),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compactSimpleCurrency(
                      name: currency,
                    ).format(value),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withValues(alpha: 0.1),
              ),
            ),
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final flSpot = barSpot;
                  final isIncome = barSpot.barIndex == 0;
                  return LineTooltipItem(
                    '${isIncome ? l10n.income : l10n.expense} \n ${NumberFormat.currency(symbol: currency).format(flSpot.y)}',
                    TextStyle(
                      color: isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseBreakdownChart extends ConsumerWidget {
  final List<Transaction> transactions;

  const _ExpenseBreakdownChart({required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);

    Map<String, double> categoryExpenses = {};
    double totalExpenses = 0;

    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        categoryExpenses[t.category] =
            (categoryExpenses[t.category] ?? 0) + t.totalAmount;
        totalExpenses += t.totalAmount;
      }
    }

    if (categoryExpenses.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noExpensesInPeriod));
    }

    final List<Color> colors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.purple,
      Colors.blue,
      Colors.teal,
      Colors.brown,
      Colors.grey,
    ];

    int colorIndex = 0;
    List<PieChartSectionData> sections = [];

    categoryExpenses.forEach((category, amount) {
      final percentage = (amount / totalExpenses) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _Badge(
            _getLocalizedCategory(context, category),
            amount,
            currency,
            colors[colorIndex % colors.length],
          ),
          badgePositionPercentageOffset: 1.3,
        ),
      );
      colorIndex++;
    });

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    );
  }

  String _getLocalizedCategory(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
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
      default:
        return category;
    }
  }
}

class _Badge extends StatelessWidget {
  final String category;
  final double amount;
  final String currency;
  final Color color;

  const _Badge(this.category, this.amount, this.currency, this.color);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            NumberFormat.compactSimpleCurrency(name: currency).format(amount),
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
