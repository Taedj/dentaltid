import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/features/settings/domain/backup_info.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart'
    as finance;
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('FirebaseService');

  // Auth
  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    final cred = EmailAuthProvider.credential(
      email: user!.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  // User Profile Management
  Future<void> createUserProfile(UserProfile profile, String licenseKey) async {
    await _firestore
        .collection('users')
        .doc(profile.uid)
        .collection('profile')
        .doc('info')
        .set(profile.toJson());
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('info')
          .get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getUserLicense(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('info')
          .get();
      if (doc.exists) {
        return doc.data()!['licenseKey'] as String?;
      }
      return null; // Explicitly return null if doc does not exist
    } catch (e, s) {
      _logger.severe('Error in getUserLicense: $e', e, s);
      return null;
    }
  }

  Future<void> updateUserProfile(String uid, UserProfile profile) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('info')
        .set(profile.toJson(), SetOptions(merge: true));
  }

  // Patients Management
  Future<void> syncPatient(String uid, Patient patient) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patient.id.toString())
        .set({...patient.toJson(), 'syncedAt': FieldValue.serverTimestamp()});
  }

  Future<List<Patient>> getSyncedPatients(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('patients')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Patient.fromJson(doc.data())).toList();
  }

  // Appointments Management
  Future<void> syncAppointment(String uid, Appointment appointment) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .doc(appointment.id.toString())
        .set({
          ...appointment.toJson(),
          'syncedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<List<Appointment>> getSyncedAppointments(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Appointment.fromJson(doc.data()))
        .toList();
  }

  // Finance/Transactions Management
  Future<void> syncTransaction(
    String uid,
    finance.Transaction transaction,
  ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('finance')
        .doc(transaction.id.toString())
        .set({
          ...transaction.toJson(),
          'syncedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<List<finance.Transaction>> getSyncedTransactions(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('finance')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => finance.Transaction.fromJson(doc.data()))
        .toList();
  }

  // Inventory Management
  Future<void> syncInventoryItem(String uid, InventoryItem item) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .doc(item.id.toString())
        .set({...item.toJson(), 'syncedAt': FieldValue.serverTimestamp()});
  }

  Future<List<InventoryItem>> getSyncedInventory(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .orderBy('name')
        .get();

    return snapshot.docs
        .map((doc) => InventoryItem.fromJson(doc.data()))
        .toList();
  }

  // Backup Management (Legacy - keeping for compatibility)
  Future<List<BackupInfo>> getBackups() async {
    try {
      final snapshot = await _firestore
          .collection('backups')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => BackupInfo.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // User-specific backups
  Future<List<BackupInfo>> getUserBackups(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('backups')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => BackupInfo.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.severe('Error getting user backups for $uid: $e');
      return [];
    }
  }

  // User-specific backups
  Future<String?> uploadUserBackupToFirestore(
    String uid,
    String filePath,
  ) async {
    try {
      _logger.info(
        'Starting upload to Firestore for user $uid, file: $filePath',
      );
      final file = File(filePath);
      if (!file.existsSync()) {
        _logger.severe('Backup file does not exist: $filePath');
        return null;
      }
      final bytes = await file.readAsBytes();
      _logger.info('File read successfully, size: ${bytes.length} bytes');
      final base64String = base64Encode(bytes);
      _logger.info('Base64 encoded, length: ${base64String.length} characters');

      // Split into chunks of 500KB
      const chunkSize = 500 * 1024;
      final chunks = <String>[];
      for (var i = 0; i < base64String.length; i += chunkSize) {
        chunks.add(
          base64String.substring(
            i,
            i + chunkSize > base64String.length
                ? base64String.length
                : i + chunkSize,
          ),
        );
      }

      _logger.info('Creating backup document with ${chunks.length} chunks');
      final backupDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('backups')
          .add({
            'timestamp': FieldValue.serverTimestamp(),
            'chunkCount': chunks.length,
          });
      _logger.info('Backup document created with ID: ${backupDoc.id}');

      _logger.info('Uploading ${chunks.length} chunks...');
      for (var i = 0; i < chunks.length; i++) {
        await backupDoc.collection('chunks').doc(i.toString()).set({
          'data': chunks[i],
        });
        if (i % 10 == 0 || i == chunks.length - 1) {
          _logger.info('Uploaded chunk $i/${chunks.length}');
        }
      }
      _logger.info('All chunks uploaded successfully');

      return backupDoc.id;
    } catch (e, s) {
      _logger.severe('Error in uploadUserBackupToFirestore: $e', e, s);
      return null;
    }
  }

  Future<File?> downloadUserBackupFromFirestore(
    String uid,
    String backupId,
    String destinationPath,
  ) async {
    try {
      final backupDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('backups')
          .doc(backupId)
          .get();
      final chunkCount = backupDoc.data()!['chunkCount'] as int;

      final chunks = <String>[];
      for (var i = 0; i < chunkCount; i++) {
        final chunkDoc = await _firestore
            .collection('users')
            .doc(uid)
            .collection('backups')
            .doc(backupId)
            .collection('chunks')
            .doc(i.toString())
            .get();
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

  // License validation
  Future<bool> validateLicense(String licenseKey) async {
    try {
      final query = await _firestore
          .collectionGroup('profile')
          .where('licenseKey', isEqualTo: licenseKey)
          .where('status', isEqualTo: SubscriptionStatus.active.toString())
          .get();

      if (query.docs.isNotEmpty) {
        final profile = UserProfile.fromJson(query.docs.first.data());
        return profile.licenseExpiry.isAfter(DateTime.now());
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Sync status tracking
  Future<void> updateLastSync(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('info')
        .update({'lastSync': FieldValue.serverTimestamp()});
  }
}
