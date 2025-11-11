import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/patients/data/patient_repository.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';

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

final patientsProvider = FutureProvider.family<List<Patient>, PatientFilter>((
  ref,
  filter,
) async {
  final service = ref.watch(patientServiceProvider);
  return service.getPatients(filter);
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

  Future<void> addPatient(Patient patient) async {
    final existingPatient = await _repository.getPatientByNameAndFamilyName(
      patient.name,
      patient.familyName,
    );
    if (existingPatient != null) {
      throw Exception('Patient with this name and family name already exists.');
    }
    await _repository.createPatient(patient);
    _auditService.logEvent(
      AuditAction.createPatient,
      details: 'Patient ${patient.name} ${patient.familyName} added.',
    );
    // Invalidate all patient providers to refresh the UI
    _ref.invalidate(patientsProvider(PatientFilter.all));
    _ref.invalidate(patientsProvider(PatientFilter.today));
    _ref.invalidate(patientsProvider(PatientFilter.emergency));
  }

  Future<List<Patient>> getPatients([
    PatientFilter filter = PatientFilter.all,
  ]) async {
    return await _repository.getPatients(filter);
  }

  Future<Patient?> getPatientById(int id) async {
    return await _repository.getPatientById(id);
  }

  Future<void> updatePatient(Patient patient) async {
    await _repository.updatePatient(patient);
    _auditService.logEvent(
      AuditAction.updatePatient,
      details: 'Patient ${patient.name} ${patient.familyName} updated.',
    );
    // Invalidate all patient providers to refresh the UI
    _ref.invalidate(patientsProvider(PatientFilter.all));
    _ref.invalidate(patientsProvider(PatientFilter.today));
    _ref.invalidate(patientsProvider(PatientFilter.emergency));
  }

  Future<void> deletePatient(int id) async {
    await _repository.deletePatient(id);
    _auditService.logEvent(
      AuditAction.deletePatient,
      details: 'Patient with ID $id deleted.',
    );
    // Invalidate all patient providers to refresh the UI
    _ref.invalidate(patientsProvider(PatientFilter.all));
    _ref.invalidate(patientsProvider(PatientFilter.today));
    _ref.invalidate(patientsProvider(PatientFilter.emergency));
  }
}
