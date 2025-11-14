import 'package:dentaltid/src/core/exceptions.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

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
  late TextEditingController _dateOfBirthController;
  late TextEditingController _healthStateController;

  late TextEditingController _phoneNumberController;
  late bool _isEmergency;
  late EmergencySeverity _severity;
  late TextEditingController _healthAlertsController;

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirthController.text.isNotEmpty
          ? DateTime.tryParse(_dateOfBirthController.text) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  int _calculateAgeFromDOB(String dobString) {
    if (dobString.isEmpty) return 0;
    final dob = DateTime.tryParse(dobString);
    if (dob == null) return 0;

    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

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
    _dateOfBirthController = TextEditingController(
      text: widget.patient?.dateOfBirth != null
          ? widget.patient!.dateOfBirth!.toLocal().toString().split(' ')[0]
          : '',
    );
    _healthStateController = TextEditingController(
      text: widget.patient?.healthState ?? '',
    );

    _isEmergency = widget.patient?.isEmergency ?? false;
    _severity = widget.patient?.severity ?? EmergencySeverity.low;
    _healthAlertsController = TextEditingController(
      text: widget.patient?.healthAlerts ?? '',
    );
    _phoneNumberController = TextEditingController(
      text: widget.patient?.phoneNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _familyNameController.dispose();
    _ageController.dispose();
    _dateOfBirthController.dispose();
    _healthStateController.dispose();

    _healthAlertsController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientService = ref.watch(patientServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patient == null ? l10n.addPatient : l10n.editPatient,
        ),
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
                  decoration: InputDecoration(labelText: l10n.name),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterName;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _familyNameController,
                  decoration: InputDecoration(labelText: l10n.familyName),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterFamilyName;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _dateOfBirthController,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDateOfBirth(context),
                    ),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select date of birth';
                    }
                    if (DateTime.tryParse(value) == null) {
                      return 'Invalid date format';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _healthStateController,
                  decoration: InputDecoration(labelText: l10n.healthState),
                ),

                TextFormField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(labelText: l10n.phoneNumber),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Phone number is optional
                    }
                    // Regex for phone number validation (e.g., +1234567890, 123-456-7890, etc.)
                    // This regex allows for an optional '+' at the beginning, followed by 7 to 15 digits.
                    // ignore: deprecated_member_use
                    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
                    if (!phoneRegex.hasMatch(value)) {
                      return l10n.enterValidPhoneNumber;
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
                        Text(
                          l10n.emergencyDetails,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          title: Text(l10n.isEmergency),
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
                            decoration: InputDecoration(
                              labelText: l10n.severity,
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
                            decoration: InputDecoration(
                              labelText: l10n.healthAlerts,
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
                            age: _calculateAgeFromDOB(
                              _dateOfBirthController.text,
                            ),
                            dateOfBirth: DateTime.tryParse(
                              _dateOfBirthController.text,
                            ),
                            healthState: _healthStateController.text,
                            diagnosis: '',
                            treatment: '',
                            payment: 0.0,
                            createdAt:
                                widget.patient?.createdAt ?? DateTime.now(),
                            isEmergency: _isEmergency,
                            severity: _severity,
                            healthAlerts: _healthAlertsController.text,
                            phoneNumber: _phoneNumberController.text,
                          );

                          if (widget.patient == null) {
                            await patientService.addPatient(newPatient);
                            ref.invalidate(patientsProvider(PatientFilter.all));
                            ref.invalidate(
                              patientsProvider(PatientFilter.today),
                            );
                            ref.invalidate(
                              patientsProvider(PatientFilter.emergency),
                            );
                          } else {
                            await patientService.updatePatient(newPatient);
                            ref.invalidate(patientsProvider(PatientFilter.all));
                            ref.invalidate(
                              patientsProvider(PatientFilter.today),
                            );
                            ref.invalidate(
                              patientsProvider(PatientFilter.emergency),
                            );
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final errorMessage =
                                ErrorHandler.getUserFriendlyMessage(e);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Text(
                      widget.patient == null ? l10n.add : l10n.update,
                    ),
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
