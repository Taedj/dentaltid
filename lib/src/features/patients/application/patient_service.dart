import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/patients/data/patient_repository.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(DatabaseService.instance);
});

final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService(ref.watch(patientRepositoryProvider));
});

class PatientService {
  final PatientRepository _repository;

  PatientService(this._repository);

  Future<void> addPatient(Patient patient) async {
    await _repository.createPatient(patient);
  }

  Future<List<Patient>> getPatients([PatientFilter filter = PatientFilter.all]) async {
    return await _repository.getPatients(filter);
  }

  Future<void> updatePatient(Patient patient) async {
    await _repository.updatePatient(patient);
  }

  Future<void> deletePatient(int id) async {
    await _repository.deletePatient(id);
  }
}
