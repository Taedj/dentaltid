import 'package:dentaltid/src/features/prescriptions/application/medicine_preset_service.dart';
import 'package:dentaltid/src/features/prescriptions/domain/medicine_preset.dart';
import 'package:dentaltid/src/features/prescriptions/domain/prescription_medicine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditMedicinePresetDialog extends StatefulWidget {
  final MedicinePreset preset;

  const EditMedicinePresetDialog({super.key, required this.preset});

  @override
  State<EditMedicinePresetDialog> createState() =>
      _EditMedicinePresetDialogState();
}

class _EditMedicinePresetDialogState extends State<EditMedicinePresetDialog> {
  late TextEditingController _nameController;
  late List<PrescriptionMedicine> _medicines;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.name);
    _medicines = List.from(widget.preset.medicines);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _removeMedicine(int index) {
    setState(() {
      _medicines.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Preset'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                hintText: 'Enter preset name',
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Medicines',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _medicines.length,
                itemBuilder: (context, index) {
                  final m = _medicines[index];
                  return ListTile(
                    dense: true,
                    title: Text('${m.medicineName} (${m.quantity})'),
                    subtitle: Text('${m.frequency} - ${m.route} - ${m.time}'),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeMedicine(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Consumer(
          builder: (context, ref, _) {
            return ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isEmpty) return;

                final updatedPreset = widget.preset.copyWith(
                  name: _nameController.text,
                  medicines: _medicines,
                );

                await ref
                    .read(medicinePresetServiceProvider)
                    .updatePreset(updatedPreset);
                ref.invalidate(medicinePresetsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Changes'),
            );
          },
        ),
      ],
    );
  }
}

Future<void> showEditMedicinePresetDialog(
  BuildContext context,
  MedicinePreset preset,
) {
  return showDialog(
    context: context,
    builder: (context) => EditMedicinePresetDialog(preset: preset),
  );
}
