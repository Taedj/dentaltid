import 'package:cloud_firestore/cloud_firestore.dart';

class BroadcastService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'broadcasts';

  // Send a new broadcast
  Future<void> sendBroadcast({
    required String title,
    required String message,
    required String type, // 'info', 'warning', 'maintenance'
    required String authorId,
  }) async {
    await _firestore.collection(_collection).add({
      'title': title,
      'message': message,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': authorId,
      'active': true,
    });
  }

  // Get active broadcasts (ordered by date)
  Stream<List<BroadcastModel>> getActiveBroadcasts() {
    // Limit to last 5 or specific time window in future if needed
    // For now, simple list
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BroadcastModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> deleteBroadcast(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}

class BroadcastModel {
  final String id;
  final String title;
  final String message;
  final String type; // info, warning, error/maintenance
  final DateTime createdAt;

  BroadcastModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
  });

  factory BroadcastModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BroadcastModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'info',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
