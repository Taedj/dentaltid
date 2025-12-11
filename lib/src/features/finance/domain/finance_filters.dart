import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class FinanceFilters extends Equatable {
  final DateTimeRange dateRange;
  final bool includeRecurringCharges;
  final bool includeInventoryExpenses;
  final bool includeStaffSalaries;
  final bool includeRent;

  const FinanceFilters({
    required this.dateRange,
    this.includeRecurringCharges = true,
    this.includeInventoryExpenses = true,
    this.includeStaffSalaries = false,
    this.includeRent = false,
  });

  @override
  List<Object?> get props => [
    dateRange,
    includeRecurringCharges,
    includeInventoryExpenses,
    includeStaffSalaries,
    includeRent,
  ];
}
