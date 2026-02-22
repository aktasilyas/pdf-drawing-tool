import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/widgets/color_picker_strip.dart';
import 'package:drawing_ui/src/widgets/compact_toggle.dart';
import 'package:drawing_ui/src/widgets/goodnotes_slider.dart';

/// GoodNotes-style highlighter settings panel.
class HighlighterSettingsPanel extends ConsumerWidget {
  const HighlighterSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(highlighterSettingsProvider);
    final currentTool = ref.watch(currentToolProvider);
    final isNeon = currentTool == ToolType.neonHighlighter;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + Close ──
          Row(
            children: [
              Expanded(
                child: Text(
                  isNeon ? 'Neon Fosforlu' : 'Fosforlu Kalem',
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

          // ── Stroke Preview ──
          _HighlighterStrokePreview(
            color: settings.color,
            thickness: settings.thickness,
            isNeon: isNeon,
          ),
          const SizedBox(height: 16),

          // ── Highlighter Type Selector ──
          _HighlighterTypeSelector(
            selectedType: currentTool,
            onTypeSelected: (t) =>
                ref.read(currentToolProvider.notifier).state = t,
          ),
          const SizedBox(height: 20),

          // ── KALINLIK (thickness) ──
          GoodNotesSlider(
            label: 'Kalınlık',
            value: settings.thickness
                .clamp(isNeon ? 8.0 : 10.0, isNeon ? 30.0 : 40.0),
            min: isNeon ? 8.0 : 10.0,
            max: isNeon ? 30.0 : 40.0,
            displayValue: '${settings.thickness.clamp(isNeon ? 8.0 : 10.0, isNeon ? 30.0 : 40.0).toStringAsFixed(0)}mm',
            activeColor: cs.primary,
            onChanged: (v) => ref
                .read(highlighterSettingsProvider.notifier)
                .setThickness(v),
          ),
          const SizedBox(height: 8),

          // ── PARLAKLIK (glow — neon only) ──
          if (isNeon) ...[
            GoodNotesSlider(
              label: 'Parlaklık',
              value: settings.glowIntensity,
              min: 0.1,
              max: 1.0,
              displayValue: '${(settings.glowIntensity * 100).round()}%',
              activeColor: cs.primary,
              onChanged: (v) => ref
                  .read(highlighterSettingsProvider.notifier)
                  .setGlowIntensity(v),
            ),
            const SizedBox(height: 8),
          ],

          // ── Straight-line toggle ──
          CompactToggle(
            label: 'Düz çizgi',
            value: settings.straightLineMode,
            onChanged: (v) => ref
                .read(highlighterSettingsProvider.notifier)
                .setStraightLineMode(v),
          ),
          const SizedBox(height: 16),

          // ── RENK SEÇİCİ ──
          ColorPickerStrip(
            selectedColor: settings.color,
            isHighlighter: true,
            onColorSelected: (c) => ref
                .read(highlighterSettingsProvider.notifier)
                .setColor(c),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stroke preview
// ─────────────────────────────────────────────────────────────────────────────

/// Highlighter-style stroke preview — wide translucent horizontal band.
class _HighlighterStrokePreview extends StatelessWidget {
  const _HighlighterStrokePreview({
    required this.color,
    required this.thickness,
    required this.isNeon,
  });

  final Color color;
  final double thickness;
  final bool isNeon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: _HighlighterSwooshPainter(color, thickness, isNeon),
      ),
    );
  }
}

/// Draws a wide, translucent highlighter-style swoosh.
class _HighlighterSwooshPainter extends CustomPainter {
  _HighlighterSwooshPainter(this.color, this.thickness, this.isNeon);

  final Color color;
  final double thickness;
  final bool isNeon;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.08, h * 0.65)
      ..cubicTo(w * 0.25, h * 0.20, w * 0.40, h * 0.15, w * 0.55, h * 0.40)
      ..cubicTo(w * 0.70, h * 0.65, w * 0.80, h * 0.75, w * 0.92, h * 0.35);

    final strokeW = (thickness * 0.8).clamp(6.0, 24.0);

    if (isNeon) {
      // Glow layer
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW + 8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Main stroke — variable width
    final metrics = path.computeMetrics().first;
    final total = metrics.length;
    const steps = 60;
    final step = total / steps;

    for (var i = 0; i < steps; i++) {
      final seg = metrics.extractPath(i * step, (i + 1) * step);
      final t = i / steps;
      final bell = 4 * t * (1 - t);
      final sw = ui.lerpDouble(strokeW * 0.6, strokeW, bell)!;
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
  bool shouldRepaint(_HighlighterSwooshPainter o) =>
      color != o.color || thickness != o.thickness || isNeon != o.isNeon;
}

// ─────────────────────────────────────────────────────────────────────────────
// Highlighter type selector (matches PenTypeSelector style)
// ─────────────────────────────────────────────────────────────────────────────

class _HighlighterTypeSelector extends StatelessWidget {
  const _HighlighterTypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
  });

  final ToolType selectedType;
  final ValueChanged<ToolType> onTypeSelected;

  static const _types = [ToolType.highlighter, ToolType.neonHighlighter];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _types.map((t) {
        final selected = t == selectedType;
        final icon = t == ToolType.neonHighlighter
            ? PhosphorIconsLight.lightning
            : StarNoteIcons.highlighter;
        return GestureDetector(
          onTap: () => onTypeSelected(t),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}
