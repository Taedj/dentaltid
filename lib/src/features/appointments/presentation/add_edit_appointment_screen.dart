import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  late TextEditingController _patientIdController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _patientIdController = TextEditingController(
      text: widget.appointment?.patientId.toString() ?? '',
    );
    _dateController = TextEditingController(
      text: widget.appointment?.date.toIso8601String().split('T')[0] ?? '',
    );
    _timeController = TextEditingController(
      text: widget.appointment?.time ?? '',
    );
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentService = ref.watch(appointmentServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.appointment == null ? 'Add Appointment' : 'Edit Appointment',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _patientIdController,
                decoration: const InputDecoration(labelText: 'Patient ID'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a patient ID';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a date';
                  }
                  final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!dateRegex.hasMatch(value)) {
                    return 'Please enter a valid date in YYYY-MM-DD format';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: 'Time (HH:MM)'),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a time';
                  }
                  final timeRegex = RegExp(r'^\d{2}:\d{2}$');
                  if (!timeRegex.hasMatch(value)) {
                    return 'Please enter a valid time in HH:MM format';
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
                          patientId:
                              int.tryParse(_patientIdController.text) ?? 0,
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
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(widget.appointment == null ? 'Add' : 'Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
