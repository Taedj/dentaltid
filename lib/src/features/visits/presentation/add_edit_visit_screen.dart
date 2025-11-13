import 'package:dentaltid/src/core/exceptions.dart';
import 'package:dentaltid/src/features/visits/application/visit_service.dart';
import 'package:dentaltid/src/features/visits/domain/visit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AddEditVisitScreen extends ConsumerStatefulWidget {
  const AddEditVisitScreen({
    super.key,
    required this.patientId,
    this.visit,
  });

  final int patientId;
  final Visit? visit;

  @override
  ConsumerState<AddEditVisitScreen> createState() => _AddEditVisitScreenState();
}

class _AddEditVisitScreenState extends ConsumerState<AddEditVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _reasonForVisitController;
  late TextEditingController _notesController;
  late TextEditingController _diagnosisController;
  late TextEditingController _treatmentController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: widget.visit != null
          ? DateFormat('yyyy-MM-dd').format(widget.visit!.dateTime)
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _reasonForVisitController = TextEditingController(
      text: widget.visit?.reasonForVisit ?? '',
    );
    _notesController = TextEditingController(
      text: widget.visit?.notes ?? '',
    );
    _diagnosisController = TextEditingController(
      text: widget.visit?.diagnosis ?? '',
    );
    _treatmentController = TextEditingController(
      text: widget.visit?.treatment ?? '',
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _reasonForVisitController.dispose();
    _notesController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitService = ref.watch(visitServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.visit == null ? l10n.addVisit : l10n.editVisit,
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
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: l10n.date,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterDate;
                    }
                    if (DateTime.tryParse(value) == null) {
                      return l10n.invalidDateFormat;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _reasonForVisitController,
                  decoration: InputDecoration(labelText: l10n.reasonForVisit),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterReasonForVisit;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: l10n.notes),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: _diagnosisController,
                  decoration: InputDecoration(labelText: l10n.diagnosis),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: _treatmentController,
                  decoration: InputDecoration(labelText: l10n.treatment),
                  maxLines: 2,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          final newVisit = Visit(
                            id: widget.visit?.id,
                            patientId: widget.patientId,
                            dateTime: DateTime.parse(_dateController.text),
                            reasonForVisit: _reasonForVisitController.text,
                            notes: _notesController.text,
                            diagnosis: _diagnosisController.text,
                            treatment: _treatmentController.text,
                          );

                          if (widget.visit == null) {
                            await visitService.addVisit(newVisit);
                          } else {
                            await visitService.updateVisit(newVisit);
                          }
                          ref.invalidate(visitsByPatientProvider(widget.patientId));
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
                      widget.visit == null ? l10n.add : l10n.update,
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
