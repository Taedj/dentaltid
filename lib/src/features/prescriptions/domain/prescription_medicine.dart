class PrescriptionMedicine {
  final String medicineName;
  final String quantity;
  final String frequency;
  final String route;
  final String time;

  PrescriptionMedicine({
    required this.medicineName,
    required this.quantity,
    required this.frequency,
    required this.route,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'medicineName': medicineName,
    'quantity': quantity,
    'frequency': frequency,
    'route': route,
    'time': time,
  };

  factory PrescriptionMedicine.fromJson(Map<String, dynamic> json) =>
      PrescriptionMedicine(
        medicineName: json['medicineName'],
        quantity: json['quantity'],
        frequency: json['frequency'],
        route: json['route'],
        time: json['time'],
      );

  PrescriptionMedicine copyWith({
    String? medicineName,
    String? quantity,
    String? frequency,
    String? route,
    String? time,
  }) {
    return PrescriptionMedicine(
      medicineName: medicineName ?? this.medicineName,
      quantity: quantity ?? this.quantity,
      frequency: frequency ?? this.frequency,
      route: route ?? this.route,
      time: time ?? this.time,
    );
  }
}
