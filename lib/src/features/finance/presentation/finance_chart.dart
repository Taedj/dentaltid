import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FinanceChart extends ConsumerWidget {
  final List<Transaction> transactions;

  const FinanceChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);

    // Group transactions by date
    Map<DateTime, double> dailyPaid = {};
    Map<DateTime, double> dailyUnpaid = {};

    for (var transaction in transactions) {
      final dateKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailyPaid[dateKey] = (dailyPaid[dateKey] ?? 0) + transaction.paidAmount;
      dailyUnpaid[dateKey] =
          (dailyUnpaid[dateKey] ?? 0) +
          (transaction.totalAmount - transaction.paidAmount);
    }

    final sortedDates =
        (dailyPaid.keys.toList() + dailyUnpaid.keys.toList()).toSet().toList()
          ..sort();

    // Calculate cumulative amounts
    List<double> cumulativePaid = [];
    List<double> cumulativeUnpaid = [];
    double paidSum = 0;
    double unpaidSum = 0;

    for (var date in sortedDates) {
      paidSum += dailyPaid[date] ?? 0;
      unpaidSum += dailyUnpaid[date] ?? 0;
      cumulativePaid.add(paidSum);
      cumulativeUnpaid.add(unpaidSum);
    }

    List<FlSpot> paidSpots = [];
    List<FlSpot> unpaidSpots = [];

    for (int i = 0; i < sortedDates.length; i++) {
      paidSpots.add(FlSpot(i.toDouble(), cumulativePaid[i]));
      unpaidSpots.add(FlSpot(i.toDouble(), cumulativeUnpaid[i]));
    }

    // Calculate totals
    final totalPaid = transactions.fold<double>(
      0.0,
      (sum, t) => sum + t.paidAmount,
    );
    final totalUnpaid = transactions.fold<double>(
      0.0,
      (sum, t) => sum + (t.totalAmount - t.paidAmount),
    );
    return Column(
      children: [
        const SizedBox(height: 128),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildBarChart(context, ref),
          ),
        ),
        const SizedBox(height: 16),
        _buildSummary(context, totalPaid, totalUnpaid, currency),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    // Group transactions by date
    Map<DateTime, double> dailyPaid = {};
    Map<DateTime, double> dailyUnpaid = {};

    for (var transaction in transactions) {
      final dateKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailyPaid[dateKey] = (dailyPaid[dateKey] ?? 0) + transaction.paidAmount;
      dailyUnpaid[dateKey] =
          (dailyUnpaid[dateKey] ?? 0) +
          (transaction.totalAmount - transaction.paidAmount);
    }

    final sortedDates =
        (dailyPaid.keys.toList() + dailyUnpaid.keys.toList()).toSet().toList()
          ..sort();

    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final paidAmount = dailyPaid[date] ?? 0;
      final unpaidAmount = dailyUnpaid[date] ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: paidAmount, color: Colors.blue, width: 16),
            BarChartRodData(toY: unpaidAmount, color: Colors.red, width: 16),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80,
              getTitlesWidget: (value, meta) {
                final format = NumberFormat.currency(symbol: currency);
                return Text(
                  format.format(value),
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                  final date = sortedDates[value.toInt()];
                  return Text(
                    DateFormat.MMMd().format(date),
                    style: theme.textTheme.bodySmall,
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: theme.dividerColor.withAlpha((255 * 0.2).round()),
            width: 1,
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = sortedDates[group.x.toInt()];
              final formattedDate = DateFormat.yMMMd().format(date);
              final amount = NumberFormat.currency(
                symbol: currency,
              ).format(rod.toY);
              final seriesName = rodIndex == 0 ? 'Paid' : 'Unpaid';
              return BarTooltipItem(
                '$seriesName\n$formattedDate\n$amount',
                TextStyle(color: rod.color, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    double totalPaid,
    double totalUnpaid,
    String currency,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'Total Paid: ${NumberFormat.currency(symbol: currency).format(totalPaid)}',
          style: TextStyle(color: Colors.blue),
        ),
        Container(height: 1, color: theme.dividerColor),
        Text(
          'Total Unpaid: ${NumberFormat.currency(symbol: currency).format(totalUnpaid)}',
          style: TextStyle(color: Colors.red),
        ),
      ],
    );
  }
}
