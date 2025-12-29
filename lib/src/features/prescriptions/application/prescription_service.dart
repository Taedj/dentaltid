import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/prescriptions/data/prescription_repository.dart';
import 'package:dentaltid/src/features/prescriptions/domain/prescription.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return PrescriptionRepository(DatabaseService.instance);
});

final prescriptionServiceProvider = Provider<PrescriptionService>((ref) {
  return PrescriptionService(
    ref,
    ref.watch(prescriptionRepositoryProvider),
  );
});

final patientPrescriptionsProvider = FutureProvider.family<List<Prescription>, int>((ref, patientId) async {
  final service = ref.read(prescriptionServiceProvider);
  return service.getPrescriptionsByPatient(patientId);
});

class PrescriptionService {
  final PrescriptionRepository _repository;
  // ignore: unused_field
  final Ref _ref;

  PrescriptionService(this._ref, this._repository);

  Future<Prescription> createPrescription(Prescription prescription) async {
    // 1. Get the last order number for this dentist
    final lastNumber = await _repository.getLastOrderNumber(prescription.dentistId);
    final nextNumber = lastNumber + 1;

    // 2. Create the prescription with the next number
    final finalPrescription = prescription.copyWith(orderNumber: nextNumber);
    final created = await _repository.createPrescription(finalPrescription);

    // 3. (Optional) Update UserProfile lastPrescriptionNumber if we want it synced/cached fast
    // This is handled by the repository being the source of truth for the local DB.

    return created;
  }

  Future<List<Prescription>> getPrescriptionsByPatient(int patientId) async {
    return await _repository.getPrescriptionsByPatient(patientId);
  }

  Future<List<Prescription>> getPrescriptionsByDentist(String dentistId) async {
    return await _repository.getPrescriptionsByDentist(dentistId);
  }

  Future<void> deletePrescription(int id) async {
    await _repository.deletePrescription(id);
  }
}
