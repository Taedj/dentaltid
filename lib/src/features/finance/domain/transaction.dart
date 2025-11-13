enum TransactionType { income, expense }

enum TransactionStatus { paid, unpaid }

enum PaymentMethod { cash, card, insurance, bankTransfer, other }

class Transaction {
  final int? id;
  final int? patientId;
  final int? visitId; // New field to link to a Visit
  final String description;
  final double totalAmount;
  final double paidAmount;
  final TransactionType type;
  final DateTime date;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;

  Transaction({
    this.id,
    this.patientId,
    this.visitId, // New field
    required this.description,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.type,
    required this.date,
    this.status = TransactionStatus.unpaid,
    this.paymentMethod = PaymentMethod.cash,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'visitId': visitId,
    'description': description,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'type': type.toString(),
    'date': date.toIso8601String(),
    'status': status.toString(),
    'paymentMethod': paymentMethod.toString(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    patientId: json['patientId'],
    visitId: json['visitId'],
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
  );

  Transaction copyWith({
    int? id,
    int? patientId,
    int? visitId,
    String? description,
    double? totalAmount,
    double? paidAmount,
    TransactionType? type,
    DateTime? date,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
  }) {
    return Transaction(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      visitId: visitId ?? this.visitId,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      type: type ?? this.type,
      date: date ?? this.date,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
