class InventoryItem {
  final int? id;
  final String name;
  final int quantity;
  final DateTime expirationDate;
  final String supplier;
  final int thresholdDays;
  final int lowStockThreshold;
  final double cost;

  InventoryItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.expirationDate,
    required this.supplier,
    this.thresholdDays = 30,
    this.lowStockThreshold = 5,
    required this.cost,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'expirationDate': expirationDate.toIso8601String(),
    'supplier': supplier,
    'thresholdDays': thresholdDays,
    'lowStockThreshold': lowStockThreshold,
    'cost': cost,
  };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'],
    name: json['name'],
    quantity: json['quantity'],
    expirationDate: DateTime.parse(json['expirationDate']),
    supplier: json['supplier'],
    thresholdDays: json['thresholdDays'] ?? 30,
    lowStockThreshold: json['lowStockThreshold'] ?? 5,
    cost: json['cost'] ?? 0.0,
  );

  InventoryItem copyWith({
    int? id,
    String? name,
    int? quantity,
    DateTime? expirationDate,
    String? supplier,
    int? thresholdDays,
    int? lowStockThreshold,
    double? cost,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      supplier: supplier ?? this.supplier,
      thresholdDays: thresholdDays ?? this.thresholdDays,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      cost: cost ?? this.cost,
    );
  }
}
