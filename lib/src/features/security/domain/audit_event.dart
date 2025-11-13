enum AuditAction {
  login,
  logout,
  createPatient,
  updatePatient,
  deletePatient,
  createAppointment,
  updateAppointment,
  deleteAppointment,
  createSession,
  updateSession,
  deleteSession,
  createTransaction,
  updateTransaction,
  deleteTransaction,
  createInventoryItem,
  updateInventoryItem,
  deleteInventoryItem,
  createBackup,
  restoreBackup,
}

class AuditEvent {
  final int? id;
  final AuditAction action;
  final String userId; // For now, we'll use the role as userId
  final DateTime timestamp;
  final String? details;

  AuditEvent({
    this.id,
    required this.action,
    required this.userId,
    required this.timestamp,
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action.toString(),
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
  };

  factory AuditEvent.fromJson(Map<String, dynamic> json) => AuditEvent(
    id: json['id'],
    action: AuditAction.values.firstWhere(
      (e) => e.toString() == json['action'],
    ),
    userId: json['userId'],
    timestamp: DateTime.parse(json['timestamp']),
    details: json['details'],
  );
}
