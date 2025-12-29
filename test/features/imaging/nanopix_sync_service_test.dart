import 'dart:io';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/src/features/imaging/application/imaging_service.dart';
import 'package:dentaltid/src/features/imaging/application/nanopix_sync_service.dart';
import 'package:dentaltid/src/features/imaging/domain/xray.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// --- Mocks ---

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;

  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempPath;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return tempPath;
  }

  @override
  Future<String?> getLibraryPath() async {
    return tempPath;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return tempPath;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return tempPath;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return [tempPath];
  }

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async {
    return [tempPath];
  }

  @override
  Future<String?> getDownloadsPath() async {
    return tempPath;
  }
}

class FakePatientService extends Fake implements PatientService {
  final List<Patient> patients;
  FakePatientService(this.patients);

  @override
  Future<List<Patient>> getPatients([PatientFilter filter = PatientFilter.all]) async => patients;
}

class FakeImagingService extends Fake implements ImagingService {
  final List<String> savedTags = [];

  @override
  Future<Xray> saveXray({
    required int patientId,
    required String patientName,
    required File imageFile,
    required String label,
    int? visitId,
    String? notes,
    XrayType type = XrayType.intraoral,
    String? sourceTag,
  }) async {
    if (sourceTag != null) savedTags.add(sourceTag);
    return Xray(
      id: 1,
      patientId: patientId,
      filePath: imageFile.path,
      label: label,
      capturedAt: DateTime.now(),
      type: type,
    );
  }

  @override
  Future<bool> existsBySourceTag(String sourceTag) async {
    return savedTags.contains(sourceTag);
  }
}

void main() {
  late Directory tempDir;
  late String nanoPixPath;
  late NanoPixSyncService syncService;
  late FakeImagingService fakeImagingService;
  
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // 1. Setup Temp Directory
    tempDir = await Directory.systemTemp.createTemp('nanopix_test_');
    nanoPixPath = p.join(tempDir.path, 'NanoPixData');
    await Directory(nanoPixPath).create();

    // 2. Setup SettingsService (Path Provider Mock)
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    // Initialize settings service (it will create files in tempDir)
    await SettingsService.instance.init(force: true);
    await SettingsService.instance.setString('nanopix_sync_path', nanoPixPath);

    // 3. Create NanoPix Database
    final dbPath = p.join(nanoPixPath, 'database');
    await Directory(dbPath).create();
    final db = await databaseFactory.openDatabase(p.join(dbPath, 'NanoPix.db3'));
    
    await db.execute('''
      CREATE TABLE Patient (
        pk INTEGER PRIMARY KEY,
        id TEXT NOT NULL UNIQUE,
        last_name TEXT NOT NULL,
        first_name TEXT,
        sex TEXT,
        birthdate DATE
      )
    ''');

    await db.insert('Patient', {
      'pk': 1,
      'id': 'P001',
      'first_name': 'John',
      'last_name': 'Doe',
      'birthdate': '1980-01-01',
      'sex': 'Male'
    });
    
    await db.close();

    // 4. Create Patient Images
    // Folders are named after the 'id' (P001)
    final patientFolderPath = p.join(nanoPixPath, 'P001');
    await Directory(patientFolderPath).create();
    // Use proper path separator for checks
    final thumbPath = p.join(patientFolderPath, 'image1_thumbnail.jpg');
    await File(thumbPath).writeAsString('fake image content');
    // Create an ignored .iosb file
    await File(p.join(patientFolderPath, 'image1.iosb')).writeAsString('fake iosb content');

    // 5. Setup Riverpod Container with Fakes
    fakeImagingService = FakeImagingService();
    final patient = Patient(
      id: 1,
      name: 'John',
      familyName: 'Doe',
      age: 44,
      dateOfBirth: DateTime(1980, 1, 1),
      healthState: 'Healthy',
      diagnosis: 'None',
      treatment: 'None',
      payment: 0.0,
      createdAt: DateTime.now(),
      phoneNumber: '123',
    );

    final container = ProviderContainer(
      overrides: [
        patientServiceProvider.overrideWithValue(FakePatientService([patient])),
        imagingServiceProvider.overrideWithValue(fakeImagingService),
      ],
    );

    syncService = container.read(nanoPixSyncServiceProvider);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('Sync should match patient and import thumbnail', () async {
    await syncService.sync();

    // Verify
    expect(fakeImagingService.savedTags.length, 1);
    // On Windows paths can be tricky, check if it ends with the filename
    expect(fakeImagingService.savedTags.first.endsWith('image1_thumbnail.jpg'), isTrue);
  });
  
  test('Sync should skip if NanoPix path is invalid', () async {
    await SettingsService.instance.setString('nanopix_sync_path', '');
    await syncService.sync();
     expect(fakeImagingService.savedTags.length, 0);
  });
}