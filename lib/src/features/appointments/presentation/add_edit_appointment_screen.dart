import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AddEditAppointmentScreen extends ConsumerStatefulWidget {
  const AddEditAppointmentScreen({super.key, this.appointment});

  final Appointment? appointment;

  @override
  ConsumerState<AddEditAppointmentScreen> createState() =>
      _AddEditAppointmentScreenState();
}

class _AddEditAppointmentScreenState
    extends ConsumerState<AddEditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Patient Selection
  Patient? _selectedPatient;

  // Appointment Date and Time
  DateTime _appointmentDateTime = DateTime.now();

  // Payment fields
  final TextEditingController _totalCostController = TextEditingController();
  final TextEditingController _paidController = TextEditingController();
  late TextEditingController _unpaidController;

  // Date time display controller
  late TextEditingController _dateTimeDisplayController;

  double get _totalCost => double.tryParse(_totalCostController.text) ?? 0.0;
  double get _paid => double.tryParse(_paidController.text) ?? 0.0;
  double get _unpaid => _totalCost - _paid;

  @override
  void initState() {
    super.initState();
    _dateTimeDisplayController = TextEditingController();
    _unpaidController = TextEditingController();
    _loadExistingDataIfEditing();
  }

  void _loadExistingDataIfEditing() async {
    if (widget.appointment != null) {
      try {
        // Load patient data
        final patientService = ref.read(patientServiceProvider);
        final patient = await patientService.getPatientById(
          widget.appointment!.patientId,
        );

        if (patient == null) {
          throw Exception('Patient not found');
        }

        setState(() {
          _selectedPatient = patient;
          _appointmentDateTime = widget.appointment!.dateTime;
          _dateTimeDisplayController.text = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(_appointmentDateTime);
        });
      } catch (e) {
        // Handle error loading existing data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading appointment data: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _totalCostController.dispose();
    _paidController.dispose();
    _unpaidController.dispose();
    _dateTimeDisplayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appointmentService = ref.watch(appointmentServiceProvider);
    final patientsAsyncValue = ref.watch(patientsProvider(PatientFilter.all));

    // Update unpaid controller text
    _unpaidController.text = '\$${_unpaid.toStringAsFixed(2)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.appointment == null
              ? l10n.addAppointment
              : l10n.editAppointment,
        ),
        elevation: 2,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 800;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (isWideScreen) ...[
                    // Wide screen: Organized 3-column grid layout
                    Column(
                      children: [
                        // First row: Core appointment details
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildPatientSelectionCard(
                                  l10n,
                                  patientsAsyncValue,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: _buildAppointmentDateTimeCard(l10n),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: _buildAppointmentTypeCard(l10n),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Second row: Payment and history
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildPaymentStatusCard(l10n),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: _buildLastVisitCard(l10n),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSaveButtonLarge(l10n, appointmentService),
                  ] else ...[
                    // Narrow screen: Single column layout
                    _buildPatientSelectionSection(l10n, patientsAsyncValue),
                    const SizedBox(height: 16),
                    _buildPaymentStatusCard(l10n),
                    const SizedBox(height: 16),
                    _buildAppointmentDateTimeSection(l10n),
                    const SizedBox(height: 16),
                    _buildAppointmentTypeCard(l10n),
                    const SizedBox(height: 16),
                    _buildLastVisitCard(l10n),
                    const SizedBox(height: 24),
                    _buildSaveButton(l10n, appointmentService),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientSelectionSection(
    AppLocalizations l10n,
    AsyncValue<List<Patient>> patientsAsyncValue,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.patient, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            patientsAsyncValue.when(
              data: (patients) => DropdownButtonFormField<int>(
                initialValue: _selectedPatient?.id,
                decoration: InputDecoration(
                  labelText: 'Select Patient',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                items: patients.map((patient) {
                  return DropdownMenuItem<int>(
                    value: patient.id,
                    child: Text('${patient.name} ${patient.familyName}'),
                  );
                }).toList(),
                onChanged: (patientId) => setState(
                  () => _selectedPatient = patients.firstWhere(
                    (p) => p.id == patientId,
                  ),
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text(
                '${l10n.error}: $error',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _navigateToAddPatient(),
                icon: Icon(Icons.add, color: colorScheme.primary),
                label: Text(
                  'Add New Patient',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentDateTimeSection(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Date & Time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateTimeDisplayController,
              decoration: InputDecoration(
                labelText: 'Appointment Date & Time',
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today, color: colorScheme.tertiary),
                  onPressed: () async => await _selectAppointmentDateTime(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.tertiary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              readOnly: true,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please select date and time' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n, dynamic appointmentService) {
    return Center(
      child: ElevatedButton(
        onPressed: () async => await _saveAppointment(l10n, appointmentService),
        child: Text(widget.appointment == null ? l10n.add : l10n.update),
      ),
    );
  }

  // Helper methods

  void _navigateToAddPatient() {
    GoRouter.of(context).go('/patients/add');
  }

  Future<void> _selectAppointmentDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _appointmentDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_appointmentDateTime),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _appointmentDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _dateTimeDisplayController.text = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(_appointmentDateTime);
        });
      }
    }
  }

  Future<void> _saveAppointment(
    AppLocalizations l10n,
    dynamic appointmentService,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectPatient)));
      return;
    }

    try {
      final appointment = Appointment(
        id: widget.appointment?.id,
        patientId: _selectedPatient!.id!,
        dateTime: _appointmentDateTime,
      );

      if (widget.appointment == null) {
        await appointmentService.addAppointment(appointment);
      } else {
        await appointmentService.updateAppointment(appointment);
      }

      ref.invalidate(appointmentsProvider);
      ref.invalidate(todaysAppointmentsProvider);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    }
  }

  // Desktop-style card widgets
  Widget _buildPatientSelectionCard(
    AppLocalizations l10n,
    AsyncValue<List<Patient>> patientsAsyncValue,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      decoration: _buildThemedCardDecoration(colorScheme.primary),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Patient Selection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: patientsAsyncValue.when(
                data: (patients) => DropdownButtonFormField<int>(
                  initialValue: _selectedPatient?.id,
                  decoration: InputDecoration(
                    labelText: 'Choose Patient',
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  items: patients.map((patient) {
                    return DropdownMenuItem<int>(
                      value: patient.id,
                      child: Text(
                        '${patient.name} ${patient.familyName}',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    );
                  }).toList(),
                  onChanged: (patientId) => setState(
                    () => _selectedPatient = patients.firstWhere(
                      (p) => p.id == patientId,
                    ),
                  ),
                ),
                loading: () => Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    '${l10n.error}: $error',
                    style: TextStyle(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _navigateToAddPatient(),
                icon: Icon(Icons.add, size: 18, color: colorScheme.primary),
                label: Text(
                  'Add New Patient',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentDateTimeCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      decoration: _buildThemedCardDecoration(colorScheme.tertiary),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withAlpha(
                      (255 * 0.1).round(),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Date & Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextFormField(
                controller: _dateTimeDisplayController,
                decoration: InputDecoration(
                  labelText: 'Select Date & Time',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      color: colorScheme.tertiary,
                    ),
                    onPressed: () async => await _selectAppointmentDateTime(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: colorScheme.tertiary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                readOnly: true,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please select date and time'
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentTypeCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      decoration: _buildThemedCardDecoration(colorScheme.secondary),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withAlpha(
                      (255 * 0.1).round(),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.category,
                    size: 20,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Appointment Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: 'consultation',
                decoration: InputDecoration(
                  labelText: 'Select Type',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'consultation',
                    child: Text('Consultation'),
                  ),
                  DropdownMenuItem(value: 'followup', child: Text('Follow-up')),
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
                  // Handle appointment type change
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 280,
      decoration: _buildThemedCardDecoration(colorScheme.primary),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(
                      (255 * 0.1).round(),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.payment,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Payment Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalCostController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: r'Total Cost ($)',
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: colorScheme.primary,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _paidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: r'Amount Paid ($)',
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unpaidController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Balance Due',
                labelStyle: TextStyle(
                  fontWeight: _unpaid == 0 ? FontWeight.w500 : FontWeight.bold,
                  color: _getUnpaidColor(),
                ),
                prefixIcon: Icon(
                  _unpaid == 0
                      ? Icons.balance
                      : (_unpaid > 0 ? Icons.warning : Icons.check_circle),
                  color: _unpaid == 0
                      ? colorScheme.onSurfaceVariant
                      : (_unpaid > 0
                            ? colorScheme.error
                            : colorScheme.tertiary),
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _unpaid == 0
                        ? colorScheme.outline
                        : (_unpaid > 0
                              ? colorScheme.error
                              : colorScheme.tertiary),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _unpaid == 0
                        ? colorScheme.outline
                        : (_unpaid > 0
                              ? colorScheme.error
                              : colorScheme.tertiary),
                  ),
                ),
                filled: true,
                fillColor: _unpaid == 0
                    ? colorScheme.surface
                    : colorScheme.surfaceContainerHighest.withAlpha(
                        (255 * 0.2).round(),
                      ),
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastVisitCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      decoration: _buildThemedCardDecoration(colorScheme.secondary),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withAlpha(
                      (255 * 0.1).round(),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.history,
                    size: 20,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Visit History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedPatient != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 18,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_selectedPatient!.name} ${_selectedPatient!.familyName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Last visit: ${_selectedPatient!.createdAt.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 32,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select a patient to view\nvisit history',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButtonLarge(
    AppLocalizations l10n,
    dynamic appointmentService,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SizedBox(
        width: 150, // Adjusted width
        height: 50, // Adjusted height
        child: ElevatedButton(
          onPressed: () async =>
              await _saveAppointment(l10n, appointmentService),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Add/Edit'),
        ),
      ),
    );
  }

  Color _getUnpaidColor() {
    if (_unpaid == 0) {
      return Colors.white;
    } else if (_unpaid > 0) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  BoxDecoration _buildThemedCardDecoration(Color primaryColor) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          primaryColor.withAlpha((255 * 0.05).round()),
          colorScheme.surface,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: primaryColor.withAlpha((255 * 0.2).round()),
        width: 1,
      ),
    );
  }
}
