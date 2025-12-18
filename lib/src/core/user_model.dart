enum SubscriptionPlan { free, trial, basic, professional, clinic, enterprise }

enum SubscriptionStatus { active, expired, cancelled, suspended }

enum UserRole { dentist, assistant, receptionist, developer }

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
  final String? medicalLicenseNumber;

  // Trial & Application Limits
  final DateTime? trialStartDate;
  final bool isPremium;
  final DateTime? premiumExpiryDate;
  final int cumulativePatients;
  final int cumulativeAppointments;
  final int cumulativeInventory;

  bool get isTrialExpired {
    if (isPremium) return false;
    if (trialStartDate == null) return true; // Should ideally have a start date
    final daysUsed = DateTime.now().difference(trialStartDate!).inDays;
    return daysUsed >= 30;
  }

  // For managed users (assistant/receptionist)
  final bool isManagedUser;
  final String? managedByDentistId; // UID of the dentist who manages this user
  final UserRole role;
  final String? username; // For managed users, instead of complex email
  final String? pin; // PIN for managed users (hashed in production)

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
    this.medicalLicenseNumber,
    this.trialStartDate,
    this.isPremium = false,
    this.premiumExpiryDate,
    this.cumulativePatients = 0,
    this.cumulativeAppointments = 0,
    this.cumulativeInventory = 0,
    this.isManagedUser = false,
    this.managedByDentistId,
    this.role = UserRole.dentist,
    this.username,
    this.pin,
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
        'medicalLicenseNumber': medicalLicenseNumber,
        'trialStartDate': trialStartDate?.toIso8601String(),
        'isPremium': isPremium ? 1 : 0,
        'premiumExpiryDate': premiumExpiryDate?.toIso8601String(),
        'cumulativePatients': cumulativePatients,
        'cumulativeAppointments': cumulativeAppointments,
        'cumulativeInventory': cumulativeInventory,
        'isManagedUser': isManagedUser ? 1 : 0,
        'managedByDentistId': managedByDentistId,
        'role': role.toString(),
        'username': username,
        'pin': pin,
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
        medicalLicenseNumber: json['medicalLicenseNumber'],
        trialStartDate: json['trialStartDate'] != null
            ? DateTime.parse(json['trialStartDate'])
            : null,
        isPremium: json['isPremium'] == 1 || json['isPremium'] == true,
        premiumExpiryDate: json['premiumExpiryDate'] != null
            ? DateTime.parse(json['premiumExpiryDate'])
            : null,
        cumulativePatients: json['cumulativePatients'] ?? 0,
        cumulativeAppointments: json['cumulativeAppointments'] ?? 0,
        cumulativeInventory: json['cumulativeInventory'] ?? 0,
        isManagedUser: json['isManagedUser'] == 1 || json['isManagedUser'] == true,
        managedByDentistId: json['managedByDentistId'],
        role: UserRole.values.firstWhere(
          (e) => e.toString() == json['role'],
          orElse: () => UserRole.dentist,
        ),
        username: json['username'],
        pin: json['pin'],
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
    String? medicalLicenseNumber,
    DateTime? trialStartDate,
    bool? isPremium,
    DateTime? premiumExpiryDate,
    int? cumulativePatients,
    int? cumulativeAppointments,
    int? cumulativeInventory,
    bool? isManagedUser,
    String? managedByDentistId,
    UserRole? role,
    String? username,
    String? pin,
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
      medicalLicenseNumber: medicalLicenseNumber ?? this.medicalLicenseNumber,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      cumulativePatients: cumulativePatients ?? this.cumulativePatients,
      cumulativeAppointments:
          cumulativeAppointments ?? this.cumulativeAppointments,
      cumulativeInventory: cumulativeInventory ?? this.cumulativeInventory,
      isManagedUser: isManagedUser ?? this.isManagedUser,
      managedByDentistId: managedByDentistId ?? this.managedByDentistId,
      role: role ?? this.role,
      username: username ?? this.username,
      pin: pin ?? this.pin,
    );
  }
}
