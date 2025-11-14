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

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key, required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${patient.name} ${patient.familyName}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Visits'),
            ],
          ),
          actions: [
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
            const Text('Blacklist'),
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
                  Text(patient.isEmergency ? "Emergency" : "Not Emergency"),
                  Text(
                    patient.isBlacklisted ? "Blacklisted" : "Not Blacklisted",
                  ),
                  if (patient.healthAlerts.isNotEmpty)
                    Text('Health Alerts: ${patient.healthAlerts}'),
                ],
              ),
            ),
            // Visits Section
            VisitsListWidget(patient: patient),
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
          return VisitCard(appointment: appointment);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class VisitCard extends ConsumerStatefulWidget {
  const VisitCard({super.key, required this.appointment});

  final Appointment appointment;

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
        );
        await financeService.addTransaction(newTransaction, invalidate: false);
      }

      ref.invalidate(patientAppointmentsProvider(widget.appointment.patientId));

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
    final colorScheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyProvider);
    final formattedDate = widget.appointment.dateTime.toLocal();
    final dateString =
        '${formattedDate.year}-${formattedDate.month.toString().padLeft(2, '0')}-${formattedDate.day.toString().padLeft(2, '0')}';
    final timeString =
        '${formattedDate.hour.toString().padLeft(2, '0')}:${formattedDate.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: false,
        backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(50),
        collapsedBackgroundColor: colorScheme.surface,
        title: Row(
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
        ),
        subtitle:
            (totalCostController.text.isNotEmpty ||
                amountPaidController.text.isNotEmpty)
            ? Text(
                balanceDue < 0
                    ? 'Overpaid: ${NumberFormat.currency(symbol: currency).format(-balanceDue)}'
                    : balanceDue > 0
                    ? 'Due: ${NumberFormat.currency(symbol: currency).format(balanceDue)}'
                    : 'Fully Paid',
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
            : null,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appointment Type Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedAppointmentType,
                  decoration: const InputDecoration(
                    labelText: 'Appointment Type',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'consultation',
                      child: Text('Consultation'),
                    ),
                    DropdownMenuItem(
                      value: 'followup',
                      child: Text('Follow-up'),
                    ),
                    DropdownMenuItem(
                      value: 'emergency',
                      child: Text('Emergency'),
                    ),
                    DropdownMenuItem(
                      value: 'procedure',
                      child: Text('Procedure'),
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
                  decoration: const InputDecoration(labelText: 'Status'),
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
                        decoration: const InputDecoration(
                          labelText: 'Total Cost',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: amountPaidController,
                        decoration: const InputDecoration(
                          labelText: 'Amount Paid',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance Due: ${NumberFormat.currency(symbol: currency).format(balanceDue)}',
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
                  decoration: const InputDecoration(labelText: 'Health State'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: diagnosisController,
                  decoration: const InputDecoration(labelText: 'Diagnosis'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: treatmentController,
                  decoration: const InputDecoration(labelText: 'Treatment'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        child: const Text('Save Changes'),
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
                        child: const Text('Delete Visit'),
                      ),
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
