import 'package:dentaltid/src/core/network/sync_broadcaster.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/database_service.dart';
import '../data/medicine_preset_repository.dart';
import '../domain/medicine_preset.dart';

final medicinePresetServiceProvider = Provider<MedicinePresetService>((ref) {
  return MedicinePresetService(
    ref,
    MedicinePresetRepository(DatabaseService.instance),
  );
});

final medicinePresetsProvider = FutureProvider<List<MedicinePreset>>((
  ref,
) async {
  final service = ref.watch(medicinePresetServiceProvider);
  return await service.getAllPresets();
});

class MedicinePresetService {
  final MedicinePresetRepository _repository;
  final Ref _ref;

  MedicinePresetService(this._ref, this._repository);

  void _broadcastChange(SyncAction action, MedicinePreset data) {
    _ref.read(syncBroadcasterProvider).broadcast(
      table: 'medicine_presets',
      action: action,
      data: data.toJson(),
    );
  }

  Future<List<MedicinePreset>> getAllPresets() async {
    return await _repository.getAll();
  }

  Future<void> savePreset(MedicinePreset preset) async {
    final id = await _repository.insert(preset);
    _broadcastChange(SyncAction.create, preset.copyWith(id: id));
  }

  Future<void> deletePreset(int id) async {
    await _repository.delete(id);
    _broadcastChange(
      SyncAction.delete,
      MedicinePreset(id: id, name: '', medicines: [], createdAt: DateTime.now()),
    );
  }

  Future<void> updatePreset(MedicinePreset preset) async {
    await _repository.update(preset);
    _broadcastChange(SyncAction.update, preset);
  }

  void notifyDataChanged() {
    _ref.invalidate(medicinePresetsProvider);
  }
}
