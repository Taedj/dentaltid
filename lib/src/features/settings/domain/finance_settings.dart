class FinanceSettings {
  final bool includeInventory;
  final bool includeAppointments;
  final bool includeRecurring;
  final double? monthlyBudgetCap;
  final double taxRatePercentage;
  final bool useCompactNumbers;

  const FinanceSettings({
    this.includeInventory = true,
    this.includeAppointments = true,
    this.includeRecurring = true,
    this.monthlyBudgetCap,
    this.taxRatePercentage = 0.0,
    this.useCompactNumbers = true,
  });

  FinanceSettings copyWith({
    bool? includeInventory,
    bool? includeAppointments,
    bool? includeRecurring,
    double? monthlyBudgetCap,
    double? taxRatePercentage,
    bool? useCompactNumbers,
  }) {
    return FinanceSettings(
      includeInventory: includeInventory ?? this.includeInventory,
      includeAppointments: includeAppointments ?? this.includeAppointments,
      includeRecurring: includeRecurring ?? this.includeRecurring,
      monthlyBudgetCap: monthlyBudgetCap ?? this.monthlyBudgetCap,
      taxRatePercentage: taxRatePercentage ?? this.taxRatePercentage,
      useCompactNumbers: useCompactNumbers ?? this.useCompactNumbers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includeInventory': includeInventory,
      'includeAppointments': includeAppointments,
      'includeRecurring': includeRecurring,
      'monthlyBudgetCap': monthlyBudgetCap,
      'taxRatePercentage': taxRatePercentage,
      'useCompactNumbers': useCompactNumbers,
    };
  }

  factory FinanceSettings.fromJson(Map<String, dynamic> json) {
    return FinanceSettings(
      includeInventory: json['includeInventory'] ?? true,
      includeAppointments: json['includeAppointments'] ?? true,
      includeRecurring: json['includeRecurring'] ?? true,
      monthlyBudgetCap: json['monthlyBudgetCap'] != null
          ? (json['monthlyBudgetCap'] as num).toDouble()
          : null,
      taxRatePercentage: (json['taxRatePercentage'] ?? 0.0) as double,
      useCompactNumbers: json['useCompactNumbers'] ?? true,
    );
  }
}
