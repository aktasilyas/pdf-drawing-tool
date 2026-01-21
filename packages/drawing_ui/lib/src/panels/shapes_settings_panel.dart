import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/color_presets.dart';
import 'package:drawing_ui/src/widgets/compact_slider.dart';
import 'package:drawing_ui/src/widgets/compact_toggle.dart';
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
          CompactSlider(
            title: 'Kontur kalınlığı',
            value: settings.strokeThickness,
            label: '${settings.strokeThickness.toStringAsFixed(1)}mm',
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
          CompactToggle(
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

/// Grid of available shapes (5x2 = 10 shapes) - compact.
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
      crossAxisCount: 5,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
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

/// Painter for shape icons - 10 şekil.
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

    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    switch (shape) {
      // Row 1
      case ShapeType.line:
        canvas.drawLine(Offset(3, h - 3), Offset(w - 3, 3), paint);

      case ShapeType.arrow:
        canvas.drawLine(Offset(3, h / 2), Offset(w - 3, h / 2), paint);
        canvas.drawLine(Offset(w - 8, 5), Offset(w - 3, h / 2), paint);
        canvas.drawLine(Offset(w - 8, h - 5), Offset(w - 3, h / 2), paint);

      case ShapeType.rectangle:
        canvas.drawRect(Rect.fromLTRB(3, 5, w - 3, h - 5), paint);

      case ShapeType.ellipse:
        canvas.drawOval(Rect.fromLTRB(3, 4, w - 3, h - 4), paint);

      case ShapeType.triangle:
        final path = Path()
          ..moveTo(w / 2, 3)
          ..lineTo(3, h - 3)
          ..lineTo(w - 3, h - 3)
          ..close();
        canvas.drawPath(path, paint);

      // Row 2
      case ShapeType.diamond:
        final path = Path()
          ..moveTo(w / 2, 3)
          ..lineTo(w - 3, h / 2)
          ..lineTo(w / 2, h - 3)
          ..lineTo(3, h / 2)
          ..close();
        canvas.drawPath(path, paint);

      case ShapeType.star:
        _drawStar(canvas, center, 8, paint);

      case ShapeType.pentagon:
        _drawPolygon(canvas, center, 8, 5, paint);

      case ShapeType.hexagon:
        _drawPolygon(canvas, center, 8, 6, paint);

      case ShapeType.plus:
        // Cross/plus shape
        canvas.drawLine(Offset(w / 2, 3), Offset(w / 2, h - 3), paint);
        canvas.drawLine(Offset(3, h / 2), Offset(w - 3, h / 2), paint);
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
