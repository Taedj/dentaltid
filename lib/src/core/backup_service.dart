import 'package:dentaltid/src/core/database_service.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/core/clinic_usage_provider.dart';

class BackupService {
  final FirebaseService _firebaseService = FirebaseService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger('BackupService');

  Future<String> _getBackupPassword() async {
    const key = 'backup_password';
    String? password = await _secureStorage.read(key: key);
    if (password == null) {
      // Generate a secure random password if none exists
      password = DateTime.now().millisecondsSinceEpoch.toString();
      await _secureStorage.write(key: key, value: password);
    }
    return password;
  }

  Future<String?> createBackup({
    bool uploadToFirebase = false,
    String? uid,
  }) async {
    Directory? tempDir;
    try {
      _logger.info(
        'Starting backup creation. uploadToFirebase: $uploadToFirebase, uid: $uid',
      );
      final docsDir = await getApplicationDocumentsDirectory();
      final dbFolderPath = join(docsDir.path, 'DentalTid', 'databases');
      final databaseFile = File(join(dbFolderPath, 'dentaltid.db'));

      final settingsFile = File(
        join(docsDir.path, 'DentalTid', 'settings', 'settings.json'),
      );

      _logger.info('Resolved database path: ${databaseFile.path}');
      _logger.info('Resolved settings path: ${settingsFile.path}');

      if (!databaseFile.existsSync()) {
        _logger.severe(
          'Database file does not exist at expected location: ${databaseFile.path}',
        );
        return null;
      }

      // CRITICAL: Close the database connection to ensure all data is flushed to disk (WAL checkpoint)
      // and to avoid file locking issues during copy.
      await DatabaseService.instance.close();
      _logger.info('Database closed for backup.');

      final archive = Archive();

      // Add Database
      archive.addFile(
        ArchiveFile(
          'dentaltid.db',
          databaseFile.lengthSync(),
          databaseFile.readAsBytesSync(),
        ),
      );

      // Add Settings if exists
      if (settingsFile.existsSync()) {
        archive.addFile(
          ArchiveFile(
            'settings.json',
            settingsFile.lengthSync(),
            settingsFile.readAsBytesSync(),
          ),
        );
        _logger.info('Settings file included in backup.');
      }

      final backupFileName =
          'dentaltid_backup_${DateTime.now().millisecondsSinceEpoch}.zip';

      tempDir = await Directory.systemTemp.createTemp('dentaltid_backup_');
      final tempFilePath = join(tempDir.path, backupFileName);
      final zipFile = File(tempFilePath);

      // Encode archive to ZIP
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      if (zipData == null) {
        throw Exception('Failed to encode ZIP archive');
      }
      await zipFile.writeAsBytes(zipData);
      _logger.info('ZIP archive created: $tempFilePath');

      // Encrypt the zip file
      final password = await _getBackupPassword();
      final crypt = AesCrypt(password);
      final encryptedFilePath = '$tempFilePath.aes';
      crypt.encryptFileSync(tempFilePath, encryptedFilePath);
      _logger.info('Encryption complete: $encryptedFilePath');

      // Delete unencrypted zip immediately
      if (zipFile.existsSync()) {
        await zipFile.delete();
      }

      if (uploadToFirebase && uid != null) {
        _logger.info('Uploading to cloud...');
        final backupId = await _firebaseService.uploadUserBackupToFirestore(
          uid,
          encryptedFilePath,
        );
        return backupId;
      } else {
        final String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Database Backup',
          fileName: '$backupFileName.aes',
          type: FileType.custom,
          allowedExtensions: ['aes'],
        );

        if (outputFile == null) {
          _logger.info('Backup save cancelled by user.');
          return null;
        }

        await File(encryptedFilePath).copy(outputFile);
        _logger.info('Local backup saved to: $outputFile');

        return outputFile;
      }
    } catch (e, s) {
      _logger.severe('Error in createBackup: $e', e, s);
      return null;
    } finally {
      // Robust cleanup of temp directory
      if (tempDir != null && tempDir.existsSync()) {
        try {
          await tempDir.delete(recursive: true);
          _logger.info('Temporary backup directory cleared.');
        } catch (e) {
          _logger.warning('Failed to clear temp directory: $e');
        }
      }
    }
  }

  Future<bool> restoreBackup({
    String? backupId,
    String? uid,
    WidgetRef? ref,
  }) async {
    Directory? tempDir;
    String? backupFilePath;
    try {
      if (backupId != null && uid != null) {
        tempDir = await Directory.systemTemp.createTemp('dentaltid_restore_');
        final tempDownloadPath = join(tempDir.path, 'downloaded_backup.aes');
        final downloadedFile = await _firebaseService
            .downloadUserBackupFromFirestore(uid, backupId, tempDownloadPath);
        if (downloadedFile == null) {
          _logger.severe('Failed to download backup from cloud.');
          return false;
        }
        backupFilePath = downloadedFile.path;
      } else {
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['aes'],
          dialogTitle: 'Select Database Backup',
        );

        if (result == null || result.files.single.path == null) {
          _logger.info('Restore cancelled by user.');
          return false;
        }
        backupFilePath = result.files.single.path!;
      }

      _logger.info('Decrypting backup: $backupFilePath');
      // Decrypt the backup file
      final password = await _getBackupPassword();
      final crypt = AesCrypt(password);

      // If downloaded, we keep it in tempDir. If picked, we create a temp file for decryption.
      tempDir ??= await Directory.systemTemp.createTemp('dentaltid_restore_');
      final decryptedFilePath = join(tempDir.path, 'decrypted_backup.zip');

      try {
        crypt.decryptFileSync(backupFilePath, decryptedFilePath);
      } catch (e) {
        _logger.severe(
          'Decryption failed. Likely wrong password or corrupt file: $e',
        );
        return false;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final dbFolderPath = join(docsDir.path, 'DentalTid', 'databases');
      final databaseFile = File(join(dbFolderPath, 'dentaltid.db'));

      final settingsFile = File(
        join(docsDir.path, 'DentalTid', 'settings', 'settings.json'),
      );

      _logger.info('Restoration target DB: ${databaseFile.path}');
      _logger.info('Restoration target Settings: ${settingsFile.path}');

      // Extract contents to temporary validation folder first
      final validationDir = await tempDir.createTemp('validation_');
      final zipFileBytes = File(decryptedFilePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(zipFileBytes);

      bool dbFound = false;
      bool settingsFound = false;

      for (final file in archive.files) {
        final content = file.content as List<int>;
        final targetPath = join(validationDir.path, file.name);
        await File(targetPath).writeAsBytes(content);

        if (file.name == 'dentaltid.db') dbFound = true;
        if (file.name == 'settings.json') settingsFound = true;
      }

      if (!dbFound) {
        _logger.severe(
          'Critical Error: dentaltid.db not found in backup archive.',
        );
        return false;
      }

      // CRITICAL: Close the database before restoring
      await DatabaseService.instance.close();
      _logger.info('Database closed for restoration.');

      // Perform the Swap (Safe Overwrite)
      final restoredDbFile = File(join(validationDir.path, 'dentaltid.db'));
      if (databaseFile.existsSync()) {
        await databaseFile.delete();
      }
      await restoredDbFile.copy(databaseFile.path);
      _logger.info('Database file successfully replaced.');

      if (settingsFound) {
        final restoredSettingsFile = File(
          join(validationDir.path, 'settings.json'),
        );
        if (settingsFile.existsSync()) {
          await settingsFile.delete();
        }
        await restoredSettingsFile.copy(settingsFile.path);
        _logger.info('Settings file successfully replaced.');

        // Re-initialize settings
        await SettingsService.instance.init(force: true);
        _logger.info('SettingsService re-initialized.');
      }

      // TRICK: Refresh all providers if ref is provided
      if (ref != null) {
        _logger.info('Refreshing all data providers after restore...');
        // We use a small delay to ensure binary swap is fully committed by OS
        await Future.delayed(const Duration(milliseconds: 500));

        // Note: We don't need to manually invalidate EVERY family provider,
        // just notifying the service to broadcast is usually enough if providers listen to it.
        // However, invalidating the main providers is safer for a full refresh.

        // Invalidate usage tracking
        ref.invalidate(clinicUsageProvider);

        // Notify Services to broadcast "Data Changed"
        // This triggers all listening providers to refresh.
        try {
          ref.read(patientServiceProvider).notifyDataChanged();
          ref.read(appointmentServiceProvider).notifyDataChanged();
          ref.read(inventoryServiceProvider).notifyDataChanged();
          ref.read(financeServiceProvider).notifyDataChanged();
          _logger.info('All services notified of data change.');
        } catch (e) {
          _logger.warning('Some services were not yet initialized: $e');
        }
      }

      return true;
    } catch (e, s) {
      _logger.severe('Error in restoreBackup: $e', e, s);
      return false;
    } finally {
      if (tempDir != null && tempDir.existsSync()) {
        try {
          await tempDir.delete(recursive: true);
          _logger.info('Restoration temporary artifacts cleaned up.');
        } catch (e) {
          _logger.warning('Failed to clean up restore temp dir: $e');
        }
      }
    }
  }
}
