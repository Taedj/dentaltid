enum PatientFilter { all, today, thisWeek, thisMonth, emergency }

enum EmergencySeverity { low, medium, high }

class Patient {
  final int? id;
  final String name;
  final String familyName;
  final int age;
  final DateTime? dateOfBirth;
  final String healthState;
  final String diagnosis;
  final String treatment;
  final double payment;
  final DateTime createdAt;
  final bool isEmergency;
  final EmergencySeverity severity;
  final String healthAlerts;
  final String phoneNumber;
  final bool isBlacklisted;

  Patient({
    this.id,
    required this.name,
    required this.familyName,
    required this.age,
    this.dateOfBirth,
    required this.healthState,
    required this.diagnosis,
    required this.treatment,
    required this.payment,
    required this.createdAt,
    this.isEmergency = false,
    this.severity = EmergencySeverity.low,
    this.healthAlerts = '',
    this.phoneNumber = '',
    this.isBlacklisted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'familyName': familyName,
    'age': age,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'healthState': healthState,
    'diagnosis': diagnosis,
    'treatment': treatment,
    'payment': payment,
    'createdAt': createdAt.toIso8601String(),
    'isEmergency': isEmergency ? 1 : 0,
    'severity': severity.toString(),
    'healthAlerts': healthAlerts,
    'phoneNumber': phoneNumber,
    'isBlacklisted': isBlacklisted ? 1 : 0,
  };

  Patient copyWith({
    int? id,
    String? name,
    String? familyName,
    int? age,
    DateTime? dateOfBirth,
    String? healthState,
    String? diagnosis,
    String? treatment,
    double? payment,
    DateTime? createdAt,
    bool? isEmergency,
    EmergencySeverity? severity,
    String? healthAlerts,
    String? phoneNumber,
    bool? isBlacklisted,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      familyName: familyName ?? this.familyName,
      age: age ?? this.age,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      healthState: healthState ?? this.healthState,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      payment: payment ?? this.payment,
      createdAt: createdAt ?? this.createdAt,
      isEmergency: isEmergency ?? this.isEmergency,
      severity: severity ?? this.severity,
      healthAlerts: healthAlerts ?? this.healthAlerts,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
    );
  }

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'],
    name: json['name'],
    familyName: json['familyName'],
    age: json['age'],
    dateOfBirth: json['dateOfBirth'] != null
        ? DateTime.parse(json['dateOfBirth'])
        : null,
    healthState: json['healthState'],
    diagnosis: json['diagnosis'],
    treatment: json['treatment'],
    payment: json['payment'],
    createdAt: DateTime.parse(json['createdAt']),
    isEmergency: json['isEmergency'] == 1,
    severity: EmergencySeverity.values.firstWhere(
      (e) => e.toString() == json['severity'],
      orElse: () => EmergencySeverity.low,
    ),
    healthAlerts: json['healthAlerts'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    isBlacklisted: json['isBlacklisted'] == 1,
  );
}
