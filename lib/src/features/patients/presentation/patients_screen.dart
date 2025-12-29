import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:intl/intl.dart';
import 'package:dentaltid/src/features/patients/presentation/widgets/editable_patient_field.dart';
import 'package:dentaltid/src/features/patients/presentation/widgets/delete_confirmation_dialog.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'dart:ui' as ui;
import 'package:dentaltid/src/core/clinic_usage_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dentaltid/src/core/app_colors.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';

// Helper for PatientFilter localization
String _getLocalizedFilterName(AppLocalizations l10n, PatientFilter filter) {
  switch (filter) {
    case PatientFilter.all:
      return l10n.filterAll;
    case PatientFilter.today:
      return l10n.filterToday;
    case PatientFilter.thisWeek:
      return l10n.filterThisWeek;
    case PatientFilter.thisMonth:
      return l10n.filterThisMonth;
    case PatientFilter.emergency:
      return l10n.filterEmergency;
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
    final l10n = AppLocalizations.of(context)!;
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
      dialogTitle: l10n.savePatientsCsvLabel,
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
        PatientListConfig(
          filter: _selectedFilter,
          query: _searchController.text,
        ),
      ),
    );
    final patientService = ref.watch(patientServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    final usage = ref.watch(clinicUsageProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final isDentist = userProfile?.role == UserRole.dentist;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '${l10n.name}, ${l10n.familyName} ${l10n.searchHintSeparator}',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).appBarTheme.titleTextStyle?.color?.withValues(alpha: 0.7),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                ),
                onChanged: (value) => setState(() {}),
              )
            : Row(
                children: [
                  Text(l10n.patients),
                  if (!usage.isPremium)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Text(
                          '${usage.patientCount}/100',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? LucideIcons.x : LucideIcons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) _searchController.clear();
                _isSearching = !_isSearching;
              });
            },
          ),
          if (!_isSearching) ...[
            DropdownButtonHideUnderline(
              child: DropdownButton<PatientFilter>(
                value: _selectedFilter,
                icon: const Icon(LucideIcons.filter),
                onChanged: (newValue) =>
                    setState(() => _selectedFilter = newValue!),
                items: PatientFilter.values.map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(_getLocalizedFilterName(l10n, value)),
                  );
                }).toList(),
              ),
            ),
            if (isDentist)
              IconButton(
                icon: const Icon(LucideIcons.download),
                onPressed: _exportPatientsToCsv,
              ),
          ],
        ],
      ),
      body: patientsAsyncValue.when(
        data: (patients) {
          if (patients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.users, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching
                        ? l10n.noPatientsFoundSearch(_searchController.text)
                        : l10n.noPatientsYet,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                // Mobile/Tablet: ListView of Modern Cards
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return _buildModernPatientCard(
                      patient,
                      l10n,
                      patientService,
                      isDentist,
                    );
                  },
                );
              } else {
                // Desktop: DataTable
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
                            headingRowColor: WidgetStateProperty.all(
                              Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                            ),
                            dataRowColor: WidgetStateProperty.all(
                              Theme.of(context).cardTheme.color,
                            ),
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.5),
                              ),
                            ),
                            columns: <DataColumn>[
                              DataColumn(
                                label: Text(
                                  l10n.patientIdHeader,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  l10n.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  l10n.familyName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  l10n.age,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  l10n.healthState,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  l10n.phoneNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  l10n.dueHeader,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  l10n.actions,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            rows: patients.asMap().entries.map((entry) {
                              final index = entry.key;
                              final patient = entry.value;
                              final config = PatientListConfig(
                                filter: _selectedFilter,
                                query: _searchController.text,
                              );

                              return DataRow(
                                cells: <DataCell>[
                                  DataCell(Text((index + 1).toString())),
                                  DataCell(
                                    EditablePatientField(
                                      patient: patient,
                                      field: 'name',
                                      currentValue: patient.name,
                                      onUpdate: (p, v) async =>
                                          await patientService.updatePatient(
                                            p.copyWith(name: v),
                                          ),
                                      patientsProvider: patientsProvider,
                                      config: config,
                                    ),
                                  ),
                                  DataCell(
                                    EditablePatientField(
                                      patient: patient,
                                      field: 'familyName',
                                      currentValue: patient.familyName,
                                      onUpdate: (p, v) async =>
                                          await patientService.updatePatient(
                                            p.copyWith(familyName: v),
                                          ),
                                      patientsProvider: patientsProvider,
                                      config: config,
                                    ),
                                  ),
                                  DataCell(
                                    EditablePatientField(
                                      patient: patient,
                                      field: 'age',
                                      currentValue: patient.age.toString(),
                                      onUpdate: (p, v) async =>
                                          await patientService.updatePatient(
                                            p.copyWith(
                                              age: int.tryParse(v) ?? p.age,
                                            ),
                                          ),
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
                                      onUpdate: (p, v) async =>
                                          await patientService.updatePatient(
                                            p.copyWith(healthState: v),
                                          ),
                                      patientsProvider: patientsProvider,
                                      config: config,
                                    ),
                                  ),
                                  DataCell(
                                    EditablePatientField(
                                      patient: patient,
                                      field: 'phoneNumber',
                                      currentValue: patient.phoneNumber,
                                      onUpdate: (p, v) async =>
                                          await patientService.updatePatient(
                                            p.copyWith(phoneNumber: v),
                                          ),
                                      patientsProvider: patientsProvider,
                                      config: config,
                                    ),
                                  ),
                                  DataCell(
                                    _buildFinancialStatus(patient.totalDue),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            LucideIcons.eye,
                                            size: 18,
                                          ),
                                          onPressed: () => context.go(
                                            '/patients/profile',
                                            extra: patient,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            LucideIcons.edit,
                                            size: 18,
                                          ),
                                          onPressed: () => context.go(
                                            '/patients/edit',
                                            extra: patient,
                                          ),
                                        ),
                                        if (isDentist)
                                          IconButton(
                                            icon: const Icon(
                                              LucideIcons.trash2,
                                              size: 18,
                                              color: Colors.red,
                                            ),
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
                                                await patientService
                                                    .deletePatient(patient.id!);
                                                ref.invalidate(
                                                  patientsProvider(config),
                                                );
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
      floatingActionButton: usage.hasReachedPatientLimit
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => context.go('/patients/add'),
              child: const Icon(LucideIcons.plus, color: Colors.white),
            ),
    );
  }

  Widget _buildModernPatientCard(
    Patient patient,
    AppLocalizations l10n,
    PatientService patientService,
    bool isDentist,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: Border.all(color: Colors.transparent),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Text(
            patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${patient.name} ${patient.familyName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${l10n.age} ${patient.age} • ${patient.phoneNumber}'),
        trailing: _buildFinancialStatus(patient.totalDue, compact: true),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.activity, size: 16),
                    const SizedBox(width: 8),
                    Text('${l10n.healthState}: ${patient.healthState}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(LucideIcons.user, size: 16),
                      label: Text(l10n.viewDetails),
                      onPressed: () =>
                          context.go('/patients/profile', extra: patient),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(LucideIcons.edit, size: 20),
                      onPressed: () =>
                          context.go('/patients/edit', extra: patient),
                    ),
                    if (isDentist)
                      IconButton(
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          final confirmed = await showDeleteConfirmationDialog(
                            context: context,
                            title: l10n.deletePatient,
                            content: l10n.confirmDeletePatient,
                          );
                          if (confirmed == true && patient.id != null) {
                            await patientService.deletePatient(patient.id!);
                            ref.invalidate(
                              patientsProvider(
                                PatientListConfig(
                                  filter: _selectedFilter,
                                  query: _searchController.text,
                                ),
                              ),
                            );
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
  }

  Widget _buildFinancialStatus(double due, {bool compact = false}) {
    final l10n = AppLocalizations.of(context)!;
    final hasDebt = due > 0;
    final color = hasDebt ? AppColors.error : AppColors.success;
    final icon = hasDebt ? LucideIcons.alertCircle : LucideIcons.checkCircle;
    final formatted = NumberFormat.compactSimpleCurrency(
      locale: Localizations.localeOf(context).languageCode,
    ).format(due);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              hasDebt ? formatted : l10n.paidStatusLabel,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      NumberFormat.currency(symbol: ref.watch(currencyProvider)).format(due),
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }
}
