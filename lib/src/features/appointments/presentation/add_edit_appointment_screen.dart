import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:dentaltid/src/features/visits/application/visit_service.dart';
import 'package:dentaltid/src/features/visits/domain/visit.dart';
import 'package:dentaltid/src/features/sessions/application/session_service.dart';
import 'package:dentaltid/src/features/sessions/domain/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

class SessionFormData {
  int sessionNumber;
  DateTime dateTime;
  TextEditingController treatmentDetailsController;
  TextEditingController notesController;
  TextEditingController totalAmountController;
  TextEditingController paidAmountController;

  SessionFormData({
    required this.sessionNumber,
    required this.dateTime,
    required this.treatmentDetailsController,
    required this.notesController,
    required this.totalAmountController,
    required this.paidAmountController,
  });
}

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
  final TextEditingController _patientSearchController =
      TextEditingController();
  List<Patient> _filteredPatients = [];
  bool _showCurrentDayPatients = false;

  // Visit Details
  bool _createNewVisit = true;
  Visit? _selectedVisit;
  final TextEditingController _reasonForVisitController =
      TextEditingController();
  final TextEditingController _visitNotesController = TextEditingController();
  bool _isEmergency = false;
  EmergencySeverity _emergencySeverity = EmergencySeverity.low;
  final TextEditingController _healthAlertsController = TextEditingController();

  // Session Details
  int _numberOfSessions = 1;
  List<SessionFormData> _sessions = [];

  // Patient Notes & Blacklist
  final TextEditingController _patientNotesController = TextEditingController();
  bool _isBlacklisted = false;

  @override
  void initState() {
    super.initState();
    _initializeSessions();
    _loadExistingDataIfEditing();
  }

  void _initializeSessions() {
    _sessions = List.generate(
      _numberOfSessions,
      (index) => SessionFormData(
        sessionNumber: index + 1,
        dateTime: DateTime.now().add(Duration(days: index)),
        treatmentDetailsController: TextEditingController(),
        notesController: TextEditingController(),
        totalAmountController: TextEditingController(text: '0.0'),
        paidAmountController: TextEditingController(text: '0.0'),
      ),
    );
  }

  void _loadExistingDataIfEditing() async {
    if (widget.appointment != null) {
      try {
        // Load existing appointment data
        final sessionService = ref.read(sessionServiceProvider);
        final session = await sessionService.getSessionById(
          widget.appointment!.sessionId,
        );

        if (session == null) {
          throw Exception('Session not found');
        }

        // Load visit data
        final visitService = ref.read(visitServiceProvider);
        final visit = await visitService.getVisitById(session.visitId);

        if (visit == null) {
          throw Exception('Visit not found');
        }

        // Load patient data
        final patientService = ref.read(patientServiceProvider);
        final patient = await patientService.getPatientById(visit.patientId);

        if (patient == null) {
          throw Exception('Patient not found');
        }

        setState(() {
          _selectedPatient = patient;
          _selectedVisit = visit;
          _createNewVisit = false; // We're editing an existing appointment
        });

        // Pre-populate form fields with existing data
        _reasonForVisitController.text = visit.reasonForVisit;
        _visitNotesController.text = visit.notes;
        _isEmergency = visit.isEmergency;
        _emergencySeverity = visit.emergencySeverity;
        _healthAlertsController.text = visit.healthAlerts;

        // Load session data
        final sessions = await sessionService.getSessionsByVisitId(visit.id!);
        if (sessions.isNotEmpty) {
          setState(() {
            _numberOfSessions = sessions.length;
            _sessions = sessions
                .map(
                  (session) => SessionFormData(
                    sessionNumber: session.sessionNumber,
                    dateTime: session.dateTime,
                    treatmentDetailsController: TextEditingController(
                      text: session.treatmentDetails,
                    ),
                    notesController: TextEditingController(text: session.notes),
                    totalAmountController: TextEditingController(
                      text: session.totalAmount.toString(),
                    ),
                    paidAmountController: TextEditingController(
                      text: session.paidAmount.toString(),
                    ),
                  ),
                )
                .toList();
          });
        }
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
    _patientSearchController.dispose();
    _reasonForVisitController.dispose();
    _visitNotesController.dispose();
    _healthAlertsController.dispose();
    _patientNotesController.dispose();
    for (final session in _sessions) {
      session.treatmentDetailsController.dispose();
      session.notesController.dispose();
      session.totalAmountController.dispose();
      session.paidAmountController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appointmentService = ref.watch(appointmentServiceProvider);
    final patientsAsyncValue = ref.watch(patientsProvider(PatientFilter.all));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.appointment == null
              ? l10n.addAppointment
              : l10n.editAppointment,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildPatientSelectionSection(l10n, patientsAsyncValue),
              const SizedBox(height: 24),
              _buildVisitDetailsSection(l10n),
              const SizedBox(height: 24),
              _buildSessionDetailsSection(l10n),
              const SizedBox(height: 24),
              _buildPatientNotesSection(l10n),
              const SizedBox(height: 24),
              _buildSaveButton(l10n, appointmentService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSelectionSection(
    AppLocalizations l10n,
    AsyncValue<List<Patient>> patientsAsyncValue,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.patient, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _patientSearchController,
              decoration: InputDecoration(
                labelText: l10n.searchPatient,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _navigateToAddPatient(),
                ),
              ),
              onChanged: (value) => _filterPatients(value, patientsAsyncValue),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _showCurrentDayPatients,
                  onChanged: (value) =>
                      setState(() => _showCurrentDayPatients = value ?? false),
                ),
                Text(l10n.showCurrentDayPatients),
              ],
            ),
            const SizedBox(height: 16),
            patientsAsyncValue.when(
              data: (patients) {
                final displayPatients = _showCurrentDayPatients
                    ? patients.where((p) => _isCurrentDayPatient(p)).toList()
                    : _filteredPatients.isNotEmpty
                    ? _filteredPatients
                    : patients;

                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: displayPatients.length,
                    itemBuilder: (context, index) {
                      final patient = displayPatients[index];
                      final hasPreviousVisits = _hasPreviousVisits(patient);
                      return ListTile(
                        title: Text('${patient.name} ${patient.familyName}'),
                        subtitle: Text('${l10n.age}: ${patient.age}'),
                        trailing: hasPreviousVisits
                            ? const Icon(Icons.history)
                            : null,
                        selected: _selectedPatient?.id == patient.id,
                        onTap: () => setState(() => _selectedPatient = patient),
                      );
                    },
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('${l10n.error}: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitDetailsSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.visitDetails,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                RadioMenuButton<bool>(
                  value: true,
                  groupValue: _createNewVisit,
                  onChanged: (value) =>
                      setState(() => _createNewVisit = value ?? true),
                  child: Text(l10n.createNewVisit),
                ),
                RadioMenuButton<bool>(
                  value: false,
                  groupValue: _createNewVisit,
                  onChanged: (value) =>
                      setState(() => _createNewVisit = value ?? true),
                  child: Text(l10n.selectExistingVisit),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_createNewVisit) ...[
              TextFormField(
                controller: _reasonForVisitController,
                decoration: InputDecoration(labelText: l10n.reasonForVisit),
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.requiredField : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _visitNotesController,
                decoration: InputDecoration(labelText: l10n.notes),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.emergency,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              CheckboxListTile(
                title: Text(l10n.isEmergency),
                value: _isEmergency,
                onChanged: (value) =>
                    setState(() => _isEmergency = value ?? false),
              ),
              if (_isEmergency) ...[
                DropdownButtonFormField<EmergencySeverity>(
                  initialValue: _emergencySeverity,
                  decoration: InputDecoration(
                    labelText: l10n.emergencySeverity,
                  ),
                  items: EmergencySeverity.values.map((severity) {
                    return DropdownMenuItem(
                      value: severity,
                      child: Text(severity.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _emergencySeverity = value!),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _healthAlertsController,
                  decoration: InputDecoration(labelText: l10n.healthAlerts),
                  maxLines: 2,
                ),
              ],
            ] else ...[
              if (_selectedPatient != null) ...[
                FutureBuilder<List<Visit>>(
                  future: ref
                      .watch(visitServiceProvider)
                      .getVisitsByPatientId(_selectedPatient!.id!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final visits = snapshot.data ?? [];
                    if (visits.isEmpty) {
                      return const Text('No existing visits for this patient');
                    }
                    return DropdownButtonFormField<Visit>(
                      initialValue: visits.cast<Visit?>().firstWhere(
                        (visit) => visit?.id == _selectedVisit?.id,
                        orElse: () => null,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.selectExistingVisit,
                      ),
                      items: visits.map((visit) {
                        return DropdownMenuItem<Visit>(
                          value: visit,
                          child: Text(
                            'Visit ${visit.visitNumber} - ${visit.dateTime.toLocal().toString().split(' ')[0]}',
                          ),
                        );
                      }).toList(),
                      onChanged: (Visit? newValue) {
                        setState(() {
                          _selectedVisit = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? l10n.requiredField : null,
                    );
                  },
                ),
              ] else ...[
                const Text('Please select a patient first'),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDetailsSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sessionDetails,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: TextEditingController(
                text: _numberOfSessions.toString(),
              ),
              decoration: InputDecoration(labelText: l10n.numberOfSessions),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final count = int.tryParse(value) ?? 1;
                setState(() {
                  _numberOfSessions = count;
                  _updateSessionsCount();
                });
              },
            ),
            const SizedBox(height: 16),
            ..._sessions.map((session) => _buildSessionForm(session, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionForm(SessionFormData session, AppLocalizations l10n) {
    final totalAmount =
        double.tryParse(session.totalAmountController.text) ?? 0.0;
    final paidAmount =
        double.tryParse(session.paidAmountController.text) ?? 0.0;
    final unpaidAmount = totalAmount - paidAmount;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.session} ${session.sessionNumber}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: TextEditingController(
                text: session.dateTime.toIso8601String(),
              ),
              decoration: InputDecoration(
                labelText: l10n.dateTime,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async => await _selectDateTime(session),
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            Text(l10n.payment, style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: session.totalAmountController,
                    decoration: InputDecoration(labelText: l10n.totalAmount),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: session.paidAmountController,
                    decoration: InputDecoration(labelText: l10n.paidAmount),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: unpaidAmount > 0
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: unpaidAmount > 0
                      ? Colors.red.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unpaid:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: unpaidAmount > 0
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                  Text(
                    unpaidAmount >= 0
                        ? unpaidAmount.toStringAsFixed(2)
                        : '0.00',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: unpaidAmount > 0
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientNotesSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.patientNotes,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _patientNotesController,
              decoration: InputDecoration(labelText: l10n.notes),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: Text(l10n.blacklistPatient),
              value: _isBlacklisted,
              onChanged: (value) =>
                  setState(() => _isBlacklisted = value ?? false),
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
  void _filterPatients(
    String query,
    AsyncValue<List<Patient>> patientsAsyncValue,
  ) {
    patientsAsyncValue.maybeWhen(
      data: (patients) {
        setState(() {
          _filteredPatients = patients.where((patient) {
            final fullName = '${patient.name} ${patient.familyName}'
                .toLowerCase();
            return fullName.contains(query.toLowerCase());
          }).toList();
        });
      },
      orElse: () {},
    );
  }

  bool _isCurrentDayPatient(Patient patient) {
    // Check if patient has appointments today by checking if they have any visits
    // For now, we'll check if they have any visits at all (simplified logic)
    // In a full implementation, we'd check for appointments on today's date
    return patient.id !=
        null; // Simplified - assume patients with IDs have visits
  }

  bool _hasPreviousVisits(Patient patient) {
    // Check if patient has any visits in the database
    // For now, we'll use a simplified check
    // In a full implementation, we'd query the visits table
    return patient.id != null &&
        patient.createdAt.isBefore(
          DateTime.now().subtract(const Duration(days: 1)),
        );
  }

  void _navigateToAddPatient() {
    GoRouter.of(context).go('/patients/add');
  }

  void _updateSessionsCount() {
    if (_sessions.length < _numberOfSessions) {
      // Add new sessions
      for (int i = _sessions.length; i < _numberOfSessions; i++) {
        _sessions.add(
          SessionFormData(
            sessionNumber: i + 1,
            dateTime: DateTime.now().add(Duration(days: i)),
            treatmentDetailsController: TextEditingController(),
            notesController: TextEditingController(),
            totalAmountController: TextEditingController(text: '0.0'),
            paidAmountController: TextEditingController(text: '0.0'),
          ),
        );
      }
    } else if (_sessions.length > _numberOfSessions) {
      // Remove excess sessions
      for (int i = _sessions.length - 1; i >= _numberOfSessions; i--) {
        _sessions[i].treatmentDetailsController.dispose();
        _sessions[i].notesController.dispose();
        _sessions[i].totalAmountController.dispose();
        _sessions[i].paidAmountController.dispose();
        _sessions.removeAt(i);
      }
    }
  }

  Future<void> _selectDateTime(SessionFormData session) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: session.dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(session.dateTime),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          session.dateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
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
      final visitService = ref.read(visitServiceProvider);
      final sessionService = ref.read(sessionServiceProvider);
      final patientService = ref.read(patientServiceProvider);

      Visit visit;
      if (_createNewVisit) {
        // Create new visit
        final nextVisitNumber = await visitService.getNextVisitNumber(
          _selectedPatient!.id!,
        );
        visit = Visit(
          patientId: _selectedPatient!.id!,
          dateTime: DateTime.now(),
          reasonForVisit: _reasonForVisitController.text,
          notes: _visitNotesController.text,
          visitNumber: nextVisitNumber,
          isEmergency: _isEmergency,
          emergencySeverity: _isEmergency
              ? _emergencySeverity
              : EmergencySeverity.low,
          healthAlerts: _healthAlertsController.text,
        );
        final visitId = await visitService.addVisit(visit);
        visit = visit.copyWith(id: visitId);
      } else {
        // Use existing visit
        if (_selectedVisit == null) {
          throw Exception('Please select an existing visit');
        }
        visit = _selectedVisit!;
      }

      // Create sessions
      final createdSessions = <Session>[];
      for (final sessionData in _sessions) {
        final session = Session(
          visitId: visit.id!,
          sessionNumber: sessionData.sessionNumber,
          dateTime: sessionData.dateTime,
          notes: sessionData.notesController.text,
          treatmentDetails: sessionData.treatmentDetailsController.text,
          totalAmount:
              double.tryParse(sessionData.totalAmountController.text) ?? 0.0,
          paidAmount:
              double.tryParse(sessionData.paidAmountController.text) ?? 0.0,
        );
        final sessionId = await sessionService.addSession(session);
        createdSessions.add(session.copyWith(id: sessionId));
      }

      // Create appointment for the first session
      final firstSession = createdSessions.first;
      final appointment = Appointment(
        id: widget.appointment?.id,
        sessionId: firstSession.id!,
        dateTime: firstSession.dateTime,
      );

      if (widget.appointment == null) {
        await appointmentService.addAppointment(appointment);
      } else {
        await appointmentService.updateAppointment(appointment);
      }

      // Update patient blacklist status if changed
      if (_selectedPatient!.isBlacklisted != _isBlacklisted) {
        final updatedPatient = _selectedPatient!.copyWith(
          isBlacklisted: _isBlacklisted,
        );
        await patientService.updatePatient(updatedPatient);
      }

      // Update patient notes if provided
      if (_patientNotesController.text.isNotEmpty) {
        // Patient notes are stored in the patient record, no separate field needed
        // The notes are already available in the form for future reference
      }

      ref.invalidate(appointmentsProvider);
      ref.invalidate(todaysAppointmentsProvider);
      ref.invalidate(visitsByPatientProvider(_selectedPatient!.id!));
      ref.invalidate(patientsProvider(PatientFilter.all));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    }
  }
}
