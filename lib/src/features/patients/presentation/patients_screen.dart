import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  PatientFilter _selectedFilter = PatientFilter.all;

  Future<void> _exportPatientsToCsv() async {
    final patientService = ref.read(patientServiceProvider);
    final patients = await patientService.getPatients(PatientFilter.all);

    List<List<dynamic>> rows = [];
    rows.add(['ID', 'Name', 'Family Name', 'Age', 'Health State', 'Diagnosis', 'Treatment', 'Payment', 'Created At']);
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
      BuildContext context, WidgetRef ref, Patient patient, String field, String currentValue) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${field[0].toUpperCase()}${field.substring(1)}'),
          content: TextFormField(
            controller: controller,
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                final patientService = ref.read(patientServiceProvider);
                Patient updatedPatient;
                switch (field) {
                  case 'name':
                    updatedPatient = patient.copyWith(name: controller.text);
                    break;
                  case 'familyName':
                    updatedPatient = patient.copyWith(familyName: controller.text);
                    break;
                  case 'age':
                    updatedPatient = patient.copyWith(age: int.tryParse(controller.text) ?? patient.age);
                    break;
                  case 'healthState':
                    updatedPatient = patient.copyWith(healthState: controller.text);
                    break;
                  case 'diagnosis':
                    updatedPatient = patient.copyWith(diagnosis: controller.text);
                    break;
                  case 'treatment':
                    updatedPatient = patient.copyWith(treatment: controller.text);
                    break;
                  case 'payment':
                    updatedPatient = patient.copyWith(payment: double.tryParse(controller.text) ?? patient.payment);
                    break;
                  default:
                    updatedPatient = patient;
                }
                await patientService.updatePatient(updatedPatient);
                ref.invalidate(patientServiceProvider);
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
    final patientService = ref.watch(patientServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: [
          DropdownButton<PatientFilter>(
            value: _selectedFilter,
            onChanged: (PatientFilter? newValue) {
              setState(() {
                _selectedFilter = newValue!;
              });
            },
            items: PatientFilter.values
                .map<DropdownMenuItem<PatientFilter>>((PatientFilter value) {
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
      body: FutureBuilder(
        future: patientService.getPatients(_selectedFilter),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No patients yet.'));
          } else {
            final patients = snapshot.data!;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                border: TableBorder.all(color: Colors.white),
                columns: const <DataColumn>[
                  DataColumn(label: Text('No.')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Family Name')),
                  DataColumn(label: Text('Age')),
                  DataColumn(label: Text('Health State')),
                  DataColumn(label: Text('Diagnosis')),
                  DataColumn(label: Text('Treatment')),
                  DataColumn(label: Text('Payment')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: patients.asMap().entries.map((entry) {
                  final index = entry.key;
                  final patient = entry.value;
                  return DataRow(
                    cells: <DataCell>[
                      DataCell(Text((index + 1).toString())),
                      DataCell(
                        InkWell(
                          onTap: () => _showEditDialog(context, ref, patient, 'name', patient.name),
                          child: Text(patient.name),
                        ),
                      ),
                      DataCell(
                        InkWell(
                          onTap: () => _showEditDialog(context, ref, patient, 'familyName', patient.familyName),
                          child: Text(patient.familyName),
                        ),
                      ),
                      DataCell(
                        InkWell(
                          onTap: () => _showEditDialog(context, ref, patient, 'age', patient.age.toString()),
                          child: Text(patient.age.toString()),
                        ),
                      ),
                      DataCell(
                        InkWell(
                          onTap: () => _showEditDialog(context, ref, patient, 'healthState', patient.healthState),
                          child: Text(patient.healthState),
                        ),
                      ),
                      DataCell(
                        InkWell(
                          onTap: () => _showEditDialog(context, ref, patient, 'diagnosis', patient.diagnosis),
                          child: Text(patient.diagnosis),
                        ),
                      ),
                      DataCell(
                        InkWell(
                          onTap: () => _showEditDialog(context, ref, patient, 'treatment', patient.treatment),
                          child: Text(patient.treatment),
                        ),
                      ),
                      DataCell(
                        InkWell(
                          onTap: () => _showEditDialog(context, ref, patient, 'payment', patient.payment.toString()),
                          child: Text(patient.payment.toString()),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                context.go('/patients/edit', extra: patient);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                if (patient.id != null) {
                                  await patientService.deletePatient(patient.id!);
                                  // Refresh the list
                                  ref.invalidate(patientServiceProvider);
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
            );
          }
        },
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
