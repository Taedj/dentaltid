import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dentaltid/src/features/patients/presentation/widgets/editable_patient_field.dart';
import 'package:dentaltid/src/features/patients/presentation/widgets/delete_confirmation_dialog.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key, this.filter});

  final PatientFilter? filter;

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  late PatientFilter _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.filter ?? PatientFilter.all;
  }

  Future<void> _exportPatientsToCsv() async {
    final patientService = ref.read(patientServiceProvider);
    final patients = await patientService.getPatients(PatientFilter.all);

    List<List<dynamic>> rows = [];
    rows.add([
      'ID',
      'Name',
      'Family Name',
      'Age',
      'Health State',
      'Diagnosis',
      'Treatment',
      'Payment',
      'Created At',
    ]);
    for (var patient in patients) {
      rows.add([
        patient.id,
        patient.name,
        patient.familyName,
        patient.age,
        patient.healthState,
        patient.diagnosis,
        patient.treatment,
        patient.payment,
        patient.createdAt.toIso8601String(),
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Patients CSV',
      fileName: 'patients.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(csv);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsyncValue = ref.watch(patientsProvider(_selectedFilter));
    final patientService = ref.watch(patientServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.patients),
        actions: [
          DropdownButton<PatientFilter>(
            value: _selectedFilter,
            onChanged: (PatientFilter? newValue) {
              setState(() {
                _selectedFilter = newValue!;
              });
            },
            items: PatientFilter.values.map<DropdownMenuItem<PatientFilter>>((
              PatientFilter value,
            ) {
              return DropdownMenuItem<PatientFilter>(
                value: value,
                child: Text(value.toString().split('.').last),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              await _exportPatientsToCsv();
            },
          ),
        ],
      ),
      body: patientsAsyncValue.when(
        data: (patients) {
          patients.sort((a, b) {
            if (a.isEmergency && !b.isEmergency) {
              return -1;
            } else if (!a.isEmergency && b.isEmergency) {
              return 1;
            } else {
              return 0;
            }
          });
          if (patients.isEmpty) {
            return Center(child: Text(l10n.noPatientsYet));
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Narrow screen: ListView of Cards
                return ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return Card(
                      color: patient.isEmergency
                          ? Colors.red.withAlpha((255 * 0.1).round())
                          : null,
                      margin: const EdgeInsets.all(8.0),
                      child: ExpansionTile(
                        leading: patient.isEmergency
                            ? const Icon(Icons.warning, color: Colors.red)
                            : null,
                        title: Tooltip(
                          message: patient.healthAlerts.isNotEmpty
                              ? patient.healthAlerts
                              : l10n.noHealthAlerts,
                          child: Text('${patient.name} ${patient.familyName}'),
                        ),
                        subtitle: Text('${l10n.age} ${patient.age}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${l10n.healthState} ${patient.healthState}',
                                ),
                                Text('${l10n.diagnosis} ${patient.diagnosis}'),
                                Text('${l10n.treatment} ${patient.treatment}'),
                                Text('${l10n.payment} \$${patient.payment}'),
                                Text(
                                  '${l10n.createdAt} ${patient.createdAt.toLocal().toString().split(' ')[0]}',
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        context.go(
                                          '/patients/edit',
                                          extra: patient,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        final confirmed =
                                            await showDeleteConfirmationDialog(
                                          context: context,
                                          title: l10n.deletePatient,
                                          content: l10n.confirmDeletePatient,
                                        );
                                        if (confirmed == true &&
                                            patient.id != null) {
                                          await patientService.deletePatient(
                                            patient.id!,
                                          );
                                          ref.invalidate(
                                            patientsProvider(_selectedFilter),
                                          ); // Invalidate to refresh
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              } else {
                // Wide screen: DataTable
                final isRTL = l10n.localeName == 'ar';
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Directionality(
                    textDirection: isRTL
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        border: TableBorder.all(color: Colors.white),
                        columns: <DataColumn>[
                          DataColumn(label: Text(l10n.emergency)),
                          DataColumn(label: Text(l10n.number)),
                          DataColumn(label: Text(l10n.name)),
                          DataColumn(label: Text(l10n.familyName)),
                          DataColumn(label: Text(l10n.age)),
                          DataColumn(label: Text(l10n.healthState)),
                          DataColumn(label: Text(l10n.diagnosis)),
                          DataColumn(label: Text(l10n.treatment)),
                          DataColumn(label: Text(l10n.payment)),
                          DataColumn(label: Text(l10n.actions)),
                        ],
                        rows: patients.asMap().entries.map((entry) {
                          final index = entry.key;
                          final patient = entry.value;
                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>((
                              Set<WidgetState> states,
                            ) {
                              if (patient.isEmergency) {
                                return Colors.red.withAlpha(
                                  (255 * 0.2).round(),
                                );
                              }
                              return null; // Use the default color.
                            }),
                            cells: <DataCell>[
                              DataCell(
                                patient.isEmergency
                                    ? const Icon(
                                        Icons.warning,
                                        color: Colors.red,
                                      )
                                    : const SizedBox(),
                              ),
                              DataCell(Text((index + 1).toString())),
                              DataCell(
                                EditablePatientField(
                                  patient: patient,
                                  field: 'name',
                                  currentValue: patient.name,
                                  onUpdate: (p, value) async {
                                    final patientService =
                                        ref.read(patientServiceProvider);
                                    await patientService
                                        .updatePatient(p.copyWith(name: value));
                                  },
                                  patientsProvider: patientsProvider,
                                  selectedFilter: _selectedFilter,
                                ),
                              ),
                              DataCell(
                                EditablePatientField(
                                  patient: patient,
                                  field: 'familyName',
                                  currentValue: patient.familyName,
                                  onUpdate: (p, value) async {
                                    final patientService =
                                        ref.read(patientServiceProvider);
                                    await patientService.updatePatient(
                                        p.copyWith(familyName: value));
                                  },
                                  patientsProvider: patientsProvider,
                                  selectedFilter: _selectedFilter,
                                ),
                              ),
                              DataCell(
                                EditablePatientField(
                                  patient: patient,
                                  field: 'age',
                                  currentValue: patient.age.toString(),
                                  onUpdate: (p, value) async {
                                    final patientService =
                                        ref.read(patientServiceProvider);
                                    await patientService.updatePatient(
                                        p.copyWith(
                                            age: int.tryParse(value) ?? p.age));
                                  },
                                  patientsProvider: patientsProvider,
                                  selectedFilter: _selectedFilter,
                                  isNumeric: true,
                                ),
                              ),
                              DataCell(
                                EditablePatientField(
                                  patient: patient,
                                  field: 'healthState',
                                  currentValue: patient.healthState,
                                  onUpdate: (p, value) async {
                                    final patientService =
                                        ref.read(patientServiceProvider);
                                    await patientService.updatePatient(
                                        p.copyWith(healthState: value));
                                  },
                                  patientsProvider: patientsProvider,
                                  selectedFilter: _selectedFilter,
                                ),
                              ),
                              DataCell(
                                EditablePatientField(
                                  patient: patient,
                                  field: 'diagnosis',
                                  currentValue: patient.diagnosis,
                                  onUpdate: (p, value) async {
                                    final patientService =
                                        ref.read(patientServiceProvider);
                                    await patientService.updatePatient(
                                        p.copyWith(diagnosis: value));
                                  },
                                  patientsProvider: patientsProvider,
                                  selectedFilter: _selectedFilter,
                                ),
                              ),
                              DataCell(
                                EditablePatientField(
                                  patient: patient,
                                  field: 'treatment',
                                  currentValue: patient.treatment,
                                  onUpdate: (p, value) async {
                                    final patientService =
                                        ref.read(patientServiceProvider);
                                    await patientService.updatePatient(
                                        p.copyWith(treatment: value));
                                  },
                                  patientsProvider: patientsProvider,
                                  selectedFilter: _selectedFilter,
                                ),
                              ),
                              DataCell(
                                EditablePatientField(
                                  patient: patient,
                                  field: 'payment',
                                  currentValue: patient.payment.toString(),
                                  onUpdate: (p, value) async {
                                    final patientService =
                                        ref.read(patientServiceProvider);
                                    await patientService.updatePatient(
                                        p.copyWith(
                                            payment: double.tryParse(value) ??
                                                p.payment));
                                  },
                                  patientsProvider: patientsProvider,
                                  selectedFilter: _selectedFilter,
                                  isNumeric: true,
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        context.go(
                                          '/patients/edit',
                                          extra: patient,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        final confirmed =
                                            await showDeleteConfirmationDialog(
                                          context: context,
                                          title: l10n.deletePatient,
                                          content: l10n.confirmDeletePatient,
                                        );
                                        if (confirmed == true &&
                                            patient.id != null) {
                                          await patientService.deletePatient(
                                            patient.id!,
                                          );
                                          ref.invalidate(
                                            patientsProvider(_selectedFilter),
                                          ); // Invalidate to refresh
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/patients/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
