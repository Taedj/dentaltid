import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/imaging/application/imaging_service.dart';
import 'package:dentaltid/src/features/imaging/domain/xray.dart';
import 'package:dentaltid/src/features/imaging/presentation/xray_viewer.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import 'package:dentaltid/src/features/imaging/presentation/sensor_capture_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

class PatientImagingGallery extends ConsumerStatefulWidget {
  final Patient patient;

  const PatientImagingGallery({super.key, required this.patient});

  @override
  ConsumerState<PatientImagingGallery> createState() => _PatientImagingGalleryState();
}

class _PatientImagingGalleryState extends ConsumerState<PatientImagingGallery> {
  bool _isListMode = false;
  int _gridColumns = 3;
  bool _sortNewestFirst = true;

  @override
  Widget build(BuildContext context) {
    final imagingService = ref.watch(imagingServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<Xray>>(
      future: imagingService.getPatientXrays(widget.patient.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${l10n.error}${snapshot.error}'));
        }

        final xrays = snapshot.data ?? [];
        if (_sortNewestFirst) {
          xrays.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
        } else {
          xrays.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.imagingHistory(xrays.length),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showCaptureOptions(context),
                        icon: const Icon(LucideIcons.camera),
                        label: Text(l10n.newXray),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Visualization Toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // View Toggle
                        IconButton(
                          icon: Icon(LucideIcons.layoutGrid, color: !_isListMode ? Theme.of(context).primaryColor : Colors.grey),
                          onPressed: () => setState(() => _isListMode = false),
                          tooltip: l10n.gridView,
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.list, color: _isListMode ? Theme.of(context).primaryColor : Colors.grey),
                          onPressed: () => setState(() => _isListMode = true),
                          tooltip: l10n.listView,
                        ),
                        
                        const VerticalDivider(width: 24),
                        
                        // Size Slider (Grid Only)
                        if (!_isListMode) ...[
                          const Icon(LucideIcons.zoomIn, size: 16, color: Colors.grey),
                          SizedBox(
                            width: 150,
                            child: Slider(
                              value: _gridColumns.toDouble(),
                              min: 2,
                              max: 6,
                              divisions: 4,
                              label: l10n.columnsCount(_gridColumns),
                              onChanged: (v) => setState(() => _gridColumns = v.toInt()),
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Sort Dropdown
                        Text(l10n.sortBy, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        DropdownButton<bool>(
                          value: _sortNewestFirst,
                          items: [
                            DropdownMenuItem(value: true, child: Text(l10n.timeLatestFirst)),
                            DropdownMenuItem(value: false, child: Text(l10n.timeEarliestFirst)),
                          ],
                          onChanged: (v) => setState(() => _sortNewestFirst = v!),
                          underline: const SizedBox(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (xrays.isEmpty)
               Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.image, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(l10n.noXraysFound, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: _isListMode
                    ? ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: xrays.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final xray = xrays[index];
                          return _XrayListItem(
                            xray: xray,
                            patientName: '${widget.patient.name} ${widget.patient.familyName}',
                            onRefresh: () => setState(() {}),
                          );
                        },
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridColumns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: xrays.length,
                        itemBuilder: (context, index) {
                          final xray = xrays[index];
                          return _XrayThumbnail(
                            xray: xray,
                            patientName: '${widget.patient.name} ${widget.patient.familyName}',
                            onRefresh: () => setState(() {}),
                          );
                        },
                      ),
              ),
          ],
        );
      },
    );
  }

  void _showCaptureOptions(BuildContext parentContext) {
    final l10n = AppLocalizations.of(parentContext)!;
    showModalBottomSheet(
      context: parentContext,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(LucideIcons.hardDrive),
              title: Text(l10n.digitalSensor),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (!mounted) return;
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => SensorCaptureDialog(
                    patientId: widget.patient.id!,
                    patientName: '${widget.patient.name} ${widget.patient.familyName}',
                  ),
                );
                if (result == true) {
                  // Trigger refresh
                   if (mounted) setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.upload),
              title: Text(l10n.uploadFromFile),
              onTap: () async {
                Navigator.pop(sheetContext);
                
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                
                if (result != null && result.files.single.path != null) {
                  if (!mounted) return;
                  final label = await _showLabelDialog(context);
                  
                  if (label != null && mounted) {
                    final patientName = '${widget.patient.name} ${widget.patient.familyName}';
                    try {
                      await ref.read(imagingServiceProvider).saveXray(
                        patientId: widget.patient.id!,
                        patientName: patientName,
                        imageFile: File(result.files.single.path!),
                        label: label,
                      );
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.importSuccess)),
                        );
                        setState(() {});
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.importError(e.toString())),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showLabelDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: l10n.intraoralXrayDefault);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.xrayLabel),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.add)),
        ],
      ),
    );
  }

  }


