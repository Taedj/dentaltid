import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditablePatientField extends ConsumerWidget {
  const EditablePatientField({
    super.key,
    required this.patient,
    required this.field,
    required this.currentValue,
    required this.onUpdate,
    required this.patientsProvider,
    required this.selectedFilter, // Re-added this
    this.isNumeric = false, // Re-added this
  });

  final Patient patient;
  final String field;
  final String currentValue;
  final Function(Patient, String) onUpdate;
  final AutoDisposeFutureProviderFamily<List<Patient>, PatientFilter>
  patientsProvider; // Changed type
  final PatientFilter selectedFilter; // Re-added this
  final bool isNumeric; // Re-added this

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    return InkWell(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                '${l10n.edit} ${field[0].toUpperCase()}${field.substring(1)}',
              ),
              content: TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: isNumeric
                    ? TextInputType.number
                    : TextInputType.text,
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(l10n.cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(l10n.save),
                  onPressed: () async {
                    await onUpdate(patient, controller.text);
                    ref.invalidate(
                      patientsProvider(selectedFilter),
                    ); // Corrected call
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
      child: Text(currentValue),
    );
  }
}
