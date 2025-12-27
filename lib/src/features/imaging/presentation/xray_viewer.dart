import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dentaltid/src/core/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dentaltid/src/features/imaging/domain/xray.dart';
import 'package:dentaltid/src/features/imaging/application/imaging_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

enum MeasurementState { none, firstPoint, secondPoint }

class XRayViewer extends StatefulWidget {
  final Xray xray;
  final String patientName;

  const XRayViewer({
    super.key,
    required this.xray,
    required this.patientName,
  });

  @override
  State<XRayViewer> createState() => _XRayViewerState();
}

class _XRayViewerState extends State<XRayViewer> {
  // Use late to initialize from widget
  late String _currentNotes;

  // Image Transformations
  double _contrast = 1.0;
  double _brightness = 0.0;
  bool _isInverted = false;
  int _rotationQuarterTurns = 0; // 0, 1, 2, 3
  bool _isFlipped = false;
  String _activeFilter = 'None'; // None, Sharpen, Emboss

  // Pan & Zoom
  final TransformationController _transformController = TransformationController();

  // Measurement Tool
  MeasurementState _measureState = MeasurementState.none;
  Offset? _p1;
  Offset? _p2;
  final double _pixelsPerMm = 10.0; // Rough estimation

  // Drawing Tool
  bool _isDrawing = false;
  final List<DrawingStroke> _strokes = [];
  final List<Offset> _currentStroke = [];
  Color _drawColor = Colors.redAccent;
  double _strokeWidth = 3.0;

  // Text Tool
  bool _isTextMode = false;
  final List<TextAnnotation> _textAnnotations = [];

  // Laser Pointer
  Offset? _laserPosition;

  // Zoom Tool
  bool _isZoomTool = false;
  
