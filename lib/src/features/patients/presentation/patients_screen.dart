import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
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

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Patient patient,
    String field,
    String currentValue,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '${l10n.edit} ${field[0].toUpperCase()}${field.substring(1)}',
          ),
          content: TextFormField(controller: controller, autofocus: true),
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
                final patientService = ref.read(patientServiceProvider);
                Patient updatedPatient;
                switch (field) {
                  case 'name':
                    updatedPatient = patient.copyWith(name: controller.text);
                    break;
                  case 'familyName':
                    updatedPatient = patient.copyWith(
                      familyName: controller.text,
                    );
                    break;
                  case 'age':
                    updatedPatient = patient.copyWith(
                      age: int.tryParse(controller.text) ?? patient.age,
                    );
                    break;
                  case 'healthState':
                    updatedPatient = patient.copyWith(
                      healthState: controller.text,
                    );
                    break;
                  case 'diagnosis':
                    updatedPatient = patient.copyWith(
                      diagnosis: controller.text,
                    );
                    break;
                  case 'treatment':
                    updatedPatient = patient.copyWith(
                      treatment: controller.text,
                    );
                    break;
                  case 'payment':
                    updatedPatient = patient.copyWith(
                      payment:
                          double.tryParse(controller.text) ?? patient.payment,
                    );
                    break;
                  default:
                    updatedPatient = patient;
                }
                await patientService.updatePatient(updatedPatient);
                ref.invalidate(
                  patientsProvider(_selectedFilter),
                ); // Invalidate to refresh
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
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
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(l10n.deletePatient),
                                            content: Text(
                                              l10n.confirmDeletePatient,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                                child: Text(l10n.cancel),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                                child: Text(
                                                  l10n.deletePatient.split(
                                                    ' ',
                                                  )[1],
                                                ), // Just "Patient" for the button
                                              ),
                                            ],
                                          ),
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
                                Tooltip(
                                  message: patient.healthAlerts.isNotEmpty
                                      ? patient.healthAlerts
                                      : l10n.noHealthAlerts,
                                  child: InkWell(
                                    onTap: () => _showEditDialog(
                                      context,
                                      ref,
                                      patient,
                                      'name',
                                      patient.name,
                                    ),
                                    child: Text(patient.name),
                                  ),
                                ),
                              ),
                              DataCell(
                                InkWell(
                                  onTap: () => _showEditDialog(
                                    context,
                                    ref,
                                    patient,
                                    'familyName',
                                    patient.familyName,
                                  ),
                                  child: Text(patient.familyName),
                                ),
                              ),
                              DataCell(
                                InkWell(
                                  onTap: () => _showEditDialog(
                                    context,
                                    ref,
                                    patient,
                                    'age',
                                    patient.age.toString(),
                                  ),
                                  child: Text(patient.age.toString()),
                                ),
                              ),
                              DataCell(
                                InkWell(
                                  onTap: () => _showEditDialog(
                                    context,
                                    ref,
                                    patient,
                                    'healthState',
                                    patient.healthState,
                                  ),
                                  child: Text(patient.healthState),
                                ),
                              ),
                              DataCell(
                                InkWell(
                                  onTap: () => _showEditDialog(
                                    context,
                                    ref,
                                    patient,
                                    'diagnosis',
                                    patient.diagnosis,
                                  ),
                                  child: Text(patient.diagnosis),
                                ),
                              ),
                              DataCell(
                                InkWell(
                                  onTap: () => _showEditDialog(
                                    context,
                                    ref,
                                    patient,
                                    'treatment',
                                    patient.treatment,
                                  ),
                                  child: Text(patient.treatment),
                                ),
                              ),
                              DataCell(
                                InkWell(
                                  onTap: () => _showEditDialog(
                                    context,
                                    ref,
                                    patient,
                                    'payment',
                                    patient.payment.toString(),
                                  ),
                                  child: Text(patient.payment.toString()),
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
                                            await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(l10n.deletePatient),
                                                content: Text(
                                                  l10n.confirmDeletePatient,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(false),
                                                    child: Text(l10n.cancel),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(true),
                                                    child: Text(
                                                      l10n.deletePatient.split(
                                                        ' ',
                                                      )[1],
                                                    ),
                                                  ),
                                                ],
                                              ),
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
