import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dentaltid/src/features/settings/domain/backup_info.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<BackupInfo>> getBackups() async {
    try {
      final snapshot = await _firestore.collection('backups').orderBy('timestamp', descending: true).get();
      return snapshot.docs.map((doc) => BackupInfo.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> uploadBackupToFirestore(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      // Split into chunks of 500KB
      const chunkSize = 500 * 1024;
      final chunks = <String>[];
      for (var i = 0; i < base64String.length; i += chunkSize) {
        chunks.add(base64String.substring(i, i + chunkSize > base64String.length ? base64String.length : i + chunkSize));
      }

      final backupDoc = await _firestore.collection('backups').add({
        'timestamp': FieldValue.serverTimestamp(),
        'chunkCount': chunks.length,
      });

      for (var i = 0; i < chunks.length; i++) {
        await backupDoc.collection('chunks').doc(i.toString()).set({'data': chunks[i]});
      }

      return backupDoc.id;
    } catch (e) {
      return null;
    }
  }

  Future<File?> downloadBackupFromFirestore(String backupId, String destinationPath) async {
    try {
      final backupDoc = await _firestore.collection('backups').doc(backupId).get();
      final chunkCount = backupDoc.data()!['chunkCount'] as int;

      final chunks = <String>[];
      for (var i = 0; i < chunkCount; i++) {
        final chunkDoc = await _firestore.collection('backups').doc(backupId).collection('chunks').doc(i.toString()).get();
        chunks.add(chunkDoc.data()!['data'] as String);
      }

      final base64String = chunks.join();
      final bytes = base64Decode(base64String);

      final file = File(destinationPath);
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      return null;
    }
  }
}