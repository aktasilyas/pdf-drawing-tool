import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/panels/pen_settings_widgets.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/color_picker_strip.dart';
import 'package:drawing_ui/src/widgets/goodnotes_slider.dart';

/// GoodNotes-style pen settings panel.
class PenSettingsPanel extends ConsumerWidget {
  const PenSettingsPanel({super.key, required this.toolType});
  final ToolType toolType;

  static const _penTools = [
    ToolType.pencil,
    ToolType.ballpointPen,
    ToolType.dashedPen,
    ToolType.brushPen,
    ToolType.rulerPen,
  ];

  static double _minTh(ToolType t) => t.penType?.config.minThickness ?? 0.1;
  static double _maxTh(ToolType t) => t.penType?.config.maxThickness ?? 20.0;
  static int _pct(double val, double min, double max) {
    if (max <= min) return 0;
    return ((val - min) / (max - min) * 100).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final active =
        _penTools.contains(currentTool) ? currentTool : toolType;
    final s = ref.watch(penSettingsProvider(active));
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Başlık + Kapat ──
          Row(
            children: [
              Expanded(
                child: Text(
                  active.penType?.config.displayNameTr ?? 'Kalem',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              PanelCloseButton(
                onTap: () =>
                    ref.read(activePanelProvider.notifier).state = null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Stroke Preview — GoodNotes calligraphic swoosh ──
          _StrokePreview(
            color: s.color, thickness: s.thickness, toolType: active,
          ),
          const SizedBox(height: 16),

          // ── Kalem Tipleri (yatay kartlar) ──
          PenTypeSelector(
            selectedType: currentTool,
            selectedColor: s.color,
            onTypeSelected: (t) =>
                ref.read(currentToolProvider.notifier).selectTool(t),
          ),
          const SizedBox(height: 20),

          // ── UÇ KESKİNLİĞİ (thickness) ──
          GoodNotesSlider(
            label: 'Uç Keskinliği',
            value: s.thickness.clamp(_minTh(active), _maxTh(active)),
            min: _minTh(active),
            max: _maxTh(active),
            displayValue: '${_pct(s.thickness, _minTh(active), _maxTh(active))}%',
            activeColor: cs.primary,
            onChanged: (v) =>
                ref.read(penSettingsProvider(active).notifier).setThickness(v),
          ),
          const SizedBox(height: 8),

          // ── BASINÇ DUYARLILIĞI ──
          GoodNotesSlider(
            label: 'Basınç Duyarlılığı',
            value: s.pressureSensitivity,
            min: 0,
            max: 1,
            displayValue: '${(s.pressureSensitivity * 100).round()}%',
            activeColor: cs.primary,
            onChanged: (v) =>
                ref.read(penSettingsProvider(active).notifier).setPressureSensitivity(v),
          ),
          const SizedBox(height: 8),

          // ── ÇİZGİ STABİLİZASYONU ──
          GoodNotesSlider(
            label: 'Çizgi Stabilizasyonu',
            value: s.stabilization,
            min: 0,
            max: 1,
            displayValue: '${(s.stabilization * 100).round()}%',
            activeColor: cs.primary,
            onChanged: (v) =>
                ref.read(penSettingsProvider(active).notifier).setStabilization(v),
          ),
          const SizedBox(height: 16),

          // ── RENK SEÇİCİ ──
          ColorPickerStrip(
            selectedColor: s.color,
            onColorSelected: (c) =>
                ref.read(penSettingsProvider(active).notifier).setColor(c),
          ),
        ],
      ),
    );
  }
}

/// GoodNotes-style stroke preview — changes shape per pen type.
class _StrokePreview extends StatelessWidget {
  const _StrokePreview({
    required this.color,
    required this.thickness,
    required this.toolType,
  });
  final Color color;
  final double thickness;
  final ToolType toolType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: _SwooshPainter(color, thickness, toolType),
      ),
    );
  }
}

/// Draws pen-specific stroke preview:
/// - pencil/ballpoint: calligraphic swoosh with variable width
/// - dashedPen: dashed swoosh
/// - brushPen: thick swoosh with exaggerated width variation
/// - rulerPen: straight horizontal line
class _SwooshPainter extends CustomPainter {
  _SwooshPainter(this.color, this.thickness, this.toolType);
  final Color color;
  final double thickness;
  final ToolType toolType;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (toolType == ToolType.rulerPen) {
      _drawRuler(canvas, size);
      return;
    }

    // S-curve path shared by all other pen types
    final path = Path()
      ..moveTo(w * 0.10, h * 0.75)
      ..cubicTo(w * 0.20, h * 0.10, w * 0.35, h * 0.05, w * 0.50, h * 0.30)
      ..cubicTo(w * 0.65, h * 0.55, w * 0.75, h * 0.85, w * 0.90, h * 0.25);

    if (toolType == ToolType.dashedPen) {
      _drawDashed(canvas, path);
      return;
    }

    _drawVariable(canvas, path);
  }

  /// Ruler pen: clean straight line across the center.
  void _drawRuler(Canvas canvas, Size size) {
    final sw = (thickness * 1.2).clamp(1.5, 8.0);
    final y = size.height / 2;
    canvas.drawLine(
      Offset(size.width * 0.08, y),
      Offset(size.width * 0.92, y),
      Paint()
        ..color = color
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Dashed pen: S-curve with dash pattern.
  void _drawDashed(Canvas canvas, Path path) {
    final sw = (thickness * 1.2).clamp(1.5, 8.0);
    final metrics = path.computeMetrics().first;
    final total = metrics.length;
    final dashLen = sw * 3.5;
    final gapLen = sw * 2.5;
    var d = 0.0;
    var draw = true;
    while (d < total) {
      final len = draw ? dashLen : gapLen;
      final end = (d + len).clamp(0.0, total);
      if (draw) {
        canvas.drawPath(
          metrics.extractPath(d, end),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = sw
            ..strokeCap = StrokeCap.round,
        );
      }
      d = end;
      draw = !draw;
    }
  }

  /// Default: variable-width calligraphic swoosh.
  /// Brush pen gets exaggerated thickness variation.
  void _drawVariable(Canvas canvas, Path path) {
    final isBrush = toolType == ToolType.brushPen;
    final minW = isBrush
        ? (thickness * 0.2).clamp(0.5, 2.0)
        : (thickness * 0.4).clamp(0.8, 3.0);
    final maxW = isBrush
        ? (thickness * 3.0).clamp(3.0, 18.0)
        : (thickness * 2.2).clamp(2.0, 14.0);

    final metrics = path.computeMetrics().first;
    final total = metrics.length;
    const steps = 80;
    final step = total / steps;

    for (var i = 0; i < steps; i++) {
      final seg = metrics.extractPath(i * step, (i + 1) * step);
      final t = i / steps;
      final bell = 4 * t * (1 - t);
      final sw = ui.lerpDouble(minW, maxW, bell)!;
      canvas.drawPath(
        seg,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SwooshPainter o) =>
      color != o.color || thickness != o.thickness || toolType != o.toolType;
}
