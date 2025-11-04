import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';

class FinanceChart extends StatelessWidget {
  final List<Transaction> transactions;

  const FinanceChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Group transactions by date
    Map<String, double> dailyIncome = {};
    Map<String, double> dailyExpense = {};

    for (var transaction in transactions) {
      final dateKey = transaction.date.toIso8601String().split('T')[0];
      if (transaction.type == TransactionType.income) {
        dailyIncome[dateKey] = (dailyIncome[dateKey] ?? 0) + transaction.amount;
      } else {
        dailyExpense[dateKey] =
            (dailyExpense[dateKey] ?? 0) + transaction.amount;
      }
    }

    // Prepare data for the bar chart
    List<BarChartGroupData> barGroups = [];
    int x = 0;
    final sortedDates =
        (dailyIncome.keys.toList() + dailyExpense.keys.toList())
            .toSet()
            .toList()
          ..sort();

    for (var dateKey in sortedDates) {
      final income = dailyIncome[dateKey] ?? 0;
      final expense = dailyExpense[dateKey] ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(toY: income, color: Colors.green, width: 10),
            BarChartRodData(toY: expense, color: Colors.red, width: 10),
          ],
          showingTooltipIndicators: [0, 1],
        ),
      );
      x++;
    }

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < sortedDates.length) {
                    return Text(
                      sortedDates[value.toInt()].substring(5),
                    ); // Show MM-DD
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }
}
