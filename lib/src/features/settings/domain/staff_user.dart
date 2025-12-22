import 'package:dentaltid/src/core/user_model.dart';

enum StaffRole {
  assistant,
  receptionist;

  String toStringValue() {
    return toString().split('.').last;
  }

  static StaffRole fromString(String value) {
    return StaffRole.values.firstWhere(
      (e) => e.toStringValue() == value,
      orElse: () => StaffRole.receptionist,
    );
  }

  UserRole toUserRole() {
    switch (this) {
      case StaffRole.assistant:
        return UserRole.assistant;
      case StaffRole.receptionist:
        return UserRole.receptionist;
    }
  }
}

class StaffUser {
  final int? id;
  final String fullName;
  final String username;
  final String pin;
  final StaffRole role;
  final DateTime createdAt;

  StaffUser({
    this.id,
    required this.fullName,
    required this.username,
    required this.pin,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'pin': pin,
      'role': role.toStringValue(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id'] as int?,
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      pin: json['pin'] as String,
      role: StaffRole.fromString(json['role'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  StaffUser copyWith({
    int? id,
    String? fullName,
    String? username,
    String? pin,
    StaffRole? role,
    DateTime? createdAt,
  }) {
    return StaffUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
