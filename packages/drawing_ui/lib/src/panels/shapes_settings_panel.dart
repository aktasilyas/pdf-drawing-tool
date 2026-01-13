import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/unified_color_picker.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';

/// Settings panel for the shapes tool.
///
/// Allows selecting shape type, stroke/fill colors, and thickness.
/// 24 shapes arranged in a 6x4 grid.
class ShapesSettingsPanel extends ConsumerWidget {
  const ShapesSettingsPanel({
    super.key,
    this.onClose,
  });

  /// Callback when panel is closed.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(shapesSettingsProvider);

    return ToolPanel(
      title: 'Şekil',
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shape selector grid (6x4)
          _ShapeGrid(
            selectedShape: settings.selectedShape,
            onShapeSelected: (shape) {
              ref.read(shapesSettingsProvider.notifier).setSelectedShape(shape);
            },
          ),
          const SizedBox(height: 12),

          // Stroke thickness - compact
          _CompactSlider(
            label: 'Kontur kalınlığı',
            value: settings.strokeThickness,
            valueLabel: '${settings.strokeThickness.toStringAsFixed(1)}mm',
            min: 0.1,
            max: 10.0,
            onChanged: (value) {
              ref.read(shapesSettingsProvider.notifier).setStrokeThickness(value);
            },
          ),
          const SizedBox(height: 10),

          // Stroke color - unified color picker
          _ColorSection(
            label: 'Kontur rengi',
            selectedColor: settings.strokeColor,
            onColorSelected: (color) {
              ref.read(shapesSettingsProvider.notifier).setStrokeColor(color);
            },
          ),
          const SizedBox(height: 8),

          // Fill toggle - compact
          _CompactToggle(
            label: 'Şekil dolgusu',
            value: settings.fillEnabled,
            onChanged: (value) {
              ref.read(shapesSettingsProvider.notifier).setFillEnabled(value);
            },
          ),

          // Fill color (only shown if fill is enabled)
          if (settings.fillEnabled) ...[
            const SizedBox(height: 8),
            _ColorSection(
              label: 'Dolgu rengi',
              selectedColor: settings.fillColor,
              onColorSelected: (color) {
                ref.read(shapesSettingsProvider.notifier).setFillColor(color);
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Color section using unified color picker.
class _ColorSection extends StatelessWidget {
  const _ColorSection({
    required this.label,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final String label;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        UnifiedColorPicker(
          selectedColor: selectedColor,
          onColorSelected: onColorSelected,
          quickColors: ColorSets.quickAccess,
          colorSets: ColorSets.all,
          chipSize: 24.0,
          spacing: 6.0,
        ),
      ],
    );
  }
}

/// Compact slider
class _CompactSlider extends StatelessWidget {
  const _CompactSlider({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String valueLabel;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 24,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: const Color(0xFF4A9DFF),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFF4A9DFF),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact toggle
class _CompactToggle extends StatelessWidget {
  const _CompactToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF444444),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF4A9DFF),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of available shapes (6x4 = 24 shapes) - compact.
class _ShapeGrid extends StatelessWidget {
  const _ShapeGrid({
    required this.selectedShape,
    required this.onShapeSelected,
  });

  final ShapeType selectedShape;
  final ValueChanged<ShapeType> onShapeSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 6,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.0,
      children: ShapeType.values.map((shape) {
        return _ShapeOption(
          shape: shape,
          isSelected: shape == selectedShape,
          onTap: () => onShapeSelected(shape),
        );
      }).toList(),
    );
  }
}

/// A single shape option in the grid - compact.
class _ShapeOption extends StatelessWidget {
  const _ShapeOption({
    required this.shape,
    required this.isSelected,
    required this.onTap,
  });

  final ShapeType shape;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A9DFF).withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A9DFF) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(18, 18),
            painter: _ShapeIconPainter(
              shape: shape,
              color: isSelected ? const Color(0xFF4A9DFF) : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter for shape icons.
class _ShapeIconPainter extends CustomPainter {
  _ShapeIconPainter({
    required this.shape,
    required this.color,
  });

  final ShapeType shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    switch (shape) {
      // Row 1 - Lines
      case ShapeType.line:
        canvas.drawLine(Offset(3, h - 3), Offset(w - 3, 3), paint);

      case ShapeType.wavyLine:
        final path = Path()
          ..moveTo(3, h / 2)
          ..cubicTo(w * 0.25, h * 0.2, w * 0.25, h * 0.8, w * 0.5, h / 2)
          ..cubicTo(w * 0.75, h * 0.2, w * 0.75, h * 0.8, w - 3, h / 2);
        canvas.drawPath(path, paint);

      case ShapeType.curvedLine:
        final path = Path()
          ..moveTo(3, h - 3)
          ..quadraticBezierTo(w / 2, 0, w - 3, h - 3);
        canvas.drawPath(path, paint);

      case ShapeType.dashedLine:
        _drawDashedLine(canvas, Offset(3, h / 2), Offset(w - 3, h / 2), paint);

      case ShapeType.arrowRight:
        canvas.drawLine(Offset(3, h / 2), Offset(w - 3, h / 2), paint);
        canvas.drawLine(Offset(w - 8, 5), Offset(w - 3, h / 2), paint);
        canvas.drawLine(Offset(w - 8, h - 5), Offset(w - 3, h / 2), paint);

      case ShapeType.doubleArrow:
        canvas.drawLine(Offset(6, h / 2), Offset(w - 6, h / 2), paint);
        // Left arrow
        canvas.drawLine(Offset(3, h / 2), Offset(8, 5), paint);
        canvas.drawLine(Offset(3, h / 2), Offset(8, h - 5), paint);
        // Right arrow
        canvas.drawLine(Offset(w - 3, h / 2), Offset(w - 8, 5), paint);
        canvas.drawLine(Offset(w - 3, h / 2), Offset(w - 8, h - 5), paint);

      // Row 2 - Lines/Symbols
      case ShapeType.curvedArrow:
        final path = Path()
          ..moveTo(5, h - 5)
          ..quadraticBezierTo(w / 2, 3, w - 5, h / 2);
        canvas.drawPath(path, paint);
        // Arrow head
        canvas.drawLine(Offset(w - 5, h / 2), Offset(w - 10, h / 2 - 4), paint);
        canvas.drawLine(Offset(w - 5, h / 2), Offset(w - 9, h / 2 + 5), paint);

      case ShapeType.angle:
        canvas.drawLine(Offset(5, 5), Offset(5, h - 5), paint);
        canvas.drawLine(Offset(5, h - 5), Offset(w - 5, h - 5), paint);

      case ShapeType.plus:
        canvas.drawLine(Offset(w / 2, 4), Offset(w / 2, h - 4), paint);
        canvas.drawLine(Offset(4, h / 2), Offset(w - 4, h / 2), paint);

      case ShapeType.tShape:
        canvas.drawLine(Offset(4, 6), Offset(w - 4, 6), paint);
        canvas.drawLine(Offset(w / 2, 6), Offset(w / 2, h - 4), paint);

      case ShapeType.bracket:
        final path = Path()
          ..moveTo(w - 6, 4)
          ..quadraticBezierTo(6, 4, 6, h / 2)
          ..quadraticBezierTo(6, h - 4, w - 6, h - 4);
        canvas.drawPath(path, paint);

      case ShapeType.triangleArrow:
        final path = Path()
          ..moveTo(w - 4, h / 2)
          ..lineTo(4, 4)
          ..lineTo(4, h - 4)
          ..close();
        canvas.drawPath(path, paint);

      // Row 3 - Basic Shapes
      case ShapeType.triangleUp:
        final path = Path()
          ..moveTo(w / 2, 4)
          ..lineTo(4, h - 4)
          ..lineTo(w - 4, h - 4)
          ..close();
        canvas.drawPath(path, paint);

      case ShapeType.triangleCorner:
        final path = Path()
          ..moveTo(4, 4)
          ..lineTo(4, h - 4)
          ..lineTo(w - 4, h - 4)
          ..close();
        canvas.drawPath(path, paint);

      case ShapeType.triangleRight:
        final path = Path()
          ..moveTo(4, 4)
          ..lineTo(4, h - 4)
          ..lineTo(w - 4, h / 2)
          ..close();
        canvas.drawPath(path, paint);

      case ShapeType.squareFilled:
        canvas.drawRect(
          Rect.fromLTRB(5, 5, w - 5, h - 5),
          fillPaint,
        );

      case ShapeType.rectangle:
        canvas.drawRect(
          Rect.fromLTRB(3, 6, w - 3, h - 6),
          paint,
        );

      case ShapeType.rightTriangle:
        final path = Path()
          ..moveTo(4, 4)
          ..lineTo(4, h - 4)
          ..lineTo(w - 4, h - 4)
          ..close();
        canvas.drawPath(path, paint);

      // Row 4 - More Shapes
      case ShapeType.squareOutline:
        canvas.drawRect(
          Rect.fromLTRB(5, 5, w - 5, h - 5),
          paint,
        );

      case ShapeType.rectangleOutline:
        canvas.drawRect(
          Rect.fromLTRB(3, 6, w - 3, h - 6),
          paint,
        );

      case ShapeType.diamond:
        final path = Path()
          ..moveTo(w / 2, 4)
          ..lineTo(w - 4, h / 2)
          ..lineTo(w / 2, h - 4)
          ..lineTo(4, h / 2)
          ..close();
        canvas.drawPath(path, paint);

      case ShapeType.pentagon:
        _drawPolygon(canvas, center, 10, 5, paint);

      case ShapeType.hexagon:
        _drawPolygon(canvas, center, 10, 6, paint);

      case ShapeType.star:
        _drawStar(canvas, center, 10, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final distance = (end - start).distance;
    final dx = (end.dx - start.dx) / distance;
    final dy = (end.dy - start.dy) / distance;

    var x = start.dx;
    var y = start.dy;
    var drawn = 0.0;

    while (drawn < distance) {
      final dashEnd = math.min(drawn + dashWidth, distance);
      canvas.drawLine(
        Offset(x, y),
        Offset(start.dx + dx * dashEnd, start.dy + dy * dashEnd),
        paint,
      );
      drawn += dashWidth + dashSpace;
      x = start.dx + dx * drawn;
      y = start.dy + dy * drawn;
    }
  }

  void _drawPolygon(Canvas canvas, Offset center, double radius, int sides, Paint paint) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - math.pi / 2;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (i * math.pi / points) - math.pi / 2;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ShapeIconPainter oldDelegate) {
    return shape != oldDelegate.shape || color != oldDelegate.color;
  }
}
