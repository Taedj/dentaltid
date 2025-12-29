import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/database_service.dart';
import '../data/medicine_preset_repository.dart';
import '../domain/medicine_preset.dart';

final medicinePresetServiceProvider = Provider<MedicinePresetService>((ref) {
  return MedicinePresetService(MedicinePresetRepository(DatabaseService.instance));
});

final medicinePresetsProvider = FutureProvider<List<MedicinePreset>>((ref) async {
  final service = ref.watch(medicinePresetServiceProvider);
  return await service.getAllPresets();
});

class MedicinePresetService {
  final MedicinePresetRepository _repository;

  MedicinePresetService(this._repository);

  Future<List<MedicinePreset>> getAllPresets() async {
    return await _repository.getAll();
  }

  Future<void> savePreset(MedicinePreset preset) async {
    await _repository.insert(preset);
  }

  Future<void> deletePreset(int id) async {
    await _repository.delete(id);
  }

  Future<void> updatePreset(MedicinePreset preset) async {
    await _repository.update(preset);
  }
}
