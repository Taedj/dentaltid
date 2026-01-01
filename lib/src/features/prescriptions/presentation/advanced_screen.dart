import 'package:dentaltid/src/features/prescriptions/presentation/prescription_history_view.dart';
import 'package:dentaltid/src/features/prescriptions/application/medicine_preset_service.dart';
import 'package:dentaltid/src/features/prescriptions/presentation/widgets/edit_medicine_preset_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

class AdvancedScreen extends StatefulWidget {
  const AdvancedScreen({super.key});

  @override
  State<AdvancedScreen> createState() => _AdvancedScreenState();
}

class _AdvancedScreenState extends State<AdvancedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.advanced),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.description_outlined), text: 'Prescriptions'),
            Tab(icon: Icon(Icons.bookmark_outline), text: 'Medicine Presets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PrescriptionHistoryView(),
          MedicinePresetsManagementView(),
        ],
      ),
    );
  }
}

class MedicinePresetsManagementView extends ConsumerWidget {
  const MedicinePresetsManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetsAsync = ref.watch(medicinePresetsProvider);

    return presetsAsync.when(
      data: (presets) {
        if (presets.isEmpty) {
          return const Center(child: Text('No presets saved yet.'));
        }
        return ListView.builder(
          itemCount: presets.length,
          itemBuilder: (context, index) {
            final preset = presets[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ExpansionTile(
                title: Text(
                  preset.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${preset.medicines.length} medicines'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue),
                      onPressed: () =>
                          showEditMedicinePresetDialog(context, preset),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Preset'),
                            content: Text(
                              'Are you sure you want to delete "${preset.name}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(medicinePresetServiceProvider)
                              .deletePreset(preset.id!);
                          ref.invalidate(medicinePresetsProvider);
                        }
                      },
                    ),
                  ],
                ),
                children: [
                  ...preset.medicines.map(
                    (m) => ListTile(
                      title: Text('${m.medicineName} (${m.quantity})'),
                      subtitle: Text('${m.frequency} - ${m.route} - ${m.time}'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
