enum SubscriptionPlan { trial, basic, professional, clinic, enterprise }

enum SubscriptionStatus { active, expired, cancelled, suspended }

class UserProfile {
  final String uid;
  final String email;
  final String licenseKey;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime licenseExpiry;
  final DateTime createdAt;
  final DateTime lastLogin;
  final DateTime lastSync;
  final String? clinicName;
  final String? dentistName;
  final String? phoneNumber;

  UserProfile({
    required this.uid,
    required this.email,
    required this.licenseKey,
    required this.plan,
    required this.status,
    required this.licenseExpiry,
    required this.createdAt,
    required this.lastLogin,
    required this.lastSync,
    this.clinicName,
    this.dentistName,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'licenseKey': licenseKey,
    'plan': plan.toString(),
    'status': status.toString(),
    'licenseExpiry': licenseExpiry.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'lastLogin': lastLogin.toIso8601String(),
    'lastSync': lastSync.toIso8601String(),
    'clinicName': clinicName,
    'dentistName': dentistName,
    'phoneNumber': phoneNumber,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'],
    email: json['email'],
    licenseKey: json['licenseKey'],
    plan: SubscriptionPlan.values.firstWhere(
      (e) => e.toString() == json['plan'],
      orElse: () => SubscriptionPlan.trial,
    ),
    status: SubscriptionStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => SubscriptionStatus.active,
    ),
    licenseExpiry: DateTime.parse(json['licenseExpiry']),
    createdAt: DateTime.parse(json['createdAt']),
    lastLogin: DateTime.parse(json['lastLogin']),
    lastSync: DateTime.parse(json['lastSync']),
    clinicName: json['clinicName'],
    dentistName: json['dentistName'],
    phoneNumber: json['phoneNumber'],
  );

  UserProfile copyWith({
    String? uid,
    String? email,
    String? licenseKey,
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    DateTime? licenseExpiry,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? lastSync,
    String? clinicName,
    String? dentistName,
    String? phoneNumber,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      licenseKey: licenseKey ?? this.licenseKey,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      lastSync: lastSync ?? this.lastSync,
      clinicName: clinicName ?? this.clinicName,
      dentistName: dentistName ?? this.dentistName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
