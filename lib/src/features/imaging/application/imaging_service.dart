import 'dart:io';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/imaging/domain/xray.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:dentaltid/src/core/settings_service.dart';

final imagingServiceProvider = Provider((ref) => ImagingService());

class ImagingService {
  final _log = Logger('ImagingService');
  static const String _defaultFolderName = 'DentalTid/Imaging';

  Future<String> _getImagingPath() async {
    final settings = SettingsService.instance;
    await settings.init();
    final customPath = settings.getString('imaging_storage_path');
    
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return customPath;
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDir.path, _defaultFolderName);
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  Future<Xray> saveXray({
    required int patientId,
    required String patientName,
    required File imageFile,
    required String label,
    int? visitId,
    String? notes,
    XrayType type = XrayType.intraoral,
  }) async {
    final baseDir = await _getImagingPath();
    final db = await DatabaseService.instance.database;

    // Calculate 'n' by counting existing records for this patient
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM xrays WHERE patientId = ?',
      [patientId],
    );
    final int n = (countResult.first['count'] as int) + 1;

    // Clean patient name: Remove only characters that are unsafe for filenames
    // Windows/Linux/Mac unsafe: < > : " / \ | ? * and control chars.
    // Arabic characters are perfectly valid path components in modern OSs.
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    final cleanName = patientName.replaceAll(invalidChars, '').replaceAll(' ', '_');
    
    final extension = p.extension(imageFile.path).isEmpty ? '.png' : p.extension(imageFile.path);
    final fileName = '${cleanName}_$n$extension';
    
    _log.info('Saving xray as $fileName for patient $patientId');
    final savedFile = await imageFile.copy(p.join(baseDir, fileName));

    final xray = Xray(
      patientId: patientId,
      visitId: visitId,
      filePath: savedFile.path,
      label: label,
      capturedAt: DateTime.now(),
      notes: notes,
      type: type,
    );

    final id = await db.insert('xrays', xray.toMap());
    
    _log.info('Saved xray $id for patient $patientId at ${savedFile.path}');
    return xray.copyWith(id: id);
  }

  Future<List<Xray>> getPatientXrays(int patientId) async {
    final db = await DatabaseService.instance.database;
    final maps = await db.query(
      'xrays',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'capturedAt DESC',
    );
    return maps.map((m) => Xray.fromMap(m)).toList();
  }

  Future<void> deleteXray(Xray xray) async {
    final db = await DatabaseService.instance.database;
    if (xray.id != null) {
      await db.delete('xrays', where: 'id = ?', whereArgs: [xray.id]);
    }
    
    final file = File(xray.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    _log.info('Deleted xray ${xray.id}');
  }

  Future<void> updateXray(Xray xray) async {
    final db = await DatabaseService.instance.database;
    if (xray.id != null) {
      await db.update(
        'xrays',
        xray.toMap(),
        where: 'id = ?',
        whereArgs: [xray.id],
      );
      _log.info('Updated xray ${xray.id}');
    }
  }
}
