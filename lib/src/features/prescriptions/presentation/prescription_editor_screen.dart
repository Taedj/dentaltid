import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:dentaltid/src/features/prescriptions/application/prescription_service.dart';
import 'package:dentaltid/src/features/prescriptions/domain/prescription.dart';
import 'package:dentaltid/src/features/prescriptions/domain/prescription_medicine.dart';
import 'package:dentaltid/src/features/prescriptions/presentation/prescription_templates.dart';
import 'package:dentaltid/src/features/prescriptions/presentation/prescription_print_options.dart';
import 'package:dentaltid/src/features/prescriptions/domain/medicine_preset.dart';
import 'package:dentaltid/src/features/prescriptions/application/medicine_preset_service.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrescriptionEditorScreen extends ConsumerStatefulWidget {
  final Patient patient;
  final UserProfile userProfile;

  const PrescriptionEditorScreen({
    super.key,
    required this.patient,
    required this.userProfile,
  });

  @override
  ConsumerState<PrescriptionEditorScreen> createState() => _PrescriptionEditorScreenState();
}

class _PrescriptionEditorScreenState extends ConsumerState<PrescriptionEditorScreen> with SingleTickerProviderStateMixin {
  final List<PrescriptionMedicine> _medicines = [];
  final String _selectedTemplate = 'model_01'; 
  String _selectedLanguage = 'fr'; // Default Language
  PrescriptionPrintOptions _printOptions = const PrescriptionPrintOptions();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _restoreLanguage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _qtyController.dispose();
    _freqController.dispose();
    _routeController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _restoreLanguage() async {
    final lang = SettingsService.instance.getString('prescription_language');
    if (lang != null && mounted) {
      setState(() => _selectedLanguage = lang);
    }
  }

  Future<void> _saveLanguage(String lang) async {
    setState(() => _selectedLanguage = lang);
    await SettingsService.instance.setString('prescription_language', lang);
  }
  
  // Interactive Fields State
  String? _notes;
  String? _advice;
  String? _qrContent;
  String? _logoPath;

