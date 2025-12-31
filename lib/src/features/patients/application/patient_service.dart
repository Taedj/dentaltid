import 'dart:async';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/exceptions.dart';
import 'package:dentaltid/src/core/network/sync_broadcaster.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/patients/data/patient_repository.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';
import 'package:dentaltid/src/features/imaging/application/nanopix_sync_service.dart';

import 'package:equatable/equatable.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(DatabaseService.instance);
});

final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService(
    ref,
    ref.watch(patientRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

class PatientListConfig extends Equatable {
  final PatientFilter filter;
  final String query;
  final int page;
  final int pageSize;

  const PatientListConfig({
    this.filter = PatientFilter.all,
    this.query = '',
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object> get props => [filter, query, page, pageSize];
}

final patientsProvider =
    AutoDisposeFutureProvider.family<PaginatedPatients, PatientListConfig>((
      ref,
      config,
    ) async {
      final service = ref.read(patientServiceProvider);

      final subscription = service.onDataChanged.listen((_) {
        ref.invalidateSelf();
      });

      // Listen to Finance changes (for totalDue)
      final financeService = ref.read(financeServiceProvider);
      final financeSub = financeService.onDataChanged.listen((_) {
        ref.invalidateSelf();
      });

      // Listen to Appointment changes (for lastVisitDate)
      final appointmentService = ref.read(appointmentServiceProvider);
      final appointmentSub = appointmentService.onDataChanged.listen((_) {
        ref.invalidateSelf();
      });

      ref.onDispose(() {
        subscription.cancel();
        financeSub.cancel();
        appointmentSub.cancel();
      });

      return service.getPatients(
        filter: config.filter,
        searchQuery: config.query,
        page: config.page,
        pageSize: config.pageSize,
      );
    });

final patientProvider = FutureProvider.family<Patient?, int>((ref, id) async {
  final service = ref.watch(patientServiceProvider);

  final subscription = service.onDataChanged.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());

  return service.getPatientById(id);
});

class PatientService {
  final PatientRepository _repository;
  final AuditService _auditService;
  final Ref _ref;

  final StreamController<void> _dataChangeController =
      StreamController.broadcast();
  Stream<void> get onDataChanged => _dataChangeController.stream;

  PatientService(this._ref, this._repository, this._auditService);

  void notifyDataChanged() {
    _dataChangeController.add(null);
  }

  void _broadcastChange(SyncAction action, Patient data) {
    _ref
        .read(syncBroadcasterProvider)
        .broadcast(table: 'patients', action: action, data: data.toJson());
  }

  Future<void> addPatient(Patient patient) async {
    try {
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

      final trimmedName = patient.name.trim();
      final trimmedFamilyName = patient.familyName.trim();

      final existingPatient = await _repository.getPatientByNameAndFamilyName(
        trimmedName,
        trimmedFamilyName,
      );
      if (existingPatient != null) {
        throw DuplicateEntryException(
          'A patient with this name and family name already exists',
          entity: 'Patient',
          duplicateValue: '$trimmedName $trimmedFamilyName',
        );
      }

      final patientToSave = patient.copyWith(
        name: trimmedName,
        familyName: trimmedFamilyName,
      );

      final newId = await _repository.createPatient(patientToSave);
      final newPatient = patientToSave.copyWith(id: newId);

      _auditService.logEvent(
        AuditAction.createPatient,
        details: 'Patient ${newPatient.name} ${newPatient.familyName} added.',
      );

      notifyDataChanged();
      _broadcastChange(SyncAction.create, newPatient);

      // Trigger NanoPix export if live sync is on
      _ref.read(nanoPixSyncServiceProvider).exportPatientToNanoPix(newPatient);
    } catch (e) {
      ErrorHandler.logError(e);
      if (e is ValidationException || e is DuplicateEntryException) rethrow;
      throw ServiceException(
        'Failed to add patient',
        service: 'PatientService',
        originalError: e,
      );
    }
  }

  Future<PaginatedPatients> getPatients({
    PatientFilter filter = PatientFilter.all,
    String? searchQuery,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      return await _repository.getPatients(
        filter: filter,
        searchQuery: searchQuery,
        page: page,
        pageSize: pageSize,
      );
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
      if (e is NotFoundException) rethrow;
      throw ServiceException(
        'Failed to retrieve patient',
        service: 'PatientService',
        originalError: e,
      );
    }
  }

  Future<void> updatePatient(Patient patient) async {
    try {
      if (patient.id == null) {
        throw ValidationException(
          'Patient ID is required for update',
          field: 'id',
        );
      }
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

      final trimmedName = patient.name.trim();
      final trimmedFamilyName = patient.familyName.trim();
      
      final patientToUpdate = patient.copyWith(
        name: trimmedName,
        familyName: trimmedFamilyName,
      );

      await _repository.updatePatient(patientToUpdate);
      _auditService.logEvent(
        AuditAction.updatePatient,
        details: 'Patient $trimmedName $trimmedFamilyName updated.',
      );

      notifyDataChanged();
      _broadcastChange(SyncAction.update, patientToUpdate);

      // Trigger NanoPix export if live sync is on
      _ref.read(nanoPixSyncServiceProvider).exportPatientToNanoPix(patientToUpdate);
    } catch (e) {
      ErrorHandler.logError(e);
      if (e is ValidationException) rethrow;
      throw ServiceException(
        'Failed to update patient',
        service: 'PatientService',
        originalError: e,
      );
    }
  }

  Future<void> deletePatient(int id) async {
    try {
      final patient = await _repository.getPatientById(id);
      if (patient == null) {
        throw NotFoundException('Patient not found', entity: 'Patient', id: id);
      }

      // 1. Get all appointments to broadcast their deletion
      final appointmentService = _ref.read(appointmentServiceProvider);
      final financeService = _ref.read(financeServiceProvider);
      final appointments = await appointmentService.getAppointmentsForPatient(
        id,
      );

      for (final appointment in appointments) {
        if (appointment.id != null) {
          // 2. Get and broadcast transaction deletions
          final transactions = await financeService.getTransactionsBySessionId(
            appointment.id!,
          );
          for (final t in transactions) {
            if (t.id != null) {
              // We call the individual delete for sync, but we could optimize this later
              await financeService.deleteTransaction(t.id!);
            }
          }
          // 3. Delete appointment (this broadcasts)
          await appointmentService.deleteAppointment(appointment.id!);
        }
      }

      // 4. Finally delete the patient
      await _repository.deletePatient(id);
      _auditService.logEvent(
        AuditAction.deletePatient,
        details: 'Patient ${patient.name} ${patient.familyName} deleted.',
      );

      notifyDataChanged();
      _broadcastChange(SyncAction.delete, patient);
    } catch (e) {
      ErrorHandler.logError(e);
      if (e is NotFoundException) rethrow;
      throw ServiceException(
        'Failed to delete patient',
        service: 'PatientService',
        originalError: e,
      );
    }
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
