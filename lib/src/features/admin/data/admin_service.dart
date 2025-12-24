import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dentaltid/src/core/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // Fetch all users (Paginated ideally, but starting simple)
  Stream<List<UserProfile>> getAllUsers() {
    return _firestore.collection(_usersCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserProfile.fromJson(doc.data());
      }).toList();
    });
  }

  // Update a user's plan (e.g., grant premium)
  Future<void> updateUserPlan(
    String userId, {
    required SubscriptionPlan plan,
    required SubscriptionStatus status,
    DateTime? expiryDate,
    bool isPremium = false,
  }) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'plan': plan.toString(),
      'status': status.toString(),
      // If we are granting premium, we might want to set this
      if (expiryDate != null) 'premiumExpiryDate': expiryDate.toIso8601String(),
      'isPremium': isPremium,
    });
  }

  // Future: Ban user, Delete user, Impersonate
}
