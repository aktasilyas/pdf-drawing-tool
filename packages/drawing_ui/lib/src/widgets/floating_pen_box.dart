import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';

/// Floating pen box that appears on the canvas.
/// Draggable, collapsible, with edit mode for removing pens.
/// Opens horizontally when near top/center, vertically when on edges.
class FloatingPenBox extends ConsumerStatefulWidget {
  const FloatingPenBox({
    super.key,
    this.onPositionChanged,
    this.position = const Offset(12, 12),
  });

  final ValueChanged<Offset>? onPositionChanged;
  final Offset position;

  @override
  ConsumerState<FloatingPenBox> createState() => _FloatingPenBoxState();
}

class _FloatingPenBoxState extends ConsumerState<FloatingPenBox> {
  bool _isExpanded = true;
  bool _isEditMode = false;

  /// Determine if should open horizontally based on position
  bool get _shouldOpenHorizontally {
    final screenWidth = WidgetsBinding
            .instance.platformDispatcher.views.first.physicalSize.width /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final x = widget.position.dx;
    final y = widget.position.dy;

    // If near left edge (< 80px) or right edge → open vertically
    // If in the middle area and near top → open horizontally
    final isNearLeftEdge = x < 80;
    final isNearRightEdge = x > screenWidth - 150;
    final isNearTop = y < 200;

    return !isNearLeftEdge && !isNearRightEdge && isNearTop;
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(penBoxPresetsProvider);
    final activePresets = presets.where((p) => !p.isEmpty).toList();

    if (activePresets.isEmpty) {
      return const SizedBox.shrink();
    }

    final content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isExpanded
          ? (_shouldOpenHorizontally
              ? _buildHorizontalExpandedView(activePresets, presets)
              : _buildVerticalExpandedView(activePresets, presets))
          : _buildCollapsedView(activePresets.length),
    );

    // Collapsed view is draggable
    if (!_isExpanded) {
      return GestureDetector(
        onPanUpdate: (details) {
          widget.onPositionChanged?.call(details.delta);
        },
        child: content,
      );
    }

