import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddEditPatientScreen extends ConsumerStatefulWidget {
  const AddEditPatientScreen({super.key, this.patient});

  final Patient? patient;

  @override
  ConsumerState<AddEditPatientScreen> createState() =>
      _AddEditPatientScreenState();
}

class _AddEditPatientScreenState extends ConsumerState<AddEditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _familyNameController;
  late TextEditingController _ageController;
  late TextEditingController _healthStateController;
  late TextEditingController _diagnosisController;
  late TextEditingController _treatmentController;
  late TextEditingController _paymentController;
  late bool _isEmergency;
  late EmergencySeverity _severity;
  late TextEditingController _healthAlertsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient?.name ?? '');
    _familyNameController = TextEditingController(
      text: widget.patient?.familyName ?? '',
    );
    _ageController = TextEditingController(
      text: widget.patient?.age.toString() ?? '',
    );
    _healthStateController = TextEditingController(
      text: widget.patient?.healthState ?? '',
    );
    _diagnosisController = TextEditingController(
      text: widget.patient?.diagnosis ?? '',
    );
    _treatmentController = TextEditingController(
      text: widget.patient?.treatment ?? '',
    );
    _paymentController = TextEditingController(
      text: widget.patient?.payment.toString() ?? '',
    );
    _isEmergency = widget.patient?.isEmergency ?? false;
    _severity = widget.patient?.severity ?? EmergencySeverity.low;
    _healthAlertsController = TextEditingController(
      text: widget.patient?.healthAlerts ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _familyNameController.dispose();
    _ageController.dispose();
    _healthStateController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _paymentController.dispose();
    _healthAlertsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientService = ref.watch(patientServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient == null ? 'Add Patient' : 'Edit Patient'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _familyNameController,
                  decoration: const InputDecoration(labelText: 'Family Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a family name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an age';
                    }
                    final age = int.tryParse(value);
                    if (age == null) {
                      return 'Please enter a valid number';
                    }
                    if (age < 0 || age > 150) {
                      return 'Please enter an age between 0 and 150';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _healthStateController,
                  decoration: const InputDecoration(labelText: 'Health State'),
                ),
                TextFormField(
                  controller: _diagnosisController,
                  decoration: const InputDecoration(labelText: 'Diagnosis'),
                ),
                TextFormField(
                  controller: _treatmentController,
                  decoration: const InputDecoration(labelText: 'Treatment'),
                ),
                TextFormField(
                  controller: _paymentController,
                  decoration: const InputDecoration(labelText: 'Payment'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a payment amount';
                    }
                    final payment = double.tryParse(value);
                    if (payment == null) {
                      return 'Please enter a valid number';
                    }
                    if (payment < 0) {
                      return 'Payment amount cannot be negative';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.red.withAlpha((255 * 0.8).round()),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emergency Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          title: const Text('Is Emergency'),
                          value: _isEmergency,
                          onChanged: (bool? value) {
                            setState(() {
                              _isEmergency = value ?? false;
                            });
                          },
                        ),
                        if (_isEmergency) ...[
                          DropdownButtonFormField<EmergencySeverity>(
                            initialValue: _severity,
                            decoration: const InputDecoration(
                              labelText: 'Severity',
                            ),
                            items: EmergencySeverity.values.map((
                              EmergencySeverity severity,
                            ) {
                              return DropdownMenuItem<EmergencySeverity>(
                                value: severity,
                                child: Text(
                                  severity.toString().split('.').last,
                                ),
                              );
                            }).toList(),
                            onChanged: (EmergencySeverity? newValue) {
                              setState(() {
                                _severity = newValue!;
                              });
                            },
                          ),
                          TextFormField(
                            controller: _healthAlertsController,
                            decoration: const InputDecoration(
                              labelText: 'Health Alerts',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          final newPatient = Patient(
                            id: widget.patient?.id,
                            name: _nameController.text,
                            familyName: _familyNameController.text,
                            age: int.tryParse(_ageController.text) ?? 0,
                            healthState: _healthStateController.text,
                            diagnosis: _diagnosisController.text,
                            treatment: _treatmentController.text,
                            payment:
                                double.tryParse(_paymentController.text) ?? 0.0,
                            createdAt:
                                widget.patient?.createdAt ?? DateTime.now(),
                            isEmergency: _isEmergency,
                            severity: _severity,
                            healthAlerts: _healthAlertsController.text,
                          );

                          if (widget.patient == null) {
                            await patientService.addPatient(newPatient);
                          } else {
                            await patientService.updatePatient(newPatient);
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
                    child: Text(widget.patient == null ? 'Add' : 'Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
