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
  ConsumerState<SensorCaptureDialog> createState() =>
      _SensorCaptureDialogState();
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
      _labelController.text = AppLocalizations.of(
        context,
      )!.intraoralXrayDefault;
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
          SnackBar(
            content: Text('Scan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _saveAndClose() async {
    if (_capturedImage == null) return;

    try {
      await ref
          .read(imagingServiceProvider)
          .saveXray(
            patientId: widget.patientId,
            patientName: widget.patientName,
            imageFile: _capturedImage!,
            label: _labelController.text,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTroubleshooting() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.helpCircle, color: Colors.blue),
            SizedBox(width: 12),
            Text('Sensor Help'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If your sensor (Nanopix) is not listed:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '1. Install TWAIN Drivers: Go to the application folder, open "drivers/XRay" and install the Nanopix driver.',
            ),
            SizedBox(height: 8),
            Text(
              '2. Re-plug Sensor: Unplug the USB, wait 5 seconds, and plug it back in.',
            ),
            SizedBox(height: 8),
            Text(
              '3. Close other apps: Ensure no other X-ray software is currently open or using the sensor.',
            ),
            SizedBox(height: 8),
            Text(
              '4. Restart App: Sometimes a fresh start is needed after installing new drivers.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.camera),
          const SizedBox(width: 12),
          Text(l10n.captureXray),
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
                decoration: InputDecoration(
                  labelText: l10n.selectSensorLabel,
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.helpCircle, size: 20),
                    tooltip: 'Troubleshoot',
                    onPressed: _showTroubleshooting,
                  ),
                ),
                items: _sources
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSource = v),
              ),
              const SizedBox(height: 24),
              if (_isScanning)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.waitingForSensorHardware),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _sources.isEmpty ? null : _startScan,
                  icon: const Icon(LucideIcons.play),
                  label: Text(l10n.initiateCapture),
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
                decoration: InputDecoration(labelText: l10n.addLabel),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        if (_capturedImage != null)
          ElevatedButton(
            onPressed: _saveAndClose,
            child: Text(l10n.saveToPatientRecord),
          ),
      ],
    );
  }
}