  // Screenshot Key
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentNotes = widget.xray.notes ?? '';
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _contrast = 1.0;
      _brightness = 0.0;
      _isInverted = false;
      _rotationQuarterTurns = 0;
      _isFlipped = false;
      _activeFilter = 'None';
      _measureState = MeasurementState.none;
      _isDrawing = false;
      _isTextMode = false;
      _isZoomTool = false;
      _drawColor = Colors.redAccent;
      _strokeWidth = 3.0;
      _strokes.clear();
      _currentStroke.clear();
      _textAnnotations.clear();
      _p1 = null;
      _p2 = null;
      _laserPosition = null;
      _transformController.value = Matrix4.identity();
    });
  }

  void _zoomAtPoint(Offset localPoint, double scaleFactor) {
    final Matrix4 oldMatrix = _transformController.value;
    final Matrix4 newMatrix = oldMatrix.clone()
      ..multiply(Matrix4.translationValues(localPoint.dx, localPoint.dy, 0.0))
      ..multiply(Matrix4.diagonal3Values(scaleFactor, scaleFactor, 1.0))
      ..multiply(Matrix4.translationValues(-localPoint.dx, -localPoint.dy, 0.0));

    setState(() {
      _transformController.value = newMatrix;
    });
  }
  
  Future<void> _saveCopy(BuildContext context, WidgetRef ref) async {
    try {
      // 1. Capture Image
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final image = await boundary.toImage(pixelRatio: 3.0); // High res
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      // 2. Write to Temp File
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_edited_xray_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(pngBytes);

      // 3. Save as new Xray Record
      if (context.mounted) {
         await ref.read(imagingServiceProvider).saveXray(
          patientId: widget.xray.patientId,
          patientName: widget.patientName,
          imageFile: tempFile,
          label: 'Copy of ${widget.xray.label}',
          notes: _currentNotes, // Preserve notes in copy
        );
         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.saveCopySuccess)));
         }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save copy: $e')));
      }
    }
  }

  Future<void> _editNotes(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: _currentNotes);
    final l10n = AppLocalizations.of(context)!;
    final newNotes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dentistNotes),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: l10n.clinicalObservationHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text), 
            child: Text(l10n.save)
          ),
        ],
      ),
    );

    if (newNotes != null && newNotes != _currentNotes) {
      await ref.read(imagingServiceProvider).updateXray(widget.xray.copyWith(notes: newNotes));
      if (!context.mounted) return;
      setState(() {
        _currentNotes = newNotes;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer( // Wrap in Consumer to access ref
      builder: (context, ref, _) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // Left Toolbar
          Container(
            width: 60,
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSidebarButton(
                          icon: LucideIcons.fileText,
                          tooltip: l10n.dentistNotes,
                          color: _currentNotes.isNotEmpty ? Colors.yellowAccent : null,
                          onPressed: () => _editNotes(context, ref),
                        ),
                        const Divider(color: Colors.white24, height: 16),
                        _buildSidebarButton(
                          icon: LucideIcons.rotateCw,
                          tooltip: l10n.rotate90,
                          onPressed: () => setState(() => _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4),
                        ),
                        _buildSidebarButton(
                          icon: LucideIcons.flipHorizontal,
                          tooltip: l10n.flipHorizontal,
                          isActive: _isFlipped,
                          onPressed: () => setState(() => _isFlipped = !_isFlipped),
                        ),
                        const Divider(color: Colors.white24, height: 24),
                        _buildSidebarButton(
                          icon: LucideIcons.activity,
                          tooltip: l10n.sharpenFilter,
                          isActive: _activeFilter == 'Sharpen',
                          onPressed: () => setState(() => _activeFilter = _activeFilter == 'Sharpen' ? 'None' : 'Sharpen'),
                        ),
                        _buildSidebarButton(
                          icon: LucideIcons.mountain,
                          tooltip: l10n.embossFilter,
                          isActive: _activeFilter == 'Emboss',
                          onPressed: () => setState(() => _activeFilter = _activeFilter == 'Emboss' ? 'None' : 'Emboss'),
                        ),
                        const Divider(color: Colors.white24, height: 24),
                         _buildSidebarButton(
                          icon: LucideIcons.save,
                          tooltip: l10n.saveCopy,
                          color: Colors.greenAccent,
                          onPressed: () => _saveCopy(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildSidebarButton(
                  icon: LucideIcons.rotateCcw,
                  tooltip: AppLocalizations.of(context)!.resetAll,
                  onPressed: _reset,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white.withValues(alpha: 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.xray.label,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${widget.xray.capturedAt.day}/${widget.xray.capturedAt.month}/${widget.xray.capturedAt.year}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(AppLocalizations.of(context)!.negativeFilter, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Switch(
                            value: _isInverted,
                            onChanged: (v) => setState(() => _isInverted = v),
                            activeTrackColor: AppColors.primary,
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // Canvas
                Expanded(
                  child: ClipRect(
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 0.5,
                      maxScale: 5.0,
                      panEnabled: _measureState == MeasurementState.none && !_isDrawing && !_isTextMode,
                      scaleEnabled: _measureState == MeasurementState.none && !_isDrawing && !_isTextMode,
                      child: MouseRegion(
                        onHover: (event) {
                          if (!_isDrawing && !_isTextMode && !_isZoomTool && _measureState == MeasurementState.none) {
                            setState(() => _laserPosition = event.localPosition);
                          }
                        },
                        onExit: (_) => setState(() => _laserPosition = null),
                        child: Center(
                          child: RepaintBoundary(
                            key: _repaintBoundaryKey,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 1. The Image with Filters
                                ColorFiltered(
                                  colorFilter: _buildColorFilter(),
                                  child: RotatedBox(
                                    quarterTurns: _rotationQuarterTurns,
                                    child: Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()..multiply(Matrix4.diagonal3Values(_isFlipped ? -1.0 : 1.0, 1.0, 1.0)),
                                      child: Image.file(
                                        File(widget.xray.filePath),
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // 2. Drawings
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: DrawingPainter(
                                      strokes: _strokes, 
                                      currentStroke: _currentStroke, 
                                      currentColor: _drawColor, 
                                      currentWidth: _strokeWidth,
                                    ), 
                                  ),
                                ),
                                
                                // 3. Text Annotation Dots & Labels
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: AnnotationDotsPainter(annotations: _textAnnotations),
                                  ),
                                ),
                                ..._textAnnotations.map((t) => Positioned(
                                  left: t.offset.dx + 8,
                                  top: t.offset.dy - 10,
                                  child: Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                     decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                     child: Text(
                                      t.text,
                                      style: TextStyle(color: t.color, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                )),

                                // Laser Pointer Indicator
                                if (_laserPosition != null)
                                  Positioned(
                                    left: _laserPosition!.dx,
                                    top: _laserPosition!.dy,
                                    child: FractionalTranslation(
                                      translation: const Offset(-0.5, -0.5),
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.8),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.red, blurRadius: 10, spreadRadius: 2)
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Measurement visual
                                if (_p1 != null || _p2 != null)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: RulerPainter(p1: _p1, p2: _p2),
                                    ),
                                  ),

                                // --- INTERACTION LAYERS ---

                                // Drawing
                                if (_isDrawing || _laserPosition != null)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onPanStart: (details) => setState(() {
                                        _currentStroke.add(details.localPosition);
                                        _laserPosition = details.localPosition;
                                      }),
                                      onPanUpdate: (details) => setState(() {
                                        _currentStroke.add(details.localPosition);
                                        _laserPosition = details.localPosition;
                                      }),
                                      onPanEnd: (_) => setState(() {
                                        _strokes.add(DrawingStroke(points: List.from(_currentStroke), color: _drawColor, width: _strokeWidth));
                                        _currentStroke.clear();
                                      }),
                                      child: MouseRegion(
                                        onHover: (event) => setState(() => _laserPosition = event.localPosition),
                                        child: Container(color: Colors.transparent),
                                      ),
                                    ),
                                  ),

                                // Text
                                if (_isTextMode)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTapUp: (details) async {
                                        final clickPos = details.localPosition;
                                        setState(() => _laserPosition = clickPos);
                                        final text = await showDialog<String>(
                                          context: context,
                                          builder: (c) {
                                            final ctrl = TextEditingController();
                                            final l10n = AppLocalizations.of(context)!;
                                            return AlertDialog(
                                              title: Text(l10n.addLabel),
                                              content: TextField(
                                                controller: ctrl,
                                                autofocus: true, 
                                                onSubmitted: (v) => Navigator.pop(c, v)
                                              ),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
                                                ElevatedButton(onPressed: () => Navigator.pop(c, ctrl.text), child: Text(l10n.add)),
                                              ],
                                            );
                                          }
                                        );
                                        if (text != null && text.isNotEmpty) {
                                          setState(() => _textAnnotations.add(TextAnnotation(text: text, offset: clickPos, color: _drawColor)));
                                        }
                                      },
                                      child: MouseRegion(
                                        onHover: (event) => setState(() => _laserPosition = event.localPosition),
                                        child: Container(color: Colors.transparent),
                                      ),
                                    ),
                                  ),

                                // Measure
                                if (_measureState != MeasurementState.none)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTapUp: (details) => setState(() {
                                        if (_measureState == MeasurementState.firstPoint) {
                                          _p1 = details.localPosition;
                                          _measureState = MeasurementState.secondPoint;
                                        } else if (_measureState == MeasurementState.secondPoint) {
                                          _p2 = details.localPosition;
                                        }
                                      }),
                                      child: MouseRegion(
                                        onHover: (event) => setState(() => _laserPosition = event.localPosition),
                                        child: Container(color: Colors.transparent),
                                      ),
                                    ),
                                  ),

                                // Zoom
                                if (_isZoomTool)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTapUp: (details) => _zoomAtPoint(details.localPosition, 1.5),
                                      onSecondaryTapUp: (details) => _zoomAtPoint(details.localPosition, 0.75),
                                      child: MouseRegion(
                                        onHover: (event) => setState(() => _laserPosition = event.localPosition),
                                        child: Container(color: Colors.transparent),
                                      ),
                                    ),
                                  ),

                                // Measure Result Text
                                if (_p1 != null && _p2 != null)
                                Positioned(
                                  left: (_p1!.dx + _p2!.dx) / 2,
                                  top: (_p1!.dy + _p2!.dy) / 2,
                                  child: FractionalTranslation(
                                    translation: const Offset(-0.5, -0.5),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                                      child: Text(_calculateDistance(), style: const TextStyle(color: Colors.yellowAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Controls (Brightness/Contrast)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1E1E1E),
                   child: Row(
                    children: [
                      const Icon(LucideIcons.contrast, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _contrast,
                          min: 0.5,
                          max: 3.0,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _contrast = v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(LucideIcons.sun, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _brightness,
                          min: -0.5,
                          max: 0.5,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _brightness = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // --- RIGHT SIDEBAR (Annotation Tools) ---
          Container(
            width: 60,
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                const SizedBox(height: 16),
                  _buildSidebarButton(
                    icon: LucideIcons.search,
                    tooltip: l10n.smartZoomTool,
                    isActive: _isZoomTool,
                    onPressed: () {
                      setState(() {
                        _isDrawing = false;
                        _isTextMode = false;
                        _measureState = MeasurementState.none;
                        _isZoomTool = !_isZoomTool;
                      });
                    },
                  ),
                  const Divider(color: Colors.white24, height: 16),
                  _buildSidebarButton(
                  icon: LucideIcons.ruler,
                  tooltip: l10n.measurementTool,
                  isActive: _measureState != MeasurementState.none,
                  onPressed: () {
                    setState(() {
                      _isDrawing = false; 
                      _isTextMode = false;
                      _isZoomTool = false;
                      if (_measureState == MeasurementState.none) {
                        _measureState = MeasurementState.firstPoint;
                        _p1 = null;
                        _p2 = null;
                      } else {
                        _measureState = MeasurementState.none;
                        _p1 = null;
                        _p2 = null;
                      }
                    });
                  },
                ),
                 _buildSidebarButton(
                  icon: LucideIcons.pencil,
                  tooltip: l10n.draw,
                  isActive: _isDrawing,
                  onPressed: () {
                    setState(() {
                      _measureState = MeasurementState.none;
                      _isTextMode = false;
                      _isZoomTool = false;
                      _isDrawing = !_isDrawing;
                    });
                  },
                ),
                _buildSidebarButton(
                  icon: LucideIcons.type,
                  tooltip: l10n.addText,
                  isActive: _isTextMode,
                  onPressed: () {
                     setState(() {
                      _measureState = MeasurementState.none;
                      _isDrawing = false;
                      _isZoomTool = false;
                      _isTextMode = !_isTextMode;
                    });
                  },
                ),
                if (_strokes.isNotEmpty || _textAnnotations.isNotEmpty)
                  _buildSidebarButton(
                    icon: LucideIcons.undo,
                    tooltip: l10n.undo,
                    color: Colors.orangeAccent,
                    onPressed: () {
                      setState(() {
                        if (_textAnnotations.isNotEmpty && !_isDrawing) {
                          _textAnnotations.removeLast();
                        } else if (_strokes.isNotEmpty) {
                           _strokes.removeLast();
                        }
                      });
                    },
                  ),
                
                // --- BRUSH SIZE & COLOR PICKER (When Drawing or Text active) ---
                if (_isDrawing || _isTextMode) ...[
                   const Divider(color: Colors.white24, height: 24),
                   // Brush Size
                   ...[2.0, 4.0, 8.0].map((w) => 
                     Padding(
                       padding: const EdgeInsets.symmetric(vertical: 4),
                       child: GestureDetector(
                         onTap: () => setState(() => _strokeWidth = w),
                         child: Container(
                           width: w + 10,
                           height: w + 10,
                           decoration: BoxDecoration(
                             color: Colors.white70,
                             shape: BoxShape.circle,
                             border: _strokeWidth == w ? Border.all(color: AppColors.primary, width: 2) : null,
                           ),
                         ),
                       ),
                     )
                   ),
                   const Divider(color: Colors.white24, height: 24),
                   // Colors
                   ...[Colors.redAccent, Colors.greenAccent, Colors.blueAccent, Colors.yellowAccent, Colors.white].map((color) => 
                     Padding(
                       padding: const EdgeInsets.symmetric(vertical: 4),
                       child: GestureDetector(
                         onTap: () => setState(() => _drawColor = color),
                         child: Container(
                           width: 24,
                           height: 24,
                           decoration: BoxDecoration(
                             color: color,
                             shape: BoxShape.circle,
                             border: _drawColor == color ? Border.all(color: AppColors.primary, width: 2) : Border.all(color: Colors.white24),
                           ),
                         ),
                       ),
                     )
                   ),
                ],
                
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
     }
    );
  }

  String _calculateDistance() {
    if (_p1 == null || _p2 == null) return '';
    final pixels = (_p1! - _p2!).distance;
    final mm = pixels / _pixelsPerMm; 
    return '${pixels.toStringAsFixed(0)} px  (~${mm.toStringAsFixed(1)} mm)';
  }

  Widget _buildSidebarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: IconButton(
        icon: Icon(icon, color: isActive ? AppColors.primary : (color ?? Colors.white70)),
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          side: isActive ? BorderSide(color: AppColors.primary) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  ColorFilter _buildColorFilter() {
    double t = (1.0 - _contrast) / 2.0 * 255.0;
    List<double> matrix = [
      _contrast, 0, 0, 0, t + (_brightness * 255.0),
      0, _contrast, 0, 0, t + (_brightness * 255.0),
      0, 0, _contrast, 0, t + (_brightness * 255.0),
      0, 0, 0, 1, 0,
    ];

    if (_isInverted) {
      double tInv = 255.0 - t - (_brightness * 255.0);
      matrix = [
        -_contrast, 0, 0, 0, tInv,
        0, -_contrast, 0, 0, tInv,
        0, 0, -_contrast, 0, tInv,
        0, 0, 0, 1, 0,
      ];
    }
    
    if (_activeFilter == 'Sharpen') {
       matrix[0] *= 1.2; // R
       matrix[6] *= 1.2; // G
       matrix[12] *= 1.3; // B 
    } else if (_activeFilter == 'Emboss') {
       return const ColorFilter.mode(Colors.grey, BlendMode.saturation);
    }

    return ColorFilter.matrix(matrix);
  }
}

class TextAnnotation {
  final String text;
  final Offset offset;
  final Color color;

  TextAnnotation({required this.text, required this.offset, this.color = Colors.yellow});
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  DrawingStroke({required this.points, required this.color, required this.width});
}

class RulerPainter extends CustomPainter {
  final Offset? p1;
  final Offset? p2;

  RulerPainter({this.p1, this.p2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    if (p1 != null) {
      canvas.drawCircle(p1!, 5, paint);
    }

    if (p1 != null && p2 != null) {
      canvas.drawLine(p1!, p2!, paint);
      canvas.drawCircle(p2!, 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RulerPainter oldDelegate) {
    return oldDelegate.p1 != p1 || oldDelegate.p2 != p2;
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentWidth;

  DrawingPainter({
    required this.strokes, 
    required this.currentStroke, 
    required this.currentColor, 
    required this.currentWidth
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Previous strokes
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Current stroke
    if (currentStroke.isNotEmpty) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
     return true; 
  }
}
class AnnotationDotsPainter extends CustomPainter {
  final List<TextAnnotation> annotations;
  AnnotationDotsPainter({required this.annotations});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (var a in annotations) {
      canvas.drawCircle(a.offset, 5, paint); // 10px diameter, centered at offset
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationDotsPainter oldDelegate) => true;
}
