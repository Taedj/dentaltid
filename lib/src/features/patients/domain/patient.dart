enum PatientFilter { all, today, thisWeek, thisMonth }

class Patient {
  final int? id;
  final String name;
  final String familyName;
  final int age;
  final String healthState;
  final String diagnosis;
  final String treatment;
  final double payment;
  final DateTime createdAt;

  Patient({
    this.id,
    required this.name,
    required this.familyName,
    required this.age,
    required this.healthState,
    required this.diagnosis,
    required this.treatment,
    required this.payment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'familyName': familyName,
        'age': age,
        'healthState': healthState,
        'diagnosis': diagnosis,
        'treatment': treatment,
        'payment': payment,
        'createdAt': createdAt.toIso8601String(),
      };

  Patient copyWith({
    int? id,
    String? name,
    String? familyName,
    int? age,
    String? healthState,
    String? diagnosis,
    String? treatment,
    double? payment,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      familyName: familyName ?? this.familyName,
      age: age ?? this.age,
      healthState: healthState ?? this.healthState,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      payment: payment ?? this.payment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'],
        name: json['name'],
        familyName: json['familyName'],
        age: json['age'],
        healthState: json['healthState'],
        diagnosis: json['diagnosis'],
        treatment: json['treatment'],
        payment: json['payment'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