    return content;
  }

  Widget _buildCollapsedView(int count) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.brush_outlined,
              size: 18,
              color: Colors.grey.shade600,
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A9DFF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vertical layout - for when pen box is near left/right edges
  Widget _buildVerticalExpandedView(
      List<PenPreset> activePresets, List<PenPreset> allPresets) {
    final selectedIndex = ref.watch(selectedPresetIndexProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Presets list (compact)
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: activePresets.asMap().entries.map((entry) {
              final index = allPresets.indexOf(entry.value);
              return _PenPresetItem(
                preset: entry.value,
                isEditMode: _isEditMode,
                isHorizontal: false, // Pen tips point right (into canvas)
                isSelected: index == selectedIndex,
                onTap: () => _onPresetTap(index, entry.value),
                onDelete: () => _deletePreset(index),
              );
            }).toList(),
          ),
        ),

        // Bottom bar with edit and collapse
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button
              GestureDetector(
                onTap: () => setState(() => _isEditMode = !_isEditMode),
                child: Icon(
                  _isEditMode ? Icons.check : Icons.edit_outlined,
                  size: 14,
                  color: _isEditMode ? Colors.green : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 12),
              // Collapse button
              GestureDetector(
                onTap: () => setState(() {
                  _isExpanded = false;
                  _isEditMode = false;
                }),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Horizontal layout - for when pen box is in top/center area
  Widget _buildHorizontalExpandedView(
      List<PenPreset> activePresets, List<PenPreset> allPresets) {
    final selectedIndex = ref.watch(selectedPresetIndexProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Presets list (horizontal)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: activePresets.asMap().entries.map((entry) {
              final index = allPresets.indexOf(entry.value);
              return _PenPresetItem(
                preset: entry.value,
                isEditMode: _isEditMode,
                isHorizontal: true, // Pen tips point down (into canvas)
                isSelected: index == selectedIndex,
                onTap: () => _onPresetTap(index, entry.value),
                onDelete: () => _deletePreset(index),
              );
            }).toList(),
          ),
        ),

        // Right bar with edit and collapse
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button
              GestureDetector(
                onTap: () => setState(() => _isEditMode = !_isEditMode),
                child: Icon(
                  _isEditMode ? Icons.check : Icons.edit_outlined,
                  size: 14,
                  color: _isEditMode ? Colors.green : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              // Collapse button
              GestureDetector(
                onTap: () => setState(() {
                  _isExpanded = false;
                  _isEditMode = false;
                }),
                child: Icon(
                  Icons.keyboard_arrow_left,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onPresetTap(int index, PenPreset preset) {
    if (_isEditMode) return;

    ref.read(selectedPresetIndexProvider.notifier).state = index;
    ref.read(currentToolProvider.notifier).state = preset.toolType;
    ref.read(penSettingsProvider(preset.toolType).notifier)
      ..setColor(preset.color)
      ..setThickness(preset.thickness)
      ..setNibShape(preset.nibShape);
    ref.read(activePanelProvider.notifier).state = null;
  }

  void _deletePreset(int index) {
    ref.read(penBoxPresetsProvider.notifier).removePreset(index);
  }
}

/// A single pen preset item with realistic pen icon and thickness value.
class _PenPresetItem extends StatelessWidget {
  const _PenPresetItem({
    required this.preset,
    required this.onTap,
    required this.onDelete,
    this.isEditMode = false,
    this.isHorizontal = false,
    this.isSelected = false,
  });

  final PenPreset preset;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isEditMode;
  final bool isHorizontal; // true = horizontal layout (pen points down)
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // Pen rotation angle
    final penAngle = isHorizontal ? 0.0 : -1.5708;

    // Soft selection - use pen color with very low opacity
    final bgColor =
        isSelected ? preset.color.withAlpha(18) : Colors.grey.shade50;
    final borderColor =
        isSelected ? preset.color.withAlpha(50) : Colors.transparent;

    if (isHorizontal) {
      // Horizontal item layout
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pen icon centered
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: Transform.rotate(
                        angle: penAngle,
                        child: CustomPaint(
                          size: const Size(22, 22),
                          painter: RealisticPenPainter(
                            toolType: preset.toolType,
                            tipColor: preset.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  // Thickness value
                  Text(
                    preset.thickness
                        .toStringAsFixed(preset.thickness < 1 ? 1 : 0),
                    style: TextStyle(
                      fontSize: 7,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Delete button in edit mode
              if (isEditMode)
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.remove,
                          size: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Vertical item layout
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Delete button in edit mode
            if (isEditMode) ...[
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.remove, size: 10, color: Colors.white),
                ),
              ),
              const SizedBox(width: 4),
            ],

            // Pen icon centered
            SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Transform.rotate(
                  angle: penAngle,
                  child: CustomPaint(
                    size: const Size(22, 22),
                    painter: RealisticPenPainter(
                      toolType: preset.toolType,
                      tipColor: preset.color,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Thickness value
            Text(
              preset.thickness.toStringAsFixed(preset.thickness < 1 ? 1 : 0),
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}

/// Realistic pen painter matching the reference app style.
/// Creates professional-looking pen/marker icons.
class RealisticPenPainter extends CustomPainter {
  RealisticPenPainter({
    required this.toolType,
    required this.tipColor,
  });

  final ToolType toolType;
  final Color tipColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (toolType) {
      case ToolType.pencil:
        _drawPencil(canvas, w, h);
      case ToolType.hardPencil:
        _drawPencil(canvas, w, h); // Use same icon, lighter color
      case ToolType.ballpointPen:
        _drawBallpointPen(canvas, w, h);
      case ToolType.gelPen:
        _drawFountainPen(canvas, w, h); // Reuse fountain pen icon
      case ToolType.dashedPen:
        _drawBallpointPen(canvas, w, h); // Similar to ballpoint
      case ToolType.brushPen:
        _drawBrush(canvas, w, h);
      case ToolType.marker:
        _drawBrush(canvas, w, h); // Similar to brush
      case ToolType.neonHighlighter:
        _drawHighlighter(canvas, w, h);
      case ToolType.highlighter:
        _drawHighlighter(canvas, w, h);
      case ToolType.rulerPen:
        _drawrulerPen(canvas, w, h);
      default:
        _drawBallpointPen(canvas, w, h);
    }
  }

  void _drawBallpointPen(Canvas canvas, double w, double h) {
    // Pen body (white/light gray)
    final bodyPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    final bodyStroke = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Main body
    final bodyPath = Path()
      ..moveTo(w * 0.35, h * 0.05)
      ..lineTo(w * 0.65, h * 0.05)
      ..lineTo(w * 0.62, h * 0.7)
      ..lineTo(w * 0.38, h * 0.7)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, bodyStroke);

    // Colored tip section
    final tipPaint = Paint()
      ..color = tipColor
      ..style = PaintingStyle.fill;

    final tipPath = Path()
      ..moveTo(w * 0.38, h * 0.7)
      ..lineTo(w * 0.62, h * 0.7)
      ..lineTo(w * 0.5, h * 0.95)
      ..close();
    canvas.drawPath(tipPath, tipPaint);

    // Clip ring
    final clipPaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.3, h * 0.08, w * 0.4, h * 0.04),
      clipPaint,
    );
  }

  void _drawFountainPen(Canvas canvas, double w, double h) {
    final bodyPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    final bodyStroke = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Cap
    final capPath = Path()
      ..moveTo(w * 0.32, h * 0.02)
      ..lineTo(w * 0.68, h * 0.02)
      ..lineTo(w * 0.65, h * 0.3)
      ..lineTo(w * 0.35, h * 0.3)
      ..close();
    canvas.drawPath(capPath, bodyPaint);
    canvas.drawPath(capPath, bodyStroke);

    // Body
    final bodyPath = Path()
      ..moveTo(w * 0.35, h * 0.32)
      ..lineTo(w * 0.65, h * 0.32)
      ..lineTo(w * 0.58, h * 0.7)
      ..lineTo(w * 0.42, h * 0.7)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = Colors.white);
    canvas.drawPath(bodyPath, bodyStroke);

    // Nib (colored)
    final nibPaint = Paint()
      ..color = tipColor
      ..style = PaintingStyle.fill;

    final nibPath = Path()
      ..moveTo(w * 0.42, h * 0.7)
      ..lineTo(w * 0.58, h * 0.7)
      ..lineTo(w * 0.5, h * 0.98)
      ..close();
    canvas.drawPath(nibPath, nibPaint);

    // Nib line
    canvas.drawLine(
      Offset(w * 0.5, h * 0.72),
      Offset(w * 0.5, h * 0.92),
      Paint()
        ..color = tipColor.withAlpha(150)
        ..strokeWidth = 1,
    );
  }

  void _drawPencil(Canvas canvas, double w, double h) {
    // Yellow pencil body
    final bodyPaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..style = PaintingStyle.fill;

    final bodyStroke = Paint()
      ..color = const Color(0xFFFF8F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Eraser (pink)
    final eraserPaint = Paint()
      ..color = const Color(0xFFFFB6C1)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.02, w * 0.3, h * 0.1),
        const Radius.circular(2),
      ),
      eraserPaint,
    );

    // Metal band
    canvas.drawRect(
      Rect.fromLTWH(w * 0.33, h * 0.11, w * 0.34, h * 0.06),
      Paint()..color = Colors.grey.shade400,
    );

    // Pencil body
    final bodyPath = Path()
      ..moveTo(w * 0.35, h * 0.17)
      ..lineTo(w * 0.65, h * 0.17)
      ..lineTo(w * 0.6, h * 0.75)
      ..lineTo(w * 0.4, h * 0.75)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, bodyStroke);

    // Wood tip
    final woodPaint = Paint()
      ..color = const Color(0xFFDEB887)
      ..style = PaintingStyle.fill;
    final woodPath = Path()
      ..moveTo(w * 0.4, h * 0.75)
      ..lineTo(w * 0.6, h * 0.75)
      ..lineTo(w * 0.5, h * 0.92)
      ..close();
    canvas.drawPath(woodPath, woodPaint);

    // Graphite tip (colored)
    final tipPaint = Paint()
      ..color = tipColor
      ..style = PaintingStyle.fill;
    final tipPath = Path()
      ..moveTo(w * 0.45, h * 0.88)
      ..lineTo(w * 0.55, h * 0.88)
      ..lineTo(w * 0.5, h * 0.98)
      ..close();
    canvas.drawPath(tipPath, tipPaint);
  }

  void _drawBrush(Canvas canvas, double w, double h) {
    // Handle
    final handlePaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.fill;

    final handlePath = Path()
      ..moveTo(w * 0.4, h * 0.02)
      ..lineTo(w * 0.6, h * 0.02)
      ..lineTo(w * 0.55, h * 0.5)
      ..lineTo(w * 0.45, h * 0.5)
      ..close();
    canvas.drawPath(handlePath, handlePaint);

    // Metal ferrule
    canvas.drawRect(
      Rect.fromLTWH(w * 0.38, h * 0.48, w * 0.24, h * 0.1),
      Paint()..color = Colors.grey.shade400,
    );

    // Brush bristles (colored)
    final bristlePaint = Paint()
      ..color = tipColor
      ..style = PaintingStyle.fill;

    final bristlePath = Path()
      ..moveTo(w * 0.35, h * 0.58)
      ..quadraticBezierTo(w * 0.25, h * 0.75, w * 0.5, h * 0.98)
      ..quadraticBezierTo(w * 0.75, h * 0.75, w * 0.65, h * 0.58)
      ..close();
    canvas.drawPath(bristlePath, bristlePaint);

    // Bristle detail lines
    final linePaint = Paint()
      ..color = tipColor.withAlpha(150)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(w * 0.45, h * 0.6), Offset(w * 0.48, h * 0.88), linePaint);
    canvas.drawLine(
        Offset(w * 0.5, h * 0.6), Offset(w * 0.5, h * 0.92), linePaint);
    canvas.drawLine(
        Offset(w * 0.55, h * 0.6), Offset(w * 0.52, h * 0.88), linePaint);
  }

  void _drawHighlighter(Canvas canvas, double w, double h) {
    // Marker body (white)
    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final bodyStroke = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Cap (colored)
    final capPaint = Paint()
      ..color = tipColor
      ..style = PaintingStyle.fill;

    final capPath = Path()
      ..moveTo(w * 0.28, h * 0.02)
      ..lineTo(w * 0.72, h * 0.02)
      ..lineTo(w * 0.7, h * 0.2)
      ..lineTo(w * 0.3, h * 0.2)
      ..close();
    canvas.drawPath(capPath, capPaint);

    // Main body
    final bodyPath = Path()
      ..moveTo(w * 0.3, h * 0.22)
      ..lineTo(w * 0.7, h * 0.22)
      ..lineTo(w * 0.65, h * 0.7)
      ..lineTo(w * 0.35, h * 0.7)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, bodyStroke);

    // Chisel tip (colored)
    final tipPaint = Paint()
      ..color = tipColor.withAlpha(220)
      ..style = PaintingStyle.fill;

    final tipPath = Path()
      ..moveTo(w * 0.35, h * 0.7)
      ..lineTo(w * 0.65, h * 0.7)
      ..lineTo(w * 0.62, h * 0.85)
      ..lineTo(w * 0.38, h * 0.85)
      ..lineTo(w * 0.5, h * 0.98)
      ..close();
    canvas.drawPath(tipPath, tipPaint);

    // Label area
    canvas.drawRect(
      Rect.fromLTWH(w * 0.35, h * 0.35, w * 0.3, h * 0.2),
      Paint()..color = tipColor.withAlpha(60),
    );
  }

  void _drawrulerPen(Canvas canvas, double w, double h) {
    // Ruler pen - pencil with ruler attached
    
    // Ruler part (left side)
    final rulerPaint = Paint()
      ..color = const Color(0xFFE8D4A8) // Light wood color
      ..style = PaintingStyle.fill;
    
    final rulerPath = Path()
      ..moveTo(w * 0.15, h * 0.1)
      ..lineTo(w * 0.35, h * 0.1)
      ..lineTo(w * 0.35, h * 0.85)
      ..lineTo(w * 0.15, h * 0.85)
      ..close();
    canvas.drawPath(rulerPath, rulerPaint);
    
    // Ruler markings
    final markPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    for (var i = 0; i < 8; i++) {
      final y = h * (0.15 + i * 0.1);
      final markLength = i % 2 == 0 ? w * 0.1 : w * 0.05;
      canvas.drawLine(
        Offset(w * 0.15, y),
        Offset(w * 0.15 + markLength, y),
        markPaint,
      );
    }
    
    // Pencil body (right side, overlapping slightly)
    final bodyPaint = Paint()
      ..color = const Color(0xFF4A7C59) // Green pencil
      ..style = PaintingStyle.fill;
    
    final bodyPath = Path()
      ..moveTo(w * 0.45, h * 0.05)
      ..lineTo(w * 0.75, h * 0.05)
      ..lineTo(w * 0.75, h * 0.65)
      ..lineTo(w * 0.45, h * 0.65)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);
    
    // Pencil tip cone
    final conePaint = Paint()
      ..color = const Color(0xFFDEB887) // Wood color
      ..style = PaintingStyle.fill;
    
    final conePath = Path()
      ..moveTo(w * 0.45, h * 0.65)
      ..lineTo(w * 0.75, h * 0.65)
      ..lineTo(w * 0.6, h * 0.85)
      ..close();
    canvas.drawPath(conePath, conePaint);
    
    // Pencil graphite tip
    final tipPaint = Paint()
      ..color = tipColor
      ..style = PaintingStyle.fill;
    
    final tipPath = Path()
      ..moveTo(w * 0.55, h * 0.82)
      ..lineTo(w * 0.65, h * 0.82)
      ..lineTo(w * 0.6, h * 0.95)
      ..close();
    canvas.drawPath(tipPath, tipPaint);
    
    // Straight line indicator on ruler
    final linePaint = Paint()
      ..color = tipColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.2, h * 0.3),
      Offset(w * 0.2, h * 0.7),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(RealisticPenPainter oldDelegate) {
    return toolType != oldDelegate.toolType || tipColor != oldDelegate.tipColor;
  }
}
