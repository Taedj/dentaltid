import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:intl/intl.dart';
import 'package:dentaltid/src/features/patients/presentation/widgets/editable_patient_field.dart';
import 'package:dentaltid/src/features/patients/presentation/widgets/delete_confirmation_dialog.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'dart:ui' as ui;


// Helper for PatientFilter localization
String _getLocalizedFilterName(AppLocalizations l10n, PatientFilter filter) {
  switch (filter) {
    case PatientFilter.all: return l10n.filterAll;

    case PatientFilter.today: return l10n.filterToday;
    case PatientFilter.thisWeek: return l10n.filterThisWeek;
    case PatientFilter.thisMonth: return l10n.filterThisMonth;
    case PatientFilter.emergency: return l10n.filterEmergency;
  }
}

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key, this.filter});

  final PatientFilter? filter;

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  late PatientFilter _selectedFilter;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.filter ?? PatientFilter.all;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final patientsAsyncValue = ref.watch(
      patientsProvider(
        PatientListConfig(filter: _selectedFilter, query: _searchController.text),
      ),
    );
    final patientService = ref.watch(patientServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    final userProfile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '${l10n.name}, ${l10n.familyName} or Phone...',
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {});
                  },
                )
                : Row(
                  children: [
                    Text(l10n.patients),
                    if (userProfile != null && !userProfile.isPremium)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                           decoration: BoxDecoration(
                             color: Colors.orange.withOpacity(0.2),
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: Colors.orange),
                           ),
                           child: Text(
                             '${userProfile.cumulativePatients}/100',
                             style: const TextStyle(
                               fontSize: 14,
                               color: Colors.orange,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                        ),
                      ),
                  ],
                ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              },
            ),
          if (!_isSearching)
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
                  child: Text(_getLocalizedFilterName(l10n, value)),
                );
              }).toList(),
            ),
          if (!_isSearching)
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
          if (patients.isEmpty) {
            if (_isSearching) {
              return Center(child: Text('No patients found matching " ${_searchController.text}"'));
            }
            return Center(child: Text(l10n.noPatientsYet));
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Narrow screen: ListView of Cards
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ExpansionTile(
                        title: Text('${patient.name} ${patient.familyName}'),
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
                                if (patient.phoneNumber.isNotEmpty)
                                  Text(
                                    '${l10n.phoneNumber} ${patient.phoneNumber}',
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  'Due: ${NumberFormat.currency(
                                    symbol: ref.watch(currencyProvider),
                                  ).format(patient.totalDue)}',
                                  style: TextStyle(
                                    color: patient.totalDue > 0
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.person),
                                      tooltip: 'View Profile',
                                      onPressed: () {
                                        context.go(
                                          '/patients/profile',
                                          extra: patient,
                                        );
                                      },
                                    ),
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
                                              content:
                                                  l10n.confirmDeletePatient,
                                            );
                                        if (confirmed == true &&
                                            patient.id != null) {
                                          await patientService.deletePatient(
                                            patient.id!,
                                          );
                                          ref.invalidate(
                                            patientsProvider(
                                               PatientListConfig(filter: _selectedFilter, query: _searchController.text),
                                            ),
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
                        ? ui.TextDirection.rtl
                        : ui.TextDirection.ltr,
                    child: Align(
                      alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                      child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 80),
                        scrollDirection: Axis.horizontal,
                      child: DataTable(
                        border: TableBorder.all(color: Colors.white),
                        columns: <DataColumn>[
                          DataColumn(label: Text(l10n.patientIdHeader)),
                          DataColumn(label: Text(l10n.name)),
                          DataColumn(label: Text(l10n.familyName)),
                          DataColumn(label: Text(l10n.age)),
                          DataColumn(label: Text(l10n.healthState)),
                          DataColumn(label: Text(l10n.phoneNumber)),
                          DataColumn(label: Text(l10n.dueHeader)),
                          DataColumn(label: Text(l10n.actions)),
                        ],
                        rows: patients.asMap().entries.map((entry) {
                          final index = entry.key;
                          final patient = entry.value;
                          final config = PatientListConfig(filter: _selectedFilter, query: _searchController.text);
                          return DataRow(
                            cells: <DataCell>[
                              DataCell(Text((index + 1).toString())),
                              DataCell(
                                EditablePatientField(
                                  patient: patient,
                                  field: 'name',
                                  currentValue: patient.name,
                                  onUpdate: (p, value) async {
                                    final patientService = ref.read(
                                      patientServiceProvider,
                                    );
                                    await patientService.updatePatient(
                                      p.copyWith(name: value),
                                    );
                                  },
                                  patientsProvider: patientsProvider,
                                  config: config,
                                ),
                              ),
                              DataCell(
                                EditablePatientField(
                                  patient: patient,
                                  field: 'familyName',
                                  currentValue: patient.familyName,
                                  onUpdate: (p, value) async {
                                    final patientService = ref.read(
                                      patientServiceProvider,
                                    );
                                    await patientService.updatePatient(
                                      p.copyWith(familyName: value),
                                    );
                                  },
                                  patientsProvider: patientsProvider,
                                  config: config,
                                ),
                              ),
                              DataCell(
                                EditablePatientField(
                                  patient: patient,
                                  field: 'age',
                                  currentValue: patient.age.toString(),
                                  onUpdate: (p, value) async {
                                    final patientService = ref.read(
                                      patientServiceProvider,
                                    );
                                    await patientService.updatePatient(
                                      p.copyWith(
                                        age: int.tryParse(value) ?? p.age,
                                      ),
                                    );
                                  },
                                  patientsProvider: patientsProvider,
                                  config: config,
                                  isNumeric: true,
                                ),
                              ),
                              DataCell(
                                EditablePatientField(
                                  patient: patient,
                                  field: 'healthState',
                                  currentValue: patient.healthState,
                                  onUpdate: (p, value) async {
                                    final patientService = ref.read(
                                      patientServiceProvider,
                                    );
                                    await patientService.updatePatient(
                                      p.copyWith(healthState: value),
                                    );
                                  },
                                  patientsProvider: patientsProvider,
                                  config: config,
                                ),
                              ),
                              DataCell(
                                EditablePatientField(
                                  patient: patient,
                                  field: 'phoneNumber',
                                  currentValue: patient.phoneNumber,
                                  onUpdate: (p, value) async {
                                    final patientService = ref.read(
                                      patientServiceProvider,
                                    );
                                    await patientService.updatePatient(
                                      p.copyWith(phoneNumber: value),
                                    );
                                  },
                                  patientsProvider: patientsProvider,
                                  config: config,
                                ),
                              ),
                              DataCell(
                                Text(
                                  NumberFormat.currency(
                                    symbol: ref.watch(currencyProvider),
                                  ).format(patient.totalDue),
                                  style: TextStyle(
                                    color: patient.totalDue > 0
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.person),
                                      tooltip: 'View Profile',
                                      onPressed: () {
                                        context.go(
                                          '/patients/profile',
                                          extra: patient,
                                        );
                                      },
                                    ),
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
                                              content:
                                                  l10n.confirmDeletePatient,
                                            );
                                        if (confirmed == true &&
                                            patient.id != null) {
                                          await patientService.deletePatient(
                                            patient.id!,
                                          );
                                          ref.invalidate(
                                            patientsProvider(
                                               PatientListConfig(filter: _selectedFilter, query: _searchController.text),
                                            ),
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
