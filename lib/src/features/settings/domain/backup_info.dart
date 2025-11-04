import 'package:cloud_firestore/cloud_firestore.dart';

class BackupInfo {
  final String id;
  final DateTime timestamp;

  BackupInfo({required this.id, required this.timestamp});

  factory BackupInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BackupInfo(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
