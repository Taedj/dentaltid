import 'dart:io';
import 'dart:async';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/src/features/imaging/application/imaging_service.dart';
import 'package:dentaltid/src/features/imaging/domain/nanopix_patient.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:dentaltid/src/core/clinic_usage_provider.dart';

final nanoPixSyncServiceProvider = Provider((ref) {
  return NanoPixSyncService(ref);
});

class NanoPixSyncService {
  final Ref _ref;
  final Logger _log = Logger('NanoPixSyncService');
  StreamSubscription<FileSystemEvent>? _directorySubscription;
  Timer? _pollingTimer;
  Timer? _debounceTimer;
  bool _isSyncing = false;
  Completer<void>? _currentSyncCompleter;

  NanoPixSyncService(this._ref);

  /// Starts the live synchronization if enabled in settings.
  void startLiveSync() {
    final settings = SettingsService.instance;
    final liveSyncEnabled = settings.getBool('nanopix_live_sync') ?? false;
    final nanoPixPath = settings.getString('nanopix_sync_path');

    stopLiveSync();

    if (liveSyncEnabled && nanoPixPath != null && nanoPixPath.isNotEmpty) {
      _log.info('Starting NanoPix Live Sync...');

      // Initial sync
      sync();

      // Monitor directory for new folders/files (Instant detection for images)
      try {
        final directory = Directory(nanoPixPath);
        _directorySubscription = directory.watch(recursive: true).listen((
          event,
        ) {
          // Debounce to avoid multiple rapid syncs
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(seconds: 2), () {
            _log.info(
              'NanoPix directory change detected: ${event.path}. Triggering sync.',
            );
            sync();
          });
        });
      } catch (e) {
        _log.warning(
          'Could not start directory watcher: $e. Falling back to polling.',
        );
      }

      // Polling as a fallback/safety net for database changes
      _pollingTimer = Timer.periodic(const Duration(minutes: 2), (_) => sync());
    }
  }

  void stopLiveSync() {
    _directorySubscription?.cancel();
    _directorySubscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  Future<void> sync() async {
    if (_isSyncing) {
      _log.info('Sync already in progress. Skipping concurrent request.');
      return _currentSyncCompleter?.future;
    }

    _isSyncing = true;
    _currentSyncCompleter = Completer<void>();

    try {
      _log.info('Starting NanoPix sync cycle...');
      final settings = SettingsService.instance;
      final nanoPixPath = settings.getString('nanopix_sync_path');

      if (nanoPixPath == null || nanoPixPath.isEmpty) {
        _log.warning('NanoPix sync path is not set. Aborting sync.');
        return;
      }

      // Step 1: Get patients from both databases
      final nanoPixPatients = await _readNanoPixDatabase(nanoPixPath);
      final patientService = _ref.read(patientServiceProvider);
      final dentalTidResult = await patientService.getPatients(
        pageSize: 100000,
      );
      final dentalTidPatients = dentalTidResult.patients;

      // Step 3: Identify new patients in NanoPix that aren't in DentalTID
      await _importNewNanoPixPatients(
        nanoPixPatients,
        dentalTidPatients,
        patientService,
      );

      // Step 4: Identify patients deleted in NanoPix but still in DentalTID
      await _removeDeletedNanoPixPatients(
        nanoPixPatients,
        dentalTidPatients,
        patientService,
      );

      // Refresh patients list and matched pairs after import/delete
      final updatedResult = await patientService.getPatients(pageSize: 100000);
      final updatedDentalTidPatients = updatedResult.patients;
      final updatedMatchedPairs = _matchPatients(
        updatedDentalTidPatients,
        nanoPixPatients,
      );

      // Step 5: Import images for matched patients
      await _importImagesForMatchedPatients(updatedMatchedPairs, nanoPixPath);

      _log.info('NanoPix sync cycle completed.');
    } catch (e) {
      _log.severe('An error occurred during NanoPix sync.', e);
    } finally {
      _isSyncing = false;
      _currentSyncCompleter?.complete();
      _currentSyncCompleter = null;
    }
  }

  /// Automatically creates patient records in DentalTID if found in NanoPix.
  Future<void> _importNewNanoPixPatients(
    List<NanoPixPatient> nanoPixPatients,
    List<Patient> dentalTidPatients,
    PatientService patientService,
  ) async {
    final settings = SettingsService.instance;
    final autoImportEnabled = settings.getBool('nanopix_live_sync') ?? false;
    if (!autoImportEnabled) return;

    // Check for Trial Limit enforcement
    // Check for Trial Limit enforcement
    final usage = _ref.read(clinicUsageProvider);
    var currentPatientCount = usage.patientCount;
    final isPremium = usage.isPremium;

    for (final npp in nanoPixPatients) {
      // Check if already in DentalTID by external_id or Name/DOB
      final exists = dentalTidPatients.any(
        (dtp) =>
            dtp.externalId == npp.patientId ||
            (_normalize(dtp.name) == _normalize(npp.firstName) &&
                _normalize(dtp.familyName) == _normalize(npp.lastName) &&
                _isSameDate(dtp.dateOfBirth, npp.birthDate)),
      );

      if (!exists) {
        if (!isPremium && currentPatientCount >= 100) {
          _log.warning('Trial limit reached during batch import. Stopping.');
          break;
        }

        _log.info(
          'Found new patient in NanoPix: ${npp.fullName} (ID: ${npp.patientId}). Importing...',
        );
        try {
          final dob = npp.birthDate != null && npp.birthDate!.isNotEmpty
              ? DateFormat('yyyy-MM-dd').parse(npp.birthDate!)
              : null;

          final newPatient = Patient(
            name: npp.firstName ?? 'Unknown',
            familyName: npp.lastName ?? 'Unknown',
            age: _calculateAge(dob),
            dateOfBirth: dob,
            healthState: 'Imported from NanoPix',
            diagnosis: '',
            treatment: '',
            payment: 0.0,
            createdAt: npp.createdAt ?? DateTime.now(),
            source: 'nanopix',
            externalId: npp.patientId,
          );

          await patientService.addPatient(newPatient);
          currentPatientCount++;
        } catch (e) {
          _log.severe('Failed to auto-import patient ${npp.fullName}', e);
        }
      }
    }
  }

  /// Automatically deletes patients from DentalTID if they no longer exist in NanoPix.
  Future<void> _removeDeletedNanoPixPatients(
    List<NanoPixPatient> nanoPixPatients,
    List<Patient> dentalTidPatients,
    PatientService patientService,
  ) async {
    final settings = SettingsService.instance;
    final liveSyncEnabled = settings.getBool('nanopix_live_sync') ?? false;
    if (!liveSyncEnabled) return;

    // We only delete patients that were imported from NanoPix (source == 'nanopix')
    final linkedPatients = dentalTidPatients.where(
      (p) => p.source == 'nanopix',
    );

    for (final dtp in linkedPatients) {
      final stillExistsInNanoPix = nanoPixPatients.any(
        (npp) =>
            npp.patientId == dtp.externalId ||
            (_normalize(dtp.name) == _normalize(npp.firstName) &&
                _normalize(dtp.familyName) == _normalize(npp.lastName) &&
                _isSameDate(dtp.dateOfBirth, npp.birthDate)),
      );

      if (!stillExistsInNanoPix) {
        _log.info(
          'Patient ${dtp.name} no longer found in NanoPix. Removing from DentalTID...',
        );
        try {
          if (dtp.id != null) {
            await patientService.deletePatient(dtp.id!);
          }
        } catch (e) {
          _log.severe('Failed to auto-delete patient ${dtp.name}', e);
        }
      }
    }
  }

  /// Exports a DentalTID patient to NanoPix database and creates the folder structure.
  Future<void> exportPatientToNanoPix(Patient patient) async {
    final settings = SettingsService.instance;
    final liveSyncEnabled = settings.getBool('nanopix_live_sync') ?? false;
    if (!liveSyncEnabled) return;

    final nanoPixPath = settings.getString('nanopix_sync_path');
    if (nanoPixPath == null || nanoPixPath.isEmpty) return;

    _log.info('Exporting patient ${patient.name} to NanoPix...');

    try {
      final dbPath = p.join(nanoPixPath, 'database', 'NanoPix.db3');
      final db = await databaseFactoryFfi.openDatabase(dbPath);

      // 1. Generate unique NanoPix ID if not exists
      final externalId =
          patient.externalId ??
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      // 2. Check if already exists in NanoPix
      final existing = await db.query(
        'Patient',
        where: 'id = ?',
        whereArgs: [externalId],
      );

      if (existing.isEmpty) {
        // 3. Insert into NanoPix DB
        await db.insert('Patient', {
          'id': externalId,
          'first_name': patient.name,
          'last_name': patient.familyName,
          'birthdate': patient.dateOfBirth != null
              ? DateFormat('yyyy-MM-dd').format(patient.dateOfBirth!)
              : null,
          'sex': 'Unknown',
          'created_datetime': DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(DateTime.now()),
          'updated_datetime': DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(DateTime.now()),
        });

        // 4. Create Folder
        final folderPath = p.join(nanoPixPath, externalId);
        final folder = Directory(folderPath);
        if (!await folder.exists()) {
          await folder.create(recursive: true);
          _log.info('Created NanoPix folder: $folderPath');
        }

        // 5. Update DentalTID patient with the externalId
        if (patient.externalId == null) {
          await _ref
              .read(patientServiceProvider)
              .updatePatient(patient.copyWith(externalId: externalId));
        }
      }
      await db.close();
    } catch (e) {
      _log.severe('Failed to export patient to NanoPix', e);
    }
  }

  /// Deletes a patient record and folder from NanoPix.
  Future<void> deletePatientFromNanoPix(String externalId) async {
    final settings = SettingsService.instance;
    final nanoPixPath = settings.getString('nanopix_sync_path');
    if (nanoPixPath == null || nanoPixPath.isEmpty) return;

    _log.info('Deleting patient $externalId from NanoPix...');

    try {
      // 1. Delete from DB
      final dbPath = p.join(nanoPixPath, 'database', 'NanoPix.db3');
      final db = await databaseFactoryFfi.openDatabase(dbPath);
      await db.delete('Patient', where: 'id = ?', whereArgs: [externalId]);
      await db.close();

      // 2. Delete Folder
      final folderPath = p.join(nanoPixPath, externalId);
      final folder = Directory(folderPath);
      if (await folder.exists()) {
        await folder.delete(recursive: true);
        _log.info('Deleted NanoPix folder: $folderPath');
      }
    } catch (e) {
      _log.severe('Failed to delete patient from NanoPix', e);
    }
  }

  int _calculateAge(DateTime? dob) {
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  String _normalize(String? s) => (s ?? '').trim().toLowerCase();

  bool _isSameDate(DateTime? dt, String? s) {
    if (dt == null || s == null || s.isEmpty) return false;
    try {
      final other = DateFormat('yyyy-MM-dd').parse(s);
      return dt.year == other.year &&
          dt.month == other.month &&
          dt.day == other.day;
    } catch (_) {
      return false;
    }
  }

  Future<void> _importImagesForMatchedPatients(
    Map<Patient, NanoPixPatient> matchedPairs,
    String basePath,
  ) async {
    final imagingService = _ref.read(imagingServiceProvider);
    _log.info(
      'Checking for new images in ${matchedPairs.length} matched patients...',
    );

    for (final entry in matchedPairs.entries) {
      final dentalTidPatient = entry.key;
      final nanoPixPatient = entry.value;

      if (nanoPixPatient.folderName == null) continue;

      final patientImagesPath = p.join(basePath, nanoPixPatient.folderName);
      final directory = Directory(patientImagesPath);

      if (!await directory.exists()) {
        _log.warning('Expected folder not found: $patientImagesPath');
        continue;
      }

      try {
        final List<FileSystemEntity> entities = await directory.list().toList();
        _log.fine(
          'Scanning ${entities.length} items in ${nanoPixPatient.folderName}',
        );

        for (final entity in entities) {
          if (entity is File) {
            final fileName = p.basename(entity.path).toLowerCase();

            // Support thumbnails and actual images
            final isImage =
                fileName.endsWith('.jpg') ||
                fileName.endsWith('.jpeg') ||
                fileName.endsWith('.png') ||
                fileName.endsWith('.bmp');

            if (isImage) {
              await _importSingleImage(
                file: entity,
                patient: dentalTidPatient,
                imagingService: imagingService,
                sourceTag: entity.path,
              );
            }
          }
        }
      } catch (e) {
        _log.severe('Error scanning folder for ${dentalTidPatient.name}: $e');
      }
    }
  }

  Future<void> _importSingleImage({
    required File file,
    required Patient patient,
    required ImagingService imagingService,
    required String sourceTag,
  }) async {
    final exists = await imagingService.existsBySourceTag(sourceTag);
    if (exists) return;

    try {
      _log.info(
        'Importing new image for ${patient.name} (${patient.id}): ${file.path}',
      );
      await imagingService.saveXray(
        patientId: patient.id!,
        patientName: '${patient.familyName}_${patient.name}',
        imageFile: file,
        label:
            'NanoPix Import ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
        sourceTag: sourceTag,
      );
      // Automatically refresh the gallery for this patient if it's open
      _ref.invalidate(patientXraysProvider(patient.id!));
    } catch (e) {
      _log.severe('Failed to import image ${file.path}', e);
    }
  }

  Map<Patient, NanoPixPatient> _matchPatients(
    List<Patient> dentalTidPatients,
    List<NanoPixPatient> nanoPixPatients,
  ) {
    final Map<Patient, NanoPixPatient> matches = {};

    for (final dtp in dentalTidPatients) {
      for (final npp in nanoPixPatients) {
        if (dtp.externalId == npp.patientId ||
            (_normalize(dtp.name) == _normalize(npp.firstName) &&
                _normalize(dtp.familyName) == _normalize(npp.lastName) &&
                _isSameDate(dtp.dateOfBirth, npp.birthDate))) {
          matches[dtp] = npp;
          break;
        }
      }
    }
    return matches;
  }

  Future<List<NanoPixPatient>> _readNanoPixDatabase(String basePath) async {
    final dbPath = p.join(basePath, 'database', 'NanoPix.db3');
    Database? db;
    try {
      db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      final patientData = await db.query('Patient');
      return patientData.map((map) => NanoPixPatient.fromMap(map)).toList();
    } catch (e) {
      _log.severe('Failed to read NanoPix database.', e);
      return [];
    } finally {
      await db?.close();
    }
  }
}
