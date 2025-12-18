import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/exceptions.dart';
import 'package:dentaltid/src/core/data_sync_service.dart';
import 'package:dentaltid/src/core/sync_manager.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/patients/data/patient_repository.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';

import 'package:equatable/equatable.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(DatabaseService.instance);
});

final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService(
    ref.watch(patientRepositoryProvider),
    ref.watch(auditServiceProvider),
    ref,
  );
});

class PatientListConfig extends Equatable {
  final PatientFilter filter;
  final String query;

  const PatientListConfig({
    this.filter = PatientFilter.all,
    this.query = '',
  });

  @override
  List<Object> get props => [filter, query];
}

final patientsProvider =
    AutoDisposeFutureProvider.family<List<Patient>, PatientListConfig>((
      ref,
      config,
    ) async {
      final service = ref.watch(patientServiceProvider);
      if (config.query.isNotEmpty) {
        return service.searchPatients(config.query);
      }
      return service.getPatients(config.filter);
    });

final patientProvider = FutureProvider.family<Patient?, int>((ref, id) async {
  final service = ref.watch(patientServiceProvider);
  return service.getPatientById(id);
});

class PatientService {
  final PatientRepository _repository;
  final AuditService _auditService;
  final Ref _ref;

  PatientService(this._repository, this._auditService, this._ref);

  Future<void> addPatient(Patient patient, {bool broadcast = true}) async {
    try {
      // Validate input
      if (patient.name.trim().isEmpty) {
        throw ValidationException(
          'Patient name cannot be empty',
          field: 'name',
        );
      }
      if (patient.familyName.trim().isEmpty) {
        throw ValidationException(
          'Patient family name cannot be empty',
          field: 'familyName',
        );
      }
      if (patient.age < 0 || patient.age > 150) {
        throw ValidationException(
          'Patient age must be between 0 and 150',
          field: 'age',
        );
      }

      final existingPatient = await _repository.getPatientByNameAndFamilyName(
        patient.name.trim(),
        patient.familyName.trim(),
      );
      if (existingPatient != null) {
        throw DuplicateEntryException(
          'A patient with this name and family name already exists',
          entity: 'Patient',
          duplicateValue: '${patient.name} ${patient.familyName}',
        );
      }

      await _repository.createPatient(patient);
      _auditService.logEvent(
        AuditAction.createPatient,
        details: 'Patient ${patient.name} ${patient.familyName} added.',
      );

      // Broadcast change to other devices on the LAN
      if (broadcast) {
        _syncLocalChange(SyncDataType.patients, 'create', patient.toJson());
      }
    } catch (e) {
      ErrorHandler.logError(e);
      if (e is ValidationException || e is DuplicateEntryException) {
        rethrow;
      }
      throw ServiceException(
        'Failed to add patient',
        service: 'PatientService',
        originalError: e,
      );
    }
  }

  Future<List<Patient>> getPatients([
    PatientFilter filter = PatientFilter.all,
  ]) async {
    try {
      return await _repository.getPatients(filter);
    } catch (e) {
      ErrorHandler.logError(e);
      throw ServiceException(
        'Failed to retrieve patients',
        service: 'PatientService',
        originalError: e,
      );
    }
  }

  Future<Patient?> getPatientById(int id) async {
    try {
      final patient = await _repository.getPatientById(id);
      if (patient == null) {
        throw NotFoundException('Patient not found', entity: 'Patient', id: id);
      }
      return patient;
    } catch (e) {
      ErrorHandler.logError(e);
      if (e is NotFoundException) {
        rethrow;
      }
      throw ServiceException(
        'Failed to retrieve patient',
        service: 'PatientService',
        originalError: e,
      );
    }
  }

  Future<void> updatePatient(Patient patient, {bool broadcast = true}) async {
    try {
      if (patient.id == null) {
        throw ValidationException(
          'Patient ID is required for update',
          field: 'id',
        );
      }

      // Validate input
      if (patient.name.trim().isEmpty) {
        throw ValidationException(
          'Patient name cannot be empty',
          field: 'name',
        );
      }
      if (patient.familyName.trim().isEmpty) {
        throw ValidationException(
          'Patient family name cannot be empty',
          field: 'familyName',
        );
      }
      if (patient.age < 0 || patient.age > 150) {
        throw ValidationException(
          'Patient age must be between 0 and 150',
          field: 'age',
        );
      }

      await _repository.updatePatient(patient);
      _auditService.logEvent(
        AuditAction.updatePatient,
        details: 'Patient ${patient.name} ${patient.familyName} updated.',
      );

      if (broadcast) {
        _syncLocalChange(SyncDataType.patients, 'update', patient.toJson());
      }
    } catch (e) {
      ErrorHandler.logError(e);
      if (e is ValidationException) {
        rethrow;
      }
      throw ServiceException(
        'Failed to update patient',
        service: 'PatientService',
        originalError: e,
      );
    }
  }

  Future<void> deletePatient(int id, {bool broadcast = true}) async {
    try {
      final patient = await _repository.getPatientById(id);
      if (patient == null) {
        throw NotFoundException('Patient not found', entity: 'Patient', id: id);
      }

      await _repository.deletePatient(id);
      _auditService.logEvent(
        AuditAction.deletePatient,
        details: 'Patient ${patient.name} ${patient.familyName} deleted.',
      );

      if (broadcast) {
        _syncLocalChange(SyncDataType.patients, 'delete', {'id': id});
      }
    } catch (e) {
      ErrorHandler.logError(e);
      if (e is NotFoundException) {
        rethrow;
      }
      throw ServiceException(
        'Failed to delete patient',
        service: 'PatientService',
        originalError: e,
      );
    }
  }

  void _syncLocalChange(SyncDataType type, String operation, Map<String, dynamic> data) {
    try {
      final userProfile = _ref.read(userProfileProvider).value;
      if (userProfile == null) return;

      final syncManager = _ref.read(syncManagerProvider);
      if (userProfile.role == UserRole.dentist) {
        syncManager.broadcastLocalChange(
          type: type,
          operation: operation,
          data: data,
        );
      } else {
        syncManager.sendToServer(
          type: type,
          operation: operation,
          data: data,
        );
      }
    } catch (_) {}
  }

  Future<List<Patient>> getBlacklistedPatients() async {
    try {
      return await _repository.getBlacklistedPatients();
    } catch (e) {
      ErrorHandler.logError(e);
      throw ServiceException(
        'Failed to retrieve blacklisted patients',
        service: 'PatientService',
        originalError: e,
      );
    }
  }

  Future<List<Patient>> searchPatients(String query) async {
    try {
      return await _repository.searchPatients(query);
    } catch (e) {
      ErrorHandler.logError(e);
      throw ServiceException(
        'Failed to search patients',
        service: 'PatientService',
        originalError: e,
      );
    }
  }

  Future<bool> isPatientBlacklisted(int id) async {
    try {
      final patient = await getPatientById(id);
      return patient?.isBlacklisted ?? false;
    } catch (e) {
      ErrorHandler.logError(e);
      return false;
    }
  }
}
