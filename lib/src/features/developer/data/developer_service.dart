import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:flutter/foundation.dart';

class DeveloperService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';
  final String _codesCollection = 'activation_codes';

  // Fetch all users
  Stream<List<UserProfile>> getAllUsers() {
    return _firestore.collectionGroup('profile').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id == 'info') // Ensure we only get the 'info' doc
          .map((doc) {
            try {
              return UserProfile.fromJson(doc.data());
            } catch (e) {
              debugPrint("Error parsing user ${doc.id}: $e");
              // Return a null-like object or filter? map expects return.
              // Let's return a dummy or filter out nulls in a step before?
              // Safer to rethrow or correct loop.
              // For now, let's just log and skip if possible, but map needs a return.
              // We can return nullable and whereType in the chain if we change return signature.
              // But simplify: assume strict schema or crash.
              rethrow;
            }
          })
          .toList();
    });
  }

  // Update a user's plan
  Future<void> updateUserPlan(
    String userId, {
    required SubscriptionPlan plan,
    required SubscriptionStatus status,
    DateTime? expiryDate,
    bool isPremium = false,
  }) async {
    await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection('profile')
        .doc('info')
        .update({
          'plan': plan.toString(),
          'status': status.toString(),
          if (expiryDate != null)
            'premiumExpiryDate': expiryDate.toIso8601String(),
          'isPremium': isPremium,
        });
  }

  // -- Activation Codes --

  Stream<List<ActivationCodeModel>> getActivationCodes() {
    return _firestore
        .collection(_codesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ActivationCodeModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> deleteActivationCode(String docId) async {
    await _firestore.collection(_codesCollection).doc(docId).delete();
  }
}

class ActivationCodeModel {
  final String id;
  final String code;
  final int durationMonths;
  final String type;
  final DateTime createdAt;
  final bool isRedeemed;
  final String? redeemedBy; // UID
  final DateTime? redeemedAt;
  final String? redeemedByEmail;
  final String? redeemedByPhone;

  ActivationCodeModel({
    required this.id,
    required this.code,
    required this.durationMonths,
    required this.type,
    required this.createdAt,
    required this.isRedeemed,
    this.redeemedBy,
    this.redeemedAt,
    this.redeemedByEmail,
    this.redeemedByPhone,
  });

  factory ActivationCodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      // Fallback if needed, though usually Timestamp in Firestore
      return null;
    }

    return ActivationCodeModel(
      id: doc.id,
      code: data['code'] ?? '',
      durationMonths: data['durationMonths'] ?? 0,
      type: data['type'] ?? '',
      createdAt: parseTimestamp(data['createdAt']) ?? DateTime.now(),
      isRedeemed: data['isRedeemed'] ?? false,
      redeemedBy: data['redeemedBy'],
      redeemedAt: parseTimestamp(data['redeemedAt']),
      redeemedByEmail: data['redeemedByEmail'],
      redeemedByPhone: data['redeemedByPhone'],
    );
  }
}
