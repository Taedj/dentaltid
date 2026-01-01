import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dentaltid/src/core/user_model.dart'; // For SubscriptionPlan enum

enum OrderStatus { pending, approved, rejected }

class PurchaseOrder {
  final String id;
  final String userId;
  final String userEmail;
  final String? dentistName; // Snapshot for convenience
  final SubscriptionPlan plan;
  final String durationLabel; // e.g., "yearly", "monthly", "lifetime"
  final String priceLabel; // e.g., "20,000 DZD"
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;

  PurchaseOrder({
    required this.id,
    required this.userId,
    required this.userEmail,
    this.dentistName,
    required this.plan,
    required this.durationLabel,
    required this.priceLabel,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'dentistName': dentistName,
      'plan': plan.toString(),
      'durationLabel': durationLabel,
      'priceLabel': priceLabel,
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userEmail: json['userEmail'] ?? '',
      dentistName: json['dentistName'],
      plan: SubscriptionPlan.values.firstWhere(
            (e) => e.toString() == json['plan'],
        orElse: () => SubscriptionPlan.trial,
      ),
      durationLabel: json['durationLabel'] ?? 'unknown',
      priceLabel: json['priceLabel'] ?? '',
      status: OrderStatus.values.firstWhere(
            (e) => e.toString() == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      processedAt: (json['processedAt'] as Timestamp?)?.toDate(),
    );
  }
}