  // Handlers
  Future<void> _handleEditNotes() async {
    final controller = TextEditingController(text: _notes);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Notes'),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(hintText: 'Enter internal notes...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null) setState(() => _notes = result);
  }

  Future<void> _handleEditAdvice() async {
    final controller = TextEditingController(text: _advice);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Advice'),
        content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(hintText: 'Enter patient advice...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null) setState(() => _advice = result);
  }

  Future<void> _handleEditQr() async {
    final controller = TextEditingController(text: _qrContent);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Content'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Enter URL or Text...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Update')),
        ],
      ),
    );
    if (result != null) setState(() => _qrContent = result);
  }

  Future<void> _handleUploadLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _logoPath = result.files.single.path);
    }
  }

  Future<void> _handleUploadBackground() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _printOptions = _printOptions.copyWith(backgroundImagePath: result.files.single.path));
    }
  }

  Future<void> _saveAsPreset() async {
    if (_medicines.isEmpty) return;

    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Preset'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Preset Name', hintText: 'e.g. Tooth Extraction Aftercare'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final preset = MedicinePreset(
        name: result,
        medicines: List.from(_medicines),
        createdAt: DateTime.now(),
      );
      await ref.read(medicinePresetServiceProvider).savePreset(preset);
      ref.invalidate(medicinePresetsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preset saved successfully')),
        );
      }
    }
  }

  void _addPresetToPrescription(MedicinePreset preset) {
    setState(() {
      _medicines.addAll(preset.medicines);
    });
  }
  
  // Controllers for adding new medicine
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _freqController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  void _addMedicine() {
    if (_nameController.text.isEmpty) return;
    
    setState(() {
      _medicines.add(PrescriptionMedicine(
        medicineName: _nameController.text,
        quantity: _qtyController.text,
        frequency: _freqController.text,
        route: _routeController.text,
        time: _timeController.text,
      ));
      _nameController.clear();
      _qtyController.clear();
      _freqController.clear();
      _routeController.clear();
      _timeController.clear();
    });
  }

  void _removeMedicine(int index) {
    setState(() {
      _medicines.removeAt(index);
    });
  }

  Future<void> _savePrescription() async {
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine')),
      );
      return;
    }

    final prescription = Prescription(
      dentistId: widget.userProfile.uid,
      patientId: widget.patient.id!,
      orderNumber: 0, // Service will calculate this
      date: DateTime.now(),
      patientName: widget.patient.name,
      patientFamilyName: widget.patient.familyName,
      patientAge: widget.patient.age,
      medicines: _medicines,
      templateId: _selectedTemplate,
    );

    try {
      await ref.read(prescriptionServiceProvider).createPrescription(prescription);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving prescription: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Prescription Editor'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
              onChanged: (value) {
                if (value != null) _saveLanguage(value);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Printing logic would go here
            },
          ),
          ElevatedButton.icon(
            onPressed: _savePrescription,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Editor
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Manual Input'),
                      Tab(text: 'Presets'),
                    ],
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Manual Input
                        Column(
                          children: [
                            _buildInputRow(),
                            const SizedBox(height: 16),
                            Expanded(child: _buildMedicineTable()),
                            const SizedBox(height: 8),
                            if (_medicines.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _saveAsPreset,
                                  icon: const Icon(Icons.bookmark_add_outlined),
                                  label: const Text('Save Current List as Preset'),
                                ),
                              ),
                          ],
                        ),
                        // Tab 2: Presets
                        _buildPresetsTab(),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  const Text('Layout & Background', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleUploadBackground,
                          icon: const Icon(Icons.image_outlined),
                          label: Text(_printOptions.backgroundImagePath == null ? 'Add BG' : 'Change BG'),
                        ),
                      ),
                      if (_printOptions.backgroundImagePath != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _printOptions = _printOptions.copyWith(backgroundImagePath: null)),
                        ),
                    ],
                  ),
                  if (_printOptions.backgroundImagePath != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.opacity, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _printOptions.backgroundOpacity,
                            min: 0.05,
                            max: 1.0,
                            onChanged: (v) => setState(() => _printOptions = _printOptions.copyWith(backgroundOpacity: v)),
                          ),
                        ),
                        Text('${(_printOptions.backgroundOpacity * 100).toInt()}%'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Print Options', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      FilterChip(
                        label: const Text('Logo'),
                        selected: _printOptions.showLogo,
                        onSelected: (v) => setState(() => _printOptions = _printOptions.copyWith(showLogo: v)),
                      ),
                      FilterChip(
                        label: const Text('Notes'),
                        selected: _printOptions.showNotes,
                        onSelected: (v) => setState(() => _printOptions = _printOptions.copyWith(showNotes: v)),
                      ),
                      FilterChip(
                        label: const Text('Advice'),
                        selected: _printOptions.showAdvice,
                        onSelected: (v) => setState(() => _printOptions = _printOptions.copyWith(showAdvice: v)),
                      ),
                      FilterChip(
                        label: const Text('Email'),
                        selected: _printOptions.showEmail,
                        onSelected: (v) => setState(() => _printOptions = _printOptions.copyWith(showEmail: v)),
                      ),
                      FilterChip(
                        label: const Text('QR Code'),
                        selected: _printOptions.showQrCode,
                        onSelected: (v) => setState(() => _printOptions = _printOptions.copyWith(showQrCode: v)),
                      ),
                      FilterChip(
                        label: const Text('Branding'),
                        selected: _printOptions.showBranding,
                        onSelected: (v) => setState(() => _printOptions = _printOptions.copyWith(showBranding: v)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Right Side: Preview
          Expanded(
            flex: 1,
            child: Container(
              color: colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1 / 1.414, // A4 aspect ratio
                  child: Card(
                    elevation: 8,
                    child: PrescriptionTemplate(
                      prescription: Prescription(
                        dentistId: widget.userProfile.uid,
                        patientId: widget.patient.id!,
                        orderNumber: 1, // Preview number
                        date: DateTime.now(),
                        patientName: widget.patient.name,
                        patientFamilyName: widget.patient.familyName,
                        patientAge: widget.patient.age,
                        medicines: List.from(_medicines),
                        templateId: _selectedTemplate,
                        notes: _notes,
                        advice: _advice,
                        qrContent: _qrContent,
                      ),
                      userProfile: widget.userProfile,
                      templateId: _selectedTemplate,
                      printOptions: _printOptions,
                      language: _selectedLanguage,
                      onEditNotes: _handleEditNotes,
                      onEditAdvice: _handleEditAdvice,
                      onEditQr: _handleEditQr,
                      onUploadLogo: _handleUploadLogo,
                      logoPath: _logoPath,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsTab() {
    final presetsAsync = ref.watch(medicinePresetsProvider);

    return presetsAsync.when(
      data: (presets) {
        if (presets.isEmpty) {
          return const Center(
            child: Text('No presets saved yet.\nSave a medicine list first.', textAlign: TextAlign.center),
          );
        }
        return ListView.builder(
          itemCount: presets.length,
          itemBuilder: (context, index) {
            final preset = presets[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ExpansionTile(
                title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${preset.medicines.length} medicines'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                      tooltip: 'Add to Prescription',
                      onPressed: () => _addPresetToPrescription(preset),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete Preset',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Preset'),
                            content: Text('Are you sure you want to delete "${preset.name}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(medicinePresetServiceProvider).deletePreset(preset.id!);
                          ref.invalidate(medicinePresetsProvider);
                        }
                      },
                    ),
                  ],
                ),
                children: [
                  ...preset.medicines.map((m) => ListTile(
                    dense: true,
                    title: Text('${m.medicineName} (${m.quantity})'),
                    subtitle: Text('${m.frequency} - ${m.route} - ${m.time}'),
                  )),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading presets: $e')),
    );
  }

  Widget _buildInputRow() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Medicine Name', hintText: 'e.g. Amoxicillin'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _qtyController,
                    decoration: const InputDecoration(labelText: 'Qty', hintText: '500mg'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _freqController,
                    decoration: const InputDecoration(labelText: 'Freq', hintText: '3x/day'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _routeController,
                    decoration: const InputDecoration(labelText: 'Route', hintText: 'Orally'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _timeController,
                    decoration: const InputDecoration(labelText: 'Time/Duration', hintText: '7 days'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addMedicine,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineTable() {
    if (_medicines.isEmpty) {
      return const Center(child: Text('No medicines added yet.'));
    }
    return ListView.builder(
      itemCount: _medicines.length,
      itemBuilder: (context, index) {
        final m = _medicines[index];
        return Card(
          key: ValueKey(m.hashCode),
          child: ListTile(
            title: Text('${m.medicineName} (${m.quantity})'),
            subtitle: Text('${m.frequency} - ${m.route} - ${m.time}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeMedicine(index),
            ),
          ),
        );
      },
    );
  }
}
