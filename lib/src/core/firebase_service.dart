import 'dart:convert';
import 'package:crypto/crypto.dart';
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

  Future<void> deleteSyncedPatient(String uid, int patientId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('patients')
        .doc(patientId.toString())
        .delete();
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

  Future<void> deleteSyncedAppointment(String uid, int appointmentId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .doc(appointmentId.toString())
        .delete();
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

  Future<void> deleteSyncedTransaction(String uid, int transactionId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('finance')
        .doc(transactionId.toString())
        .delete();
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

  Future<void> deleteSyncedInventoryItem(String uid, int itemId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .doc(itemId.toString())
        .delete();
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

      // Calculate MD5 for integrity check later
      final md5Hash = md5.convert(bytes).toString();
      _logger.info(
        'File read successfully. Size: ${bytes.length} bytes, MD5: $md5Hash',
      );

      final base64String = base64Encode(bytes);
      _logger.info('Base64 encoding complete. Length: ${base64String.length}');

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

      _logger.info('Creating backup manifest with ${chunks.length} chunks');
      final backupDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('backups')
          .add({
            'timestamp': FieldValue.serverTimestamp(),
            'chunkCount': chunks.length,
            'md5Hash': md5Hash,
            'fileSize': bytes.length,
            'status': 'uploading',
          });

      _logger.info('Uploading ${chunks.length} chunks...');
      for (var i = 0; i < chunks.length; i++) {
        await backupDoc.collection('chunks').doc(i.toString()).set({
          'data': chunks[i],
        });
        if (i % 10 == 0 || i == chunks.length - 1) {
          _logger.info('Upload progress: chunk $i/${chunks.length}');
        }
      }

      // Mark as complete
      await backupDoc.update({'status': 'completed'});
      _logger.info(
        'All chunks uploaded and verified. Backup ID: ${backupDoc.id}',
      );

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
      _logger.info('Downloading backup $backupId for user $uid');
      final backupDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('backups')
          .doc(backupId)
          .get();

      if (!backupDoc.exists) {
        _logger.severe('Backup document $backupId not found.');
        return null;
      }

      final data = backupDoc.data()!;
      final chunkCount = data['chunkCount'] as int;
      final expectedMd5 = data['md5Hash'] as String?;

      _logger.info('Reassembling $chunkCount chunks...');
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

        if (!chunkDoc.exists) {
          throw Exception('Missing chunk $i for backup $backupId');
        }
        chunks.add(chunkDoc.data()!['data'] as String);

        if (i % 10 == 0 || i == chunkCount - 1) {
          _logger.info('Download progress: chunk $i/$chunkCount');
        }
      }

      final base64String = chunks.join();
      final bytes = base64Decode(base64String);

      // Verify Integrity if MD5 exists
      if (expectedMd5 != null) {
        final actualMd5 = md5.convert(bytes).toString();
        if (actualMd5 != expectedMd5) {
          _logger.severe(
            'INTEGRITY FAILURE: Expected MD5 $expectedMd5, got $actualMd5',
          );
          return null;
        }
        _logger.info('Integrity verified (MD5 match).');
      }

      final file = File(destinationPath);
      await file.writeAsBytes(bytes);
      _logger.info('Backup downloaded and reassembled at $destinationPath');

      return file;
    } catch (e, s) {
      _logger.severe('Error in downloadUserBackupFromFirestore: $e', e, s);
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

  // Managed Users (Staff) Management
  Future<void> saveManagedUser(UserProfile staffProfile) async {
    await _firestore
        .collection('users')
        .doc(staffProfile.managedByDentistId!)
        .collection('managed_users')
        .doc(staffProfile.uid)
        .set(staffProfile.toJson());
  }

  Future<List<UserProfile>> getManagedUsers(String dentistUid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(dentistUid)
        .collection('managed_users')
        .get();

    return snapshot.docs
        .map((doc) => UserProfile.fromJson(doc.data()))
        .toList();
  }

  Future<void> deleteManagedUser(String staffUid) async {
    // First, find the dentist who manages this user
    final query = await _firestore
        .collectionGroup('managed_users')
        .where('uid', isEqualTo: staffUid)
        .get();

    if (query.docs.isNotEmpty) {
      final managedUserDoc = query.docs.first;
      final dentistUid = managedUserDoc.reference.parent.parent!.id;

      await _firestore
          .collection('users')
          .doc(dentistUid)
          .collection('managed_users')
          .doc(staffUid)
          .delete();
    }
  }

  // Authenticate managed user by PIN
  Future<UserProfile?> authenticateManagedUser(
    String dentistUid,
    String username,
    String pin,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(dentistUid)
        .collection('managed_users')
        .where('username', isEqualTo: username)
        .where('pin', isEqualTo: pin)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return UserProfile.fromJson(snapshot.docs.first.data());
    }
    return null;
  }

  Future<bool> redeemActivationCode(String uid, String code) async {
    try {
      _logger.info('Attempting to redeem code: $code for user: $uid');
      final upperCode = code.toUpperCase();

      // 1. Find the code document
      final query = await _firestore
          .collection('activation_codes')
          .where('code', isEqualTo: upperCode)
          .where('isRedeemed', isEqualTo: false)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _logger.warning('Code not found or already redeemed');
        return false;
      }

      final codeDoc = query.docs.first;
      final durationMonths = codeDoc.data()['durationMonths'] as int? ?? 0;

      if (durationMonths <= 0) {
        _logger.severe('Invalid durationMonths: $durationMonths');
        return false;
      }

      // 2. Mark code as redeemed
      await codeDoc.reference.update({
        'isRedeemed': true,
        'redeemedBy': uid,
        'redeemedAt': FieldValue.serverTimestamp(),
      });

      // 3. Get User Profile
      final userParamsRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('info');

      final userDoc = await userParamsRef.get();
      if (!userDoc.exists) {
        _logger.warning('User profile not found');
        return false;
      }
      // 3. Calculate new expiry
      // If multiple codes are redeemed, stack the duration? No, usually extends from current premium expiry or now.

      DateTime currentExpiry = DateTime.now();
      final userProfile = await getUserProfile(uid);
      if (userProfile != null &&
          userProfile.isPremium &&
          userProfile.premiumExpiryDate != null) {
        // If already premium and not expired, extend from existing expiry
        if (userProfile.premiumExpiryDate!.isAfter(DateTime.now())) {
          currentExpiry = userProfile.premiumExpiryDate!;
        }
      } else {
        // Try getting current expiry from somewhere else? No, default to Now.
        // There was a logic reading 'premiumExpiryDate' from userParamsRef before, but we have userProfile now.
      }

      // Capture User Info for the Code Document
      final userEmail = userProfile?.email;
      final userPhone = userProfile?.phoneNumber;

      // 2. Mark code as redeemed (Optimistic update or Transaction?)
      // Using transaction would be safer but let's stick to simple updates for now as per codebase style
      await codeDoc.reference.update({
        'isRedeemed': true,
        'redeemedBy': uid,
        'redeemedAt': FieldValue.serverTimestamp(),
        'redeemedByEmail': userEmail,
        'redeemedByPhone': userPhone,
      });

      final newExpiry = currentExpiry.add(Duration(days: 30 * durationMonths));

      // 4. Update User Profile
      await userParamsRef.update({
        'isPremium': true,
        'plan': SubscriptionPlan.professional.toString(),
        'premiumExpiryDate': newExpiry.toIso8601String(),
        'status': SubscriptionStatus.active.toString(),
      });

      _logger.info('Account activated successfully');
      return true;
    } catch (e, s) {
      _logger.severe('Error redeeming code: $e', e, s);
      return false;
    }
  }

  // --- Usage Tracking Helpers ---

  Future<void> incrementPatientCount(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('info')
        .update({'cumulativePatients': FieldValue.increment(1)});
  }

  Future<void> incrementAppointmentCount(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('info')
        .update({'cumulativeAppointments': FieldValue.increment(1)});
  }

  Future<void> incrementInventoryCount(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('info')
        .update({'cumulativeInventory': FieldValue.increment(1)});
  }

  // --- Developer Tools ---

  Future<void> createActivationCode({
    required String code,
    required int durationMonths,
    required String type, // 'trial_extension', 'full_premium'
    String? assignedToEmail,
  }) async {
    try {
      await _firestore.collection('activation_codes').add({
        'code': code.toUpperCase(),
        'durationMonths': durationMonths,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'isRedeemed': false,
        'redeemedBy': null,
        'redeemedAt': null,
        'assignedToEmail': assignedToEmail,
      });
    } catch (e) {
      _logger.severe('Error creating activation code', e);
      throw Exception('Failed to create activation code: $e');
    }
  }

  Future<void> deleteUserBackupFromFirestore(
    String uid,
    String backupId,
  ) async {
    try {
      _logger.info('Deleting backup $backupId for user $uid');
      final backupRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('backups')
          .doc(backupId);

      // 1. Delete chunks sub-collection
      final chunks = await backupRef.collection('chunks').get();
      for (final doc in chunks.docs) {
        await doc.reference.delete();
      }

      // 2. Delete the main document
      await backupRef.delete();
      _logger.info('Backup $backupId deleted successfully.');
    } catch (e, s) {
      _logger.severe('Error in deleteUserBackupFromFirestore: $e', e, s);
      rethrow;
    }
  }
}
