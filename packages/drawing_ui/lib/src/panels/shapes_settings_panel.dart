import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/color_picker_strip.dart';
import 'package:drawing_ui/src/widgets/compact_toggle.dart';
import 'package:drawing_ui/src/widgets/goodnotes_slider.dart';

/// Shapes settings content for popover panel.
class ShapesSettingsPanel extends ConsumerWidget {
  const ShapesSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(shapesSettingsProvider);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Şekil', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
              ),
              PanelCloseButton(
                onTap: () =>
                    ref.read(activePanelProvider.notifier).state = null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ShapeGrid(
            selectedShape: settings.selectedShape,
            onShapeSelected: (s) => ref.read(
                shapesSettingsProvider.notifier).setSelectedShape(s),
          ),
          const SizedBox(height: 12),
          GoodNotesSlider(
            label: 'Kontur Kalınlığı', activeColor: cs.primary,
            value: settings.strokeThickness, min: 0.1, max: 10.0,
            displayValue: '${settings.strokeThickness.toStringAsFixed(1)}mm',
            onChanged: (v) => ref.read(
                shapesSettingsProvider.notifier).setStrokeThickness(v),
          ),
          const SizedBox(height: 10),
          _StripLabel(label: 'Kontur Rengi'),
          const SizedBox(height: 6),
          ColorPickerStrip(
            selectedColor: settings.strokeColor,
            onColorSelected: (c) => ref.read(
                shapesSettingsProvider.notifier).setStrokeColor(c),
          ),
          const SizedBox(height: 8),
          CompactToggle(
            label: 'Şekil dolgusu', value: settings.fillEnabled,
            onChanged: (v) => ref.read(
                shapesSettingsProvider.notifier).setFillEnabled(v),
          ),
          if (settings.fillEnabled) ...[
            const SizedBox(height: 8),
            _StripLabel(label: 'Dolgu Rengi'),
            const SizedBox(height: 6),
            ColorPickerStrip(
              selectedColor: settings.fillColor,
              onColorSelected: (c) => ref.read(
                  shapesSettingsProvider.notifier).setFillColor(c),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section label for color strip.
class _StripLabel extends StatelessWidget {
  const _StripLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
        color: cs.onSurfaceVariant, letterSpacing: 0.5));
  }
}

/// Grid of available shapes.
class _ShapeGrid extends StatelessWidget {
  const _ShapeGrid({
    required this.selectedShape, required this.onShapeSelected,
  });
  final ShapeType selectedShape;
  final ValueChanged<ShapeType> onShapeSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 5, mainAxisSpacing: 6, crossAxisSpacing: 6,
      children: ShapeType.values.map((shape) => _ShapeOption(
        shape: shape, isSelected: shape == selectedShape,
        onTap: () => onShapeSelected(shape),
      )).toList(),
    );
  }
}

/// A single shape option in the grid.
class _ShapeOption extends StatelessWidget {
  const _ShapeOption({
    required this.shape, required this.isSelected, required this.onTap,
  });
  final ShapeType shape;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dk = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer
              : (dk ? cs.surfaceContainerHigh : cs.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? cs.primary
                : cs.outline.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(child: CustomPaint(
          size: const Size(18, 18),
          painter: _ShapeIconPainter(
            shape: shape,
            color: isSelected ? cs.primary : cs.onSurfaceVariant),
        )),
      ),
    );
  }
}

/// Painter for shape icons.
class _ShapeIconPainter extends CustomPainter {
  _ShapeIconPainter({required this.shape, required this.color});
  final ShapeType shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color..style = PaintingStyle.stroke
      ..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    final cx = size.width / 2, cy = size.height / 2;
    final w = size.width, h = size.height;

    switch (shape) {
      case ShapeType.line:
        canvas.drawLine(Offset(3, h - 3), Offset(w - 3, 3), paint);
      case ShapeType.arrow:
        canvas.drawLine(Offset(3, cy), Offset(w - 3, cy), paint);
        canvas.drawLine(Offset(w - 8, 5), Offset(w - 3, cy), paint);
        canvas.drawLine(Offset(w - 8, h - 5), Offset(w - 3, cy), paint);
      case ShapeType.rectangle:
        canvas.drawRect(Rect.fromLTRB(3, 5, w - 3, h - 5), paint);
      case ShapeType.ellipse:
        canvas.drawOval(Rect.fromLTRB(3, 4, w - 3, h - 4), paint);
      case ShapeType.triangle:
        final p = Path()..moveTo(w / 2, 3)..lineTo(3, h - 3)
            ..lineTo(w - 3, h - 3)..close();
        canvas.drawPath(p, paint);
      case ShapeType.diamond:
        final p = Path()..moveTo(w / 2, 3)..lineTo(w - 3, cy)
            ..lineTo(w / 2, h - 3)..lineTo(3, cy)..close();
        canvas.drawPath(p, paint);
      case ShapeType.star:
        _drawStar(canvas, Offset(cx, cy), 8, paint);
      case ShapeType.pentagon:
        _drawPolygon(canvas, Offset(cx, cy), 8, 5, paint);
      case ShapeType.hexagon:
        _drawPolygon(canvas, Offset(cx, cy), 8, 6, paint);
      case ShapeType.plus:
        canvas.drawLine(Offset(w / 2, 3), Offset(w / 2, h - 3), paint);
        canvas.drawLine(Offset(3, cy), Offset(w - 3, cy), paint);
    }
  }

  void _drawPolygon(Canvas c, Offset ctr, double r, int sides, Paint p) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final a = (i * 2 * math.pi / sides) - math.pi / 2;
      final pt = Offset(ctr.dx + r * math.cos(a), ctr.dy + r * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    c.drawPath(path, p);
  }

  void _drawStar(Canvas c, Offset ctr, double r, Paint p) {
    final path = Path();
    const pts = 5;
    final ir = r * 0.4;
    for (int i = 0; i < pts * 2; i++) {
      final rd = i.isEven ? r : ir;
      final a = (i * math.pi / pts) - math.pi / 2;
      final pt = Offset(ctr.dx + rd * math.cos(a), ctr.dy + rd * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ShapeIconPainter o) =>
      shape != o.shape || color != o.color;
}
