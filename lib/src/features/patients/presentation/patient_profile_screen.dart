import 'package:dentaltid/src/features/patients/application/patient_appointments_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/clinic_usage_provider.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/prescriptions/presentation/prescription_editor_screen.dart';
import 'package:dentaltid/src/features/imaging/presentation/patient_imaging_gallery.dart';

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key, required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userProfile = ref.watch(userProfileProvider).value;
    final isDentist = userProfile?.role == UserRole.dentist;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${patient.name} ${patient.familyName}'),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabInfo),
              Tab(text: l10n.tabVisits),
              Tab(text: l10n.tabImaging),
            ],
          ),
          actions: [
            if (isDentist) ...[
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.deletePatient),
                      content: Text(l10n.confirmDeletePatient),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.cancel),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    try {
                      await ref
                          .read(patientServiceProvider)
                          .deletePatient(patient.id!);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete patient: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              Switch(
                value: patient.isBlacklisted,
                onChanged: (value) {
                  // Toggle blacklist
                  final patientService = ref.read(patientServiceProvider);
                  patientService.updatePatient(
                    patient.copyWith(isBlacklisted: value),
                  );
                },
                activeThumbColor: Colors.red,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(l10n.blacklist),
              ),
            ],
          ],
        ),
        body: TabBarView(
          children: [
            // Patient Info Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.name}: ${patient.name} ${patient.familyName}'),
                  Text('${l10n.age}: ${patient.age}'),
                  Text('${l10n.phoneNumber}: ${patient.phoneNumber}'),
                  Text('${l10n.healthState}: ${patient.healthState}'),
                  Text(
                    patient.isEmergency
                        ? l10n.emergencyLabel
                        : l10n.notEmergencyLabel,
                  ),
                  Text(
                    patient.isBlacklisted
                        ? l10n.blacklistedLabel
                        : l10n.notBlacklistedLabel,
                  ),
                  if (patient.healthAlerts.isNotEmpty)
                    Text(l10n.healthAlertsLabel(patient.healthAlerts)),
                ],
              ),
            ),
            VisitsListWidget(patient: patient),
            isDentist
                ? PatientImagingGallery(patient: patient)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.accessRestricted,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.onlyDentistsImaging,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class VisitsListWidget extends ConsumerWidget {
  const VisitsListWidget({super.key, required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsyncValue = ref.watch(
      patientAppointmentsProvider(patient.id!),
    );

    return appointmentsAsyncValue.when(
      data: (appointments) => ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return VisitCard(appointment: appointment, patient: patient);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class VisitCard extends ConsumerStatefulWidget {
  const VisitCard({
    super.key,
    required this.appointment,
    required this.patient,
  });

  final Appointment appointment;
  final Patient patient;

  @override
  ConsumerState<VisitCard> createState() => _VisitCardState();
}

class _VisitCardState extends ConsumerState<VisitCard> {
  late String selectedAppointmentType;
  late AppointmentStatus selectedStatus;
  final TextEditingController totalCostController = TextEditingController();
  final TextEditingController amountPaidController = TextEditingController();
  final TextEditingController healthStateController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController treatmentController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  Transaction? existingTransaction;

  @override
  void initState() {
    super.initState();
    selectedAppointmentType = widget.appointment.appointmentType.isNotEmpty
        ? widget.appointment.appointmentType
        : 'consultation';
    selectedStatus = widget.appointment.status;
    healthStateController.text = widget.appointment.healthState;
    diagnosisController.text = widget.appointment.diagnosis;
    treatmentController.text = widget.appointment.treatment;
    notesController.text = widget.appointment.notes;

    // Load existing transaction
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    final financeService = ref.read(financeServiceProvider);
    final transactions = await financeService.getTransactionsBySessionId(
      widget.appointment.id!,
    );
    if (transactions.isNotEmpty) {
      final latest = transactions.reduce(
        (a, b) => a.date.isAfter(b.date) ? a : b,
      );
      if (mounted) {
        setState(() {
          existingTransaction = latest;
          totalCostController.text = latest.totalAmount.toString();
          amountPaidController.text = latest.paidAmount.toString();
        });
      }
    }
  }

  double get balanceDue =>
      (double.tryParse(totalCostController.text) ?? 0.0) -
      (double.tryParse(amountPaidController.text) ?? 0.0);

  @override
  void dispose() {
    totalCostController.dispose();
    amountPaidController.dispose();
    healthStateController.dispose();
    diagnosisController.dispose();
    treatmentController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final appointmentService = ref.read(appointmentServiceProvider);
    final financeService = ref.read(financeServiceProvider);
    try {
      // Save appointment changes
      final updatedAppointment = widget.appointment.copyWith(
        appointmentType: selectedAppointmentType,
        status: selectedStatus,
        healthState: healthStateController.text,
        diagnosis: diagnosisController.text,
        treatment: treatmentController.text,
        notes: notesController.text,
      );

      await appointmentService.updateAppointment(updatedAppointment);

      // Save transaction changes
      final totalCost = double.tryParse(totalCostController.text) ?? 0.0;
      final amountPaid = double.tryParse(amountPaidController.text) ?? 0.0;

      if (existingTransaction != null) {
        await financeService.updateTransaction(
          existingTransaction!.copyWith(
            totalAmount: totalCost,
            paidAmount: amountPaid,
          ),
          invalidate: false,
        );
      } else {
        final newTransaction = Transaction(
          sessionId: widget.appointment.id,
          description: 'Appointment payment',
          totalAmount: totalCost,
          paidAmount: amountPaid,
          type: TransactionType.income,
          date: DateTime.now(),
          sourceType: TransactionSourceType.appointment,
          sourceId: widget.appointment.id,
          category: selectedAppointmentType,
        );
        await financeService.addTransaction(newTransaction, invalidate: false);
      }

      ref.invalidate(patientAppointmentsProvider(widget.appointment.patientId));

      // Invalidate finance providers
      ref.invalidate(filteredTransactionsProvider);
      ref.invalidate(actualTransactionsProvider);
      ref.invalidate(dailySummaryProvider);
      ref.invalidate(weeklySummaryProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(yearlySummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit updated successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving changes: $e')));
    }
  }

  Future<void> _deleteVisit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Visit'),
        content: const Text(
          'Are you sure you want to delete this visit? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final appointmentService = ref.read(appointmentServiceProvider);
    final financeService = ref.read(financeServiceProvider);

    try {
      // Delete associated transaction if it exists
      if (existingTransaction != null) {
        await financeService.deleteTransaction(existingTransaction!.id!);
      }

      // Delete the appointment
      await appointmentService.deleteAppointment(widget.appointment.id!);

      ref.invalidate(patientAppointmentsProvider(widget.appointment.patientId));

      // Invalidate finance providers
      ref.invalidate(filteredTransactionsProvider);
      ref.invalidate(actualTransactionsProvider);
      ref.invalidate(dailySummaryProvider);
      ref.invalidate(weeklySummaryProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(yearlySummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit deleted successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting visit: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyProvider);
    final usage = ref.watch(clinicUsageProvider);
    final formattedDate = widget.appointment.dateTime.toLocal();
    final dateString =
        '${formattedDate.year}-${formattedDate.month.toString().padLeft(2, '0')}-${formattedDate.day.toString().padLeft(2, '0')}';
    final timeString =
        '${formattedDate.hour.toString().padLeft(2, '0')}:${formattedDate.minute.toString().padLeft(2, '0')}';

    final userProfile = ref.watch(userProfileProvider).value;
    final isDentist = userProfile?.role == UserRole.dentist;

    final Widget titleWidget = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Date and Time Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateString,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                timeString,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Appointment Type and Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(selectedStatus).withAlpha(100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            selectedAppointmentType,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(selectedStatus),
            ),
          ),
        ),
        // Status Badge
        Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _getAppointmentTypeColor(
              selectedAppointmentType,
            ).withAlpha(100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            selectedStatus.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getAppointmentTypeColor(selectedAppointmentType),
            ),
          ),
        ),
      ],
    );

    final Widget? subtitleWidget =
        (totalCostController.text.isNotEmpty ||
            amountPaidController.text.isNotEmpty)
        ? Text(
            balanceDue < 0
                ? l10n.overpaid(
                    NumberFormat.currency(symbol: currency).format(-balanceDue),
                  )
                : balanceDue > 0
                ? l10n.due(
                    NumberFormat.currency(symbol: currency).format(balanceDue),
                  )
                : l10n.fullyPaid,
            style: TextStyle(
              color: balanceDue < 0
                  ? Colors.green
                  : balanceDue > 0
                  ? colorScheme.error
                  : Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          )
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: isDentist
          ? ExpansionTile(
              initiallyExpanded: false,
              backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(
                50,
              ),
              collapsedBackgroundColor: colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              collapsedShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              title: titleWidget,
              subtitle: subtitleWidget,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Appointment Type Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedAppointmentType,
                        decoration: InputDecoration(
                          labelText: l10n.appointmentTypeTitle,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'consultation',
                            child: Text(l10n.consultationType),
                          ),
                          DropdownMenuItem(
                            value: 'followup',
                            child: Text(l10n.followupType),
                          ),
                          DropdownMenuItem(
                            value: 'emergency',
                            child: Text(l10n.emergencyType),
                          ),
                          DropdownMenuItem(
                            value: 'procedure',
                            child: Text(l10n.procedureType),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedAppointmentType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Status Dropdown
                      DropdownButtonFormField<AppointmentStatus>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(labelText: l10n.status),
                        items: AppointmentStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.toString().split('.').last),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                      const Divider(height: 24),
                      // Payment Fields
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: totalCostController,
                              decoration: InputDecoration(
                                labelText: l10n.totalCost,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: amountPaidController,
                              decoration: InputDecoration(
                                labelText: l10n.paidAmount,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.balanceDueLabel}: ${NumberFormat.currency(symbol: currency).format(balanceDue)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: balanceDue > 0
                              ? colorScheme.error
                              : balanceDue < 0
                              ? Colors.green
                              : Colors.green,
                        ),
                      ),
                      const Divider(height: 24),
                      // Health Fields
                      TextFormField(
                        controller: healthStateController,
                        decoration: InputDecoration(
                          labelText: l10n.healthState,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: diagnosisController,
                        decoration: InputDecoration(labelText: l10n.diagnosis),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: treatmentController,
                        decoration: InputDecoration(labelText: l10n.treatment),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        decoration: InputDecoration(labelText: l10n.notes),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              child: Text(l10n.saveButton),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (!usage.isCrown && !usage.isTrial) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('CROWN Feature'),
                                      content: const Text(
                                        'Prescriptions are only available in the CROWN plan.\nPlease upgrade to access this feature.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text(l10n.okButton),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }
                                if (userProfile != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PrescriptionEditorScreen(
                                            patient: widget.patient,
                                            userProfile: userProfile,
                                            visitId: widget.appointment.id,
                                          ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (usage.isCrown || usage.isTrial)
                                    ? colorScheme.secondaryContainer
                                    : Colors.grey.withValues(alpha: 0.2),
                                foregroundColor: (usage.isCrown || usage.isTrial)
                                    ? colorScheme.onSecondaryContainer
                                    : Colors.grey,
                              ),
                              icon: (usage.isCrown || usage.isTrial)
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.lock, size: 16),
                              label: const Text('Prescription'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _deleteVisit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(l10n.deleteVisit),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: titleWidget,
              subtitle: subtitleWidget,
              trailing: const Icon(Icons.lock_outline, size: 20),
            ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.waiting:
        return Colors.yellow;
      case AppointmentStatus.inProgress:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getAppointmentTypeColor(String type) {
    switch (type) {
      case 'consultation':
        return Colors.blue;
      case 'followup':
        return Colors.green;
      case 'emergency':
        return Colors.red;
      case 'procedure':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
