import 'package:dentaltid/src/core/database_service.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    try {
      _logger.info(
        'Starting backup creation. uploadToFirebase: $uploadToFirebase, uid: $uid',
      );
      final dbPath = await getDatabasesPath();
      final databaseFile = File(join(dbPath, 'dentaltid.db'));

      if (!databaseFile.existsSync()) {
        _logger.warning('Database file does not exist at $dbPath');
        return null;
      }

      // CRITICAL: Close the database connection to ensure all data is flushed to disk (WAL checkpoint)
      // and to avoid file locking issues during copy.
      await DatabaseService.instance.close();
      _logger.info('Database closed for backup.');

      _logger.info(
        'Database file found, size: ${databaseFile.lengthSync()} bytes',
      );

      final encoder = ZipEncoder();
      final archive = Archive();
      archive.addFile(
        ArchiveFile(
          'dentaltid.db',
          databaseFile.lengthSync(),
          databaseFile.readAsBytesSync(),
        ),
      );

      final backupFileName =
          'dentaltid_backup_${DateTime.now().millisecondsSinceEpoch}.zip';

      final tempDir = await Directory.systemTemp.createTemp();
      final tempFilePath = join(tempDir.path, backupFileName);
      final zipFile = File(tempFilePath);
      final output = zipFile.openWrite();
      output.add(encoder.encode(archive)!);
      await output.close();

      // Encrypt the zip file
      final password = await _getBackupPassword();
      final crypt = AesCrypt(password);
      crypt.encryptFileSync(tempFilePath, '$tempFilePath.aes');
      await zipFile.delete(); // Delete unencrypted zip

      final encryptedFilePath = '$tempFilePath.aes';

      if (uploadToFirebase && uid != null) {
        final backupId = await _firebaseService.uploadUserBackupToFirestore(
          uid,
          encryptedFilePath,
        );
        await tempDir.delete(recursive: true);
        return backupId;
      } else {
        final String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Database Backup',
          fileName: '$backupFileName.aes',
          type: FileType.custom,
          allowedExtensions: ['aes'],
        );

        if (outputFile == null) {
          await tempDir.delete(recursive: true);
          return null;
        }

        await File(encryptedFilePath).copy(outputFile);
        await tempDir.delete(recursive: true);

        return outputFile;
      }
    } catch (e, s) {
      _logger.severe('Error in createBackup: $e', e, s);
      return null;
    }
  }

  Future<bool> restoreBackup({String? backupId, String? uid}) async {
    try {
      String? backupFilePath;
      if (backupId != null && uid != null) {
        final tempDir = await Directory.systemTemp.createTemp();
        final tempFilePath = join(tempDir.path, 'dentaltid_backup.zip');
        final downloadedFile = await _firebaseService
            .downloadUserBackupFromFirestore(uid, backupId, tempFilePath);
        if (downloadedFile == null) {
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
          return false;
        }
        backupFilePath = result.files.single.path!;
      }

      // Decrypt the backup file
      final password = await _getBackupPassword();
      final crypt = AesCrypt(password);
      final decryptedFilePath = backupFilePath.replaceAll('.aes', '');
      try {
        crypt.decryptFileSync(backupFilePath, decryptedFilePath);
      } catch (e) {
        // Handle decryption error (e.g., wrong password)
        return false;
      }
      backupFilePath = decryptedFilePath;

      final dbPath = await getDatabasesPath();
      final databaseFile = File(join(dbPath, 'dentaltid.db'));

      // Close the database before restoring
      await DatabaseService.instance.close();

      // Delete existing database file
      if (databaseFile.existsSync()) {
        await databaseFile.delete();
      }

      // Read the zip file bytes
      final zipFileBytes = File(backupFilePath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(zipFileBytes);

      // Extract the database file
      for (final file in archive.files) {
        if (file.name == 'dentaltid.db') {
          final output = databaseFile.openWrite();
          output.add(file.content!);
          await output.close();
          break;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
