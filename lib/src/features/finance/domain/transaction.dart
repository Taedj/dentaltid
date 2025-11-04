enum TransactionType { income, expense }

enum TransactionStatus { paid, unpaid }

class Transaction {
  final int? id;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final TransactionStatus status;

  Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    this.status = TransactionStatus.unpaid,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'type': type.toString(),
    'date': date.toIso8601String(),
    'status': status.toString(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    description: json['description'],
    amount: json['amount'],
    type: TransactionType.values.firstWhere(
      (e) => e.toString() == json['type'],
    ),
    date: DateTime.parse(json['date']),
    status: TransactionStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => TransactionStatus.unpaid,
    ),
  );

  Transaction copyWith({
    int? id,
    String? description,
    double? amount,
    TransactionType? type,
    DateTime? date,
    TransactionStatus? status,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }
}