class _XrayThumbnail extends ConsumerWidget {
  final Xray xray;
  final String patientName;
  final VoidCallback onRefresh;

  const _XrayThumbnail({
    required this.xray,
    required this.patientName,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: xray.notes != null && xray.notes!.isNotEmpty 
          ? l10n.notesLabel(xray.notes!) 
          : l10n.noNotes,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      showDuration: const Duration(seconds: 10),
      textStyle: const TextStyle(fontSize: 16, color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: Text(xray.label)),
                body: XRayViewer(
                  xray: xray,
                  patientName: patientName,
                ),
              ),
            ),
          ).then((_) => onRefresh()); // Refresh on return to show updated notes
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
            image: DecorationImage(
              image: FileImage(File(xray.filePath)),
              fit: BoxFit.cover,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (xray.notes != null && xray.notes!.isNotEmpty)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(LucideIcons.fileText, color: Colors.yellowAccent, size: 16),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: Colors.black54,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          xray.label,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildActionButton(
                        icon: LucideIcons.pencil,
                        color: Colors.blueAccent,
                        onTap: () => _rename(context, ref),
                      ),
                      _buildActionButton(
                        icon: LucideIcons.download,
                        color: Colors.greenAccent,
                        onTap: () => _export(context),
                      ),
                      _buildActionButton(
                        icon: LucideIcons.trash2,
                        color: Colors.redAccent,
                        onTap: () => _delete(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: xray.label);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameXray),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (newLabel != null && newLabel.isNotEmpty && newLabel != xray.label) {
      await ref.read(imagingServiceProvider).updateXray(xray.copyWith(label: newLabel));
      onRefresh();
    }
  }

  Future<void> _export(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      try {
        final sourceFile = File(xray.filePath);
        final fileName = sourceFile.uri.pathSegments.last;
        final targetPath = '$result/$fileName';
        await sourceFile.copy(targetPath);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.exportSuccess(targetPath))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.exportError(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }


  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteXrayConfirmTitle),
        content: Text(l10n.deleteXrayWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(imagingServiceProvider).deleteXray(xray);
      onRefresh();
    }
  }
}

class _XrayListItem extends ConsumerWidget {
  final Xray xray;
  final String patientName;
  final VoidCallback onRefresh;

  const _XrayListItem({
    required this.xray,
    required this.patientName,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Tooltip(
        message: xray.notes != null && xray.notes!.isNotEmpty 
            ? l10n.notesLabel(xray.notes!) 
            : l10n.noNotes,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        showDuration: const Duration(seconds: 10),
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
         decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(xray.filePath),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(xray.label, style: const TextStyle(fontWeight: FontWeight.bold))),
              if (xray.notes != null && xray.notes!.isNotEmpty)
                  const Icon(LucideIcons.fileText, size: 16, color: Colors.orangeAccent),
            ],
          ),
          subtitle: Text(l10n.capturedDate('${xray.capturedAt.day}/${xray.capturedAt.month}/${xray.capturedAt.year}')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.pencil, size: 18, color: Colors.blueAccent),
                onPressed: () => _rename(context, ref),
                tooltip: l10n.edit,
              ),
              IconButton(
                icon: const Icon(LucideIcons.download, size: 18, color: Colors.greenAccent),
                onPressed: () => _export(context),
                tooltip: 'Export',
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
                onPressed: () => _delete(context, ref),
                tooltip: l10n.delete,
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: Text(xray.label)),
                  body: XRayViewer(
                    xray: xray,
                    patientName: patientName,
                  ),
                ),
              ),
            ).then((_) => onRefresh());
          },
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: xray.label);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameXray),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (newLabel != null && newLabel.isNotEmpty && newLabel != xray.label) {
      await ref.read(imagingServiceProvider).updateXray(xray.copyWith(label: newLabel));
      onRefresh();
    }
  }

  Future<void> _export(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      try {
        final sourceFile = File(xray.filePath);
        final fileName = sourceFile.uri.pathSegments.last;
        final targetPath = '$result/$fileName';
        await sourceFile.copy(targetPath);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.exportSuccess(targetPath))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.exportError(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteXrayConfirmTitle),
        content: Text(l10n.deleteXrayWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(imagingServiceProvider).deleteXray(xray);
      onRefresh();
    }
  }
}
