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
  );
});

final patientsProvider = FutureProvider.family<List<Patient>, PatientFilter>((
  ref,
  filter,
) async {
  final service = ref.watch(patientServiceProvider);
  return service.getPatients(filter);
});

class PatientService {
  final PatientRepository _repository;
  final AuditService _auditService;

  PatientService(this._repository, this._auditService);

  Future<void> addPatient(Patient patient) async {
    await _repository.createPatient(patient);
    _auditService.logEvent(
      AuditAction.createPatient,
      details: 'Patient ${patient.name} ${patient.familyName} added.',
    );
  }

  Future<List<Patient>> getPatients([
    PatientFilter filter = PatientFilter.all,
  ]) async {
    return await _repository.getPatients(filter);
  }

  Future<void> updatePatient(Patient patient) async {
    await _repository.updatePatient(patient);
    _auditService.logEvent(
      AuditAction.updatePatient,
      details: 'Patient ${patient.name} ${patient.familyName} updated.',
    );
  }

  Future<void> deletePatient(int id) async {
    await _repository.deletePatient(id);
    _auditService.logEvent(
      AuditAction.deletePatient,
      details: 'Patient with ID $id deleted.',
    );
  }
}
