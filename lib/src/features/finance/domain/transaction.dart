enum TransactionType { income, expense }

enum TransactionStatus { paid, unpaid }

enum PaymentMethod { cash, card, insurance, bankTransfer, other }

enum TransactionSourceType {
  appointment,
  inventory,
  recurringCharge,
  salary,
  rent,
  other,
}

class Transaction {
  final int? id;
  final int? sessionId; // This can be considered as appointmentId
  final String description;
  final double totalAmount;
  final double paidAmount;
  final TransactionType type;
  final DateTime date;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  final TransactionSourceType sourceType;
  final int? sourceId;
  final String category;

  Transaction({
    this.id,
    this.sessionId,
    required this.description,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.type,
    required this.date,
    this.status = TransactionStatus.unpaid,
    this.paymentMethod = PaymentMethod.cash,
    required this.sourceType,
    this.sourceId,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'description': description,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'type': type.toString(),
    'date': date.toIso8601String(),
    'status': status.toString(),
    'paymentMethod': paymentMethod.toString(),
    'sourceType': sourceType.toString(),
    'sourceId': sourceId,
    'category': category,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    sessionId: json['sessionId'],
    description: json['description'],
    totalAmount: json['totalAmount'],
    paidAmount: json['paidAmount'] ?? 0.0,
    type: TransactionType.values.firstWhere(
      (e) => e.toString() == json['type'],
    ),
    date: DateTime.parse(json['date']),
    status: TransactionStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => TransactionStatus.unpaid,
    ),
    paymentMethod: PaymentMethod.values.firstWhere(
      (e) => e.toString() == json['paymentMethod'],
      orElse: () => PaymentMethod.cash,
    ),
    sourceType: TransactionSourceType.values.firstWhere(
      (e) => e.toString() == json['sourceType'],
      orElse: () => TransactionSourceType.other,
    ),
    sourceId: json['sourceId'],
    category: json['category'] ?? '',
  );

  Transaction copyWith({
    int? id,
    int? sessionId,
    String? description,
    double? totalAmount,
    double? paidAmount,
    TransactionType? type,
    DateTime? date,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    TransactionSourceType? sourceType,
    int? sourceId,
    String? category,
  }) {
    return Transaction(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      type: type ?? this.type,
      date: date ?? this.date,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      category: category ?? this.category,
    );
  }
}
