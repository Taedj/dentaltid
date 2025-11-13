import 'dart:developer' as developer;

import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/core/exceptions.dart'; // Import for DuplicateEntryException

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
  late int? _selectedPatientId;
  late TextEditingController _dateTimeController; // Combined controller

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.appointment?.patientId;
    _dateTimeController = TextEditingController(
      text:
          widget.appointment?.dateTime.toIso8601String() ??
          '', // Use combined dateTime
    );
  }

  @override
  void dispose() {
    _dateTimeController.dispose(); // Dispose combined controller
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              patientsAsyncValue.when(
                data: (patients) {
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedPatientId,
                    decoration: InputDecoration(labelText: l10n.patient),
                    items: patients.map((Patient patient) {
                      return DropdownMenuItem<int>(
                        value: patient.id,
                        child: Text('${patient.name} ${patient.familyName}'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        _selectedPatientId = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return l10n.selectPatient;
                      }
                      return null;
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('${l10n.error}$error'),
              ),
              TextFormField(
                controller: _dateTimeController,
                decoration: InputDecoration(
                  labelText:
                      '${l10n.dateYYYYMMDD} ${l10n.timeHHMM}', // Combined label
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (!context.mounted) return; // Added check
                      if (pickedDate != null) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (!context.mounted) return; // Added check
                        if (pickedTime != null) {
                          final combinedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                          setState(() {
                            _dateTimeController.text = combinedDateTime
                                .toIso8601String();
                          });
                        }
                      }
                    },
                  ),
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n
                        .enterDate; // Reusing enterDate for combined field
                  }
                  final selectedDateTime = DateTime.tryParse(value);
                  if (selectedDateTime == null) {
                    return l10n.invalidDateFormat; // Reusing invalidDateFormat
                  }
                  if (selectedDateTime.isBefore(
                    DateTime.now().subtract(
                      const Duration(minutes: 1),
                    ), // Allow current minute
                  )) {
                    return l10n.dateInPast; // Reusing dateInPast
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        final newAppointment = Appointment(
                          id: widget.appointment?.id,
                          patientId: _selectedPatientId!,
                          dateTime: DateTime.parse(
                            _dateTimeController.text,
                          ), // Use combined dateTime
                        );

                        if (widget.appointment == null) {
                          await appointmentService.addAppointment(
                            newAppointment,
                          );
                        } else {
                          await appointmentService.updateAppointment(
                            newAppointment,
                          );
                        }
                        ref.invalidate(appointmentsProvider);
                        ref.invalidate(todaysAppointmentsProvider);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      } on DuplicateEntryException catch (_) {
                        // Changed to catch (_)
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.appointmentExistsError),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        // Changed to catch (e) to log the actual error
                        if (!context.mounted) return;
                        // Log the actual error for debugging
                        developer.log(
                          'Error adding appointment: $e',
                          name: 'AddEditAppointmentScreen',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${l10n.error}$e',
                            ), // Show the actual error
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    widget.appointment == null ? l10n.add : l10n.update,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
