class InventoryItem {
  final int? id;
  final String name;
  final int quantity;
  final DateTime expirationDate;
  final String supplier;

  InventoryItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.expirationDate,
    required this.supplier,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'expirationDate': expirationDate.toIso8601String(),
        'supplier': supplier,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'],
        name: json['name'],
        quantity: json['quantity'],
        expirationDate: DateTime.parse(json['expirationDate']),
        supplier: json['supplier'],
      );

  InventoryItem copyWith({
    int? id,
    String? name,
    int? quantity,
    DateTime? expirationDate,
    String? supplier,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      supplier: supplier ?? this.supplier,
    );
  }
}
