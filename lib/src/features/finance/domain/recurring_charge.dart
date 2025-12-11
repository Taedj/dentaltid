enum RecurringChargeFrequency {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom,
}

class RecurringCharge {
  final int? id;
  final String name;
  final double amount;
  final RecurringChargeFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String description;

  RecurringCharge({
    this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'frequency': frequency.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'description': description,
    };
  }

  factory RecurringCharge.fromMap(Map<String, dynamic> map) {
    return RecurringCharge(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      frequency: RecurringChargeFrequency.values.firstWhere(
        (e) => e.toString() == map['frequency'],
        orElse: () => RecurringChargeFrequency.monthly,
      ),
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      isActive: map['isActive'] == 1,
      description: map['description'],
    );
  }

  RecurringCharge copyWith({
    int? id,
    String? name,
    double? amount,
    RecurringChargeFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? description,
  }) {
    return RecurringCharge(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
    );
  }
}
