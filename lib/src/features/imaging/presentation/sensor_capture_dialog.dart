import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_twain_scanner/flutter_twain_scanner.dart';
import 'package:dentaltid/src/features/imaging/application/imaging_service.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SensorCaptureDialog extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;

  const SensorCaptureDialog({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<SensorCaptureDialog> createState() => _SensorCaptureDialogState();
}

class _SensorCaptureDialogState extends ConsumerState<SensorCaptureDialog> {
  final _twainScanner = FlutterTwainScanner();
  List<String> _sources = [];
  String? _selectedSource;
  bool _isScanning = false;
  File? _capturedImage;
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _loadSources();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_labelController.text.isEmpty) {
      _labelController.text = AppLocalizations.of(context)!.intraoralXrayDefault;
    }
  }

  Future<void> _loadSources() async {
    try {
      final sources = await _twainScanner.getDataSources();
      setState(() {
        _sources = sources;
        if (sources.isNotEmpty) _selectedSource = sources.first;
      });
    } catch (e) {
      debugPrint('Error loading TWAIN sources: $e');
    }
  }

  Future<void> _startScan() async {
    if (_selectedSource == null) return;

    setState(() => _isScanning = true);
    try {
      final sourceIndex = _sources.indexOf(_selectedSource!);
      final result = await _twainScanner.scanDocument(sourceIndex);
      
      if (result.isNotEmpty) {
        // Result is usually a path to a temporary file
        setState(() {
          _capturedImage = File(result.first);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _saveAndClose() async {
    if (_capturedImage == null) return;

    try {
      await ref.read(imagingServiceProvider).saveXray(
        patientId: widget.patientId,
        patientName: widget.patientName,
        imageFile: _capturedImage!,
        label: _labelController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.camera),
          const SizedBox(width: 12),
          Text(AppLocalizations.of(context)!.captureXray),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_capturedImage == null) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedSource,
                decoration: const InputDecoration(labelText: 'Select Sensor/Scanner'),
                items: _sources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _selectedSource = v),
              ),
              const SizedBox(height: 24),
              if (_isScanning)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.waitingForSensorHardware),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _sources.isEmpty ? null : _startScan,
                  icon: const Icon(LucideIcons.play),
                  label: Text(AppLocalizations.of(context)!.initiateCapture),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
            ] else ...[
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                  image: DecorationImage(
                    image: FileImage(_capturedImage!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Image Label'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        if (_capturedImage != null)
          ElevatedButton(
            onPressed: _saveAndClose,
            child: Text(AppLocalizations.of(context)!.saveToPatientRecord),
          ),
      ],
    );
  }
}
