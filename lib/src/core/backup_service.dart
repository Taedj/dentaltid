import 'package:dentaltid/src/core/database_service.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';

class BackupService {
  final FirebaseService _firebaseService = FirebaseService();
  // TODO: Use a secure storage solution for the backup password
  final String _backupPassword = '72603991';

  Future<String?> createBackup({bool uploadToFirebase = false}) async {
    try {
      final dbPath = await getDatabasesPath();
      final databaseFile = File(join(dbPath, 'dentaltid.db'));

      if (!databaseFile.existsSync()) {
        return null;
      }

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
          'dentaltid_backup_$DateTime.now().millisecondsSinceEpoch.zip';

      final tempDir = await Directory.systemTemp.createTemp();
      final tempFilePath = join(tempDir.path, backupFileName);
      final zipFile = File(tempFilePath);
      final output = zipFile.openWrite();
      output.writeAll(encoder.encode(archive));
      await output.close();

      // Encrypt the zip file
      final crypt = AesCrypt(_backupPassword);
      crypt.encryptFileSync(tempFilePath, '$tempFilePath.aes');
      await zipFile.delete(); // Delete unencrypted zip

      final encryptedFilePath = '$tempFilePath.aes';

      if (uploadToFirebase) {
        final backupId = await _firebaseService.uploadBackupToFirestore(
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
    } catch (e) {
      return null;
    }
  }

  Future<bool> restoreBackup({String? backupId}) async {
    try {
      String? backupFilePath;
      if (backupId != null) {
        final tempDir = await Directory.systemTemp.createTemp();
        final tempFilePath = join(tempDir.path, 'dentaltid_backup.zip');
        final downloadedFile = await _firebaseService
            .downloadBackupFromFirestore(backupId, tempFilePath);
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
      final crypt = AesCrypt(_backupPassword);
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
          output.writeAll(file.content as List<int>);
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
