import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

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
  late TextEditingController _dateController;
  late TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.appointment?.patientId;
    _dateController = TextEditingController(
      text: widget.appointment?.date.toIso8601String().split('T')[0] ?? '',
    );
    _timeController = TextEditingController(
      text: widget.appointment?.time ?? '',
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
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
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: l10n.dateYYYYMMDD,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateController.text = picked.toIso8601String().split(
                            'T',
                          )[0];
                        });
                      }
                    },
                  ),
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.enterDate;
                  }
                  final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!dateRegex.hasMatch(value)) {
                    return l10n.invalidDateFormat;
                  }
                  final selectedDate = DateTime.tryParse(value);
                  if (selectedDate == null) {
                    return l10n.invalidDate;
                  }
                  if (selectedDate.isBefore(
                    DateTime.now().subtract(const Duration(days: 1)),
                  )) {
                    return l10n.dateInPast;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: l10n.timeHHMM,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _timeController.text =
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                  ),
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.enterTime;
                  }
                  final timeRegex = RegExp(r'^(\d{2}):(\d{2})$');
                  if (!timeRegex.hasMatch(value)) {
                    return l10n.invalidTimeFormat;
                  }

                  // Check if the combined date and time is in the future
                  if (_dateController.text.isNotEmpty) {
                    try {
                      final dateTimeString = '${_dateController.text} $value';
                      final appointmentDateTime = DateTime.parse(
                        dateTimeString,
                      );
                      if (appointmentDateTime.isBefore(DateTime.now())) {
                        return 'Appointment time cannot be in the past';
                      }
                    } catch (e) {
                      // If parsing fails, let the date validation handle it
                    }
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
                          date: DateTime.parse(_dateController.text),
                          time: _timeController.text,
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
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } on Exception catch (e) {
                        if (context.mounted) {
                          String errorMessage = l10n.error + e.toString();
                          if (e.toString().contains(
                            'An appointment for this patient at this date and time already exists.',
                          )) {
                            errorMessage = l10n.appointmentExistsError;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${l10n.error}${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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
