import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:dentaltid/src/features/prescriptions/application/prescription_service.dart';
import 'package:dentaltid/src/features/prescriptions/domain/prescription.dart';
import 'package:dentaltid/src/features/prescriptions/domain/prescription_medicine.dart';
import 'package:dentaltid/src/features/prescriptions/presentation/prescription_templates.dart';
import 'package:dentaltid/src/features/prescriptions/presentation/prescription_print_options.dart';
import 'package:dentaltid/src/features/prescriptions/domain/medicine_preset.dart';
import 'package:dentaltid/src/features/prescriptions/application/medicine_preset_service.dart';
import 'package:dentaltid/src/features/prescriptions/presentation/widgets/edit_medicine_preset_dialog.dart';
import 'package:dentaltid/src/features/prescriptions/application/prescription_pdf_helper.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PrescriptionEditorScreen extends ConsumerStatefulWidget {
  final Patient patient;
  final UserProfile userProfile;
  final int? visitId;

  const PrescriptionEditorScreen({
    super.key,
    required this.patient,
    required this.userProfile,
    this.visitId,
  });

  @override
  ConsumerState<PrescriptionEditorScreen> createState() =>
      _PrescriptionEditorScreenState();
}

class _PrescriptionEditorScreenState
    extends ConsumerState<PrescriptionEditorScreen>
    with SingleTickerProviderStateMixin {
  final List<PrescriptionMedicine> _medicines = [];
  final String _selectedTemplate = 'model_01';
  String _selectedLanguage = 'fr'; // Default Language
  PrescriptionPrintOptions _printOptions = const PrescriptionPrintOptions();
  late TabController _tabController;
  int? _existingPrescriptionId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _restoreSettings();
    _loadExistingPrescription();
  }

  Future<void> _loadExistingPrescription() async {
    if (widget.visitId == null) return;

    final existing = await ref
        .read(prescriptionServiceProvider)
        .getPrescriptionByVisit(widget.visitId!);

    if (existing != null && mounted) {
      setState(() {
        _existingPrescriptionId = existing.id;
        _medicines.clear();
        _medicines.addAll(existing.medicines);
        _notes = existing.notes;
        _advice = existing.advice;
        _qrContent = existing.qrContent;
        _logoPath = existing.logoPath;
        _printOptions = _printOptions.copyWith(
          backgroundImagePath: existing.backgroundImagePath,
          backgroundOpacity: existing.backgroundOpacity,
          showLogo: existing.showLogo,
          showNotes: existing.showNotes,
          showAllergies: existing.showAllergies,
          showAdvice: existing.showAdvice,
          showQrCode: existing.showQrCode,
          showBranding: existing.showBranding,
          showBorders: existing.showBorders,
          showEmail: existing.showEmail,
        );
      });
    }
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

  Future<void> _restoreSettings() async {
    final settings = SettingsService.instance;
    final lang = settings.getString('prescription_language');
    final bgPath = settings.getString('prescription_bg_path');
    final bgOpacity = settings.getDouble('prescription_bg_opacity');
    final logo = settings.getString('prescription_logo_path');
    final qr = settings.getString('prescription_qr_content');
    final notes = settings.getString('prescription_default_notes');
    final advice = settings.getString('prescription_default_advice');

    if (mounted) {
      setState(() {
        if (lang != null) _selectedLanguage = lang;
        if (bgPath != null) {
          _printOptions = _printOptions.copyWith(
            backgroundImagePath: bgPath,
            backgroundOpacity: bgOpacity ?? 0.2,
          );
        }
        _printOptions = _printOptions.copyWith(
          showLogo: settings.getBool('prescription_show_logo') ?? false,
          showNotes: settings.getBool('prescription_show_notes') ?? false,
          showAllergies:
              settings.getBool('prescription_show_allergies') ?? false,
          showAdvice: settings.getBool('prescription_show_advice') ?? false,
          showQrCode: settings.getBool('prescription_show_qr') ?? false,
          showBranding: settings.getBool('prescription_show_branding') ?? false,
          showBorders: settings.getBool('prescription_show_borders') ?? false,
          showEmail: settings.getBool('prescription_show_email') ?? false,
        );

        if (logo != null) _logoPath = logo;
        if (qr != null) _qrContent = qr;
        if (notes != null) _notes = notes;
        if (advice != null) _advice = advice;
      });
    }
  }

  Future<void> _saveLanguage(String lang) async {
    setState(() => _selectedLanguage = lang);
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
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter internal notes...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _notes = result);
    }
  }

  Future<void> _handleEditAdvice() async {
    final controller = TextEditingController(text: _advice);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Advice'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter patient advice...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _advice = result);
    }
  }

  Future<void> _handleEditQr() async {
    final controller = TextEditingController(text: _qrContent);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Content'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter URL or Text...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _qrContent = result);
    }
  }

  Future<String> _securelyCopyPrescriptionImage(String sourcePath) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(
        p.join(docsDir.path, 'DentalTid', 'Imaging', 'Prescriptions'),
      );

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final fileName = p.basename(sourcePath);
      // Create a unique filename to avoid collisions if users pick "logo.png" multiple times
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final targetPath = p.join(targetDir.path, uniqueFileName);

      await File(sourcePath).copy(targetPath);
      return targetPath;
    } catch (e) {
      debugPrint('Error copying prescription image: $e');
      // If copy fails, fallback to original path (better than nothing)
      return sourcePath;
    }
  }

  Future<void> _handleUploadLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final originalPath = result.files.single.path!;
      final securedPath = await _securelyCopyPrescriptionImage(originalPath);

      setState(() => _logoPath = securedPath);
    }
  }

  Future<void> _handleUploadBackground() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final originalPath = result.files.single.path!;
      final securedPath = await _securelyCopyPrescriptionImage(originalPath);

      setState(
        () => _printOptions = _printOptions.copyWith(
          backgroundImagePath: securedPath,
        ),
      );
    }
  }

  Future<void> _handlePrint() async {
    final pdf = pw.Document();

    // Load fonts and images
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    final logoImage = _logoPath != null
        ? pw.MemoryImage(File(_logoPath!).readAsBytesSync())
        : null;
    final bgImage = _printOptions.backgroundImagePath != null
        ? pw.MemoryImage(
            File(_printOptions.backgroundImagePath!).readAsBytesSync(),
          )
        : null;

    final t = {
      'fr': {
        'dr': 'Dr.',
        'surgeon': 'Chirurgien Dentiste',
        'city': 'Ville',
        'on': 'le',
        'order_no': 'N° d\'ordre',
        'patient': 'PATIENT',
        'age': 'Age',
        'years': 'Ans',
        'prescription_title': 'ORDONNANCE',
        'notes': 'NOTES',
        'advice': 'CONSEILS',
        'signature': 'Signature & Cachet',
        'tel': 'Tél',
      },
      'en': {
        'dr': 'Dr.',
        'surgeon': 'Dental Surgeon',
        'city': 'City',
        'on': 'on',
        'order_no': 'Order No.',
        'patient': 'PATIENT',
        'age': 'Age',
        'years': 'Yrs',
        'prescription_title': 'PRESCRIPTION',
        'notes': 'NOTES',
        'advice': 'ADVICE',
        'signature': 'Signature & Stamp',
        'tel': 'Tel',
      },
      'ar': {
        'dr': 'د.',
        'surgeon': 'جراح أسنان',
        'city': 'المدينة',
        'on': 'في',
        'order_no': 'رقم الترتيب',
        'patient': 'المريض',
        'age': 'العمر',
        'years': 'سنة',
        'prescription_title': 'وصفة طبية',
        'notes': 'ملاحظات',
        'advice': 'نصائح',
        'signature': 'التوقيع والختم',
        'tel': 'هاتف',
      },
    }[_selectedLanguage]!;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                // Background
                if (bgImage != null)
                  pw.Opacity(
                    opacity: _printOptions.backgroundOpacity,
                    child: pw.Center(
                      child: pw.Image(bgImage, fit: pw.BoxFit.contain),
                    ),
                  ),
                // Content
                pw.Padding(
                  padding: const pw.EdgeInsets.all(24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                if (_printOptions.showLogo && logoImage != null)
                                  pw.Container(
                                    height: 50,
                                    child: pw.Image(
                                      logoImage,
                                      alignment: pw.Alignment.centerLeft,
                                    ),
                                  ),
                                pw.Text(
                                  (widget.userProfile.clinicName ??
                                          'Cabinet Dentaire')
                                      .toUpperCase(),
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  widget.userProfile.dentistName ??
                                      '${t['dr']} Dentist',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  t['surgeon']!,
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                if (_printOptions.showQrCode &&
                                    _qrContent != null)
                                  pw.Container(
                                    width: 40,
                                    height: 40,
                                    child: pw.BarcodeWidget(
                                      barcode: pw.Barcode.qrCode(),
                                      data: _qrContent!,
                                    ),
                                  ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  '${t['order_no']}: 1',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                if (widget.userProfile.phoneNumber != null)
                                  pw.Text(
                                    '${t['tel']}: ${widget.userProfile.phoneNumber}',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Divider(thickness: 0.5),
                      pw.SizedBox(height: 5),
                      // Patient Info
                      pw.Row(
                        children: [
                          pw.Text(
                            '${t['patient']}: ',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '${widget.patient.name} ${widget.patient.familyName}'
                                .toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Spacer(),
                          pw.Text(
                            '${t['age']}: ${widget.patient.age} ${t['years']}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      // Date
                      pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          '${widget.userProfile.province ?? ''} ${t['on']} : ${DateFormat('dd / MM / yyyy').format(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      // Title
                      pw.Center(
                        child: pw.Text(
                          t['prescription_title']!,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      // Medicines
                      pw.Expanded(
                        child: pw.ListView.builder(
                          itemCount: _medicines.length,
                          itemBuilder: (pw.Context context, int index) {
                            final m = _medicines[index];
                            String route = m.route;
                            if (_selectedLanguage == 'fr' &&
                                route.toLowerCase() == 'orally') {
                              route = 'voie orale';
                            }
                            final posology =
                                '${m.quantity} ${m.frequency} par $route pendant ${m.time}';

                            return pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 10),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    children: [
                                      pw.Text(
                                        '• ',
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                      pw.Text(
                                        m.medicineName.toUpperCase(),
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(
                                      left: 12,
                                      top: 2,
                                    ),
                                    child: pw.Text(
                                      posology,
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        fontStyle: pw.FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Notes / Advice
                      if (_printOptions.showNotes && _notes != null) ...[
                        pw.Text(
                          '${t['notes']}:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red,
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Text(
                            _notes!,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                      ],
                      if (_printOptions.showAdvice && _advice != null) ...[
                        pw.Text(
                          '${t['advice']}:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          _advice!,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                      ],
                      pw.SizedBox(height: 20),
                      // Footer
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            widget.userProfile.clinicAddress ?? '',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                          pw.Column(
                            children: [
                              pw.Text(
                                t['signature']!,
                                style: const pw.TextStyle(fontSize: 7),
                              ),
                              pw.SizedBox(height: 30),
                              pw.Container(
                                width: 100,
                                height: 0.5,
                                color: PdfColors.black,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Prescription_${widget.patient.name}',
    );
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
          decoration: const InputDecoration(
            labelText: 'Preset Name',
            hintText: 'e.g. Tooth Extraction Aftercare',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
      _medicines.add(
        PrescriptionMedicine(
          medicineName: _nameController.text,
          quantity: _qtyController.text,
          frequency: _freqController.text,
          route: _routeController.text,
          time: _timeController.text,
        ),
      );
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
      id: _existingPrescriptionId,
      dentistId: widget.userProfile.uid,
      patientId: widget.patient.id!,
      visitId: widget.visitId,
      orderNumber: 0, // Service will calculate this for new ones
      date: DateTime.now(),
      patientName: widget.patient.name,
      patientFamilyName: widget.patient.familyName,
      patientAge: widget.patient.age,
      medicines: _medicines,
      templateId: _selectedTemplate,
      notes: _notes,
      advice: _advice,
      qrContent: _qrContent,
      logoPath: _logoPath,
      backgroundImagePath: _printOptions.backgroundImagePath,
      backgroundOpacity: _printOptions.backgroundOpacity,
      showLogo: _printOptions.showLogo,
      showNotes: _printOptions.showNotes,
      showAllergies: _printOptions.showAllergies,
      showAdvice: _printOptions.showAdvice,
      showQrCode: _printOptions.showQrCode,
      showBranding: _printOptions.showBranding,
      showBorders: _printOptions.showBorders,
      showEmail: _printOptions.showEmail,
    );

    try {
      // Persist these options as defaults for future prescriptions
      final settings = SettingsService.instance;
      await settings.setString('prescription_language', _selectedLanguage);
      if (_printOptions.backgroundImagePath != null) {
        await settings.setString(
          'prescription_bg_path',
          _printOptions.backgroundImagePath!,
        );
      } else {
        await settings.remove('prescription_bg_path');
      }
      await settings.setDouble(
        'prescription_bg_opacity',
        _printOptions.backgroundOpacity,
      );
      await settings.setBool('prescription_show_logo', _printOptions.showLogo);
      await settings.setBool('prescription_show_notes', _printOptions.showNotes);
      await settings.setBool(
        'prescription_show_allergies',
        _printOptions.showAllergies,
      );
      await settings.setBool('prescription_show_advice', _printOptions.showAdvice);
      await settings.setBool('prescription_show_qr', _printOptions.showQrCode);
      await settings.setBool(
        'prescription_show_branding',
        _printOptions.showBranding,
      );
      await settings.setBool('prescription_show_borders', _printOptions.showBorders);
      await settings.setBool('prescription_show_email', _printOptions.showEmail);

      if (_logoPath != null) {
        await settings.setString('prescription_logo_path', _logoPath!);
      }
      if (_notes != null) {
        await settings.setString('prescription_default_notes', _notes!);
      }
      if (_advice != null) {
        await settings.setString('prescription_default_advice', _advice!);
      }
      if (_qrContent != null) {
        await settings.setString('prescription_qr_content', _qrContent!);
      }

      if (_existingPrescriptionId != null) {
        await ref
            .read(prescriptionServiceProvider)
            .updatePrescription(prescription);
      } else {
        await ref
            .read(prescriptionServiceProvider)
            .createPrescription(prescription);
      }
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
          IconButton(icon: const Icon(Icons.print), onPressed: _handlePrint),
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
                border: Border(
                  right: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Manual Input'),
                      Tab(text: 'Presets'),
                      Tab(text: 'Options'),
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
                                  label: const Text(
                                    'Save Current List as Preset',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Tab 2: Presets
                        _buildPresetsTab(),
                        // Tab 3: Options
                        _buildOptionsTab(),
                      ],
                    ),
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
                                  backgroundImagePath: _printOptions.backgroundImagePath,
                                  backgroundOpacity: _printOptions.backgroundOpacity,
                                  showLogo: _printOptions.showLogo,
                                  showNotes: _printOptions.showNotes,
                                  showAllergies: _printOptions.showAllergies,
                                  showAdvice: _printOptions.showAdvice,
                                  showQrCode: _printOptions.showQrCode,
                                  showBranding: _printOptions.showBranding,
                                  showBorders: _printOptions.showBorders,
                                  showEmail: _printOptions.showEmail,
                                ),
                                userProfile: widget.userProfile,                      templateId: _selectedTemplate,
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
            child: Text(
              'No presets saved yet.\nSave a medicine list first.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          itemCount: presets.length,
          itemBuilder: (context, index) {
            final preset = presets[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ExpansionTile(
                title: Text(
                  preset.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${preset.medicines.length} medicines'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue),
                      tooltip: 'Edit Preset',
                      onPressed: () =>
                          showEditMedicinePresetDialog(context, preset),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.green,
                      ),
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
                            content: Text(
                              'Are you sure you want to delete "${preset.name}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(medicinePresetServiceProvider)
                              .deletePreset(preset.id!);
                          ref.invalidate(medicinePresetsProvider);
                        }
                      },
                    ),
                  ],
                ),
                children: [
                  ...preset.medicines.map(
                    (m) => ListTile(
                      dense: true,
                      title: Text('${m.medicineName} (${m.quantity})'),
                      subtitle: Text('${m.frequency} - ${m.route} - ${m.time}'),
                    ),
                  ),
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

  Widget _buildOptionsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layout & Background',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleUploadBackground,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _printOptions.backgroundImagePath == null
                        ? 'Add Background'
                        : 'Change Background',
                  ),
                ),
              ),
              if (_printOptions.backgroundImagePath != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => setState(
                    () => _printOptions = _printOptions.copyWith(
                      backgroundImagePath: null,
                    ),
                  ),
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
                    onChanged: (v) {
                      setState(
                        () => _printOptions = _printOptions.copyWith(
                          backgroundOpacity: v,
                        ),
                      );
                    },
                  ),
                ),
                Text('${(_printOptions.backgroundOpacity * 100).toInt()}%'),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Print Components Visibility',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              FilterChip(
                label: const Text('Logo'),
                selected: _printOptions.showLogo,
                onSelected: (v) {
                  setState(
                    () => _printOptions = _printOptions.copyWith(showLogo: v),
                  );
                },
              ),
              FilterChip(
                label: const Text('Notes'),
                selected: _printOptions.showNotes,
                onSelected: (v) {
                  setState(
                    () => _printOptions = _printOptions.copyWith(showNotes: v),
                  );
                },
              ),
              FilterChip(
                label: const Text('Allergies'),
                selected: _printOptions.showAllergies,
                onSelected: (v) {
                  setState(
                    () => _printOptions = _printOptions.copyWith(
                      showAllergies: v,
                    ),
                  );
                },
              ),
              FilterChip(
                label: const Text('Advice'),
                selected: _printOptions.showAdvice,
                onSelected: (v) {
                  setState(
                    () => _printOptions = _printOptions.copyWith(showAdvice: v),
                  );
                },
              ),
              FilterChip(
                label: const Text('Email'),
                selected: _printOptions.showEmail,
                onSelected: (v) {
                  setState(
                    () => _printOptions = _printOptions.copyWith(showEmail: v),
                  );
                },
              ),
              FilterChip(
                label: const Text('QR Code'),
                selected: _printOptions.showQrCode,
                onSelected: (v) {
                  setState(
                    () => _printOptions = _printOptions.copyWith(showQrCode: v),
                  );
                },
              ),
              FilterChip(
                label: const Text('Branding'),
                selected: _printOptions.showBranding,
                onSelected: (v) {
                  setState(
                    () =>
                        _printOptions = _printOptions.copyWith(showBranding: v),
                  );
                },
              ),
              FilterChip(
                label: const Text('Borders'),
                selected: _printOptions.showBorders,
                onSelected: (v) {
                  setState(
                    () =>
                        _printOptions = _printOptions.copyWith(showBorders: v),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(50),
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
                    decoration: const InputDecoration(
                      labelText: 'Medicine Name',
                      hintText: 'e.g. Amoxicillin',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _qtyController,
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      hintText: '500mg',
                    ),
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
                    decoration: const InputDecoration(
                      labelText: 'Freq',
                      hintText: '3x/day',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _routeController,
                    decoration: const InputDecoration(
                      labelText: 'Route',
                      hintText: 'Orally',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'Time/Duration',
                      hintText: '7 days',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addMedicine,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
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
