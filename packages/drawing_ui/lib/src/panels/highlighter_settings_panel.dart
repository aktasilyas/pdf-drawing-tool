import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/panels/chrome_panel_parts.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';
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
    final palette = ChromePalette.of(context);
    final str = context.drawingStrings;
    final notifier = ref.read(highlighterSettingsProvider.notifier);
    final minTh = isNeon ? 8.0 : 10.0;
    final maxTh = isNeon ? 30.0 : 40.0;
    final thickness = settings.thickness.clamp(minTh, maxTh);

    return Padding(
      padding: const EdgeInsets.all(ChromeSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChromePanelHeader(
            title: isNeon ? str.tools.neonHighlighter : str.tools.highlighter,
            onClose: () => ref.read(activePanelProvider.notifier).state = null,
          ),
          _HighlighterStrokePreview(
            color: settings.color,
            thickness: settings.thickness,
            isNeon: isNeon,
          ),
          const SizedBox(height: ChromeSpacing.sm),
          _HighlighterTypeSelector(
            selectedType: currentTool,
            onTypeSelected: (t) =>
                ref.read(currentToolProvider.notifier).selectTool(t),
          ),
          const ChromeHairline(),
          GoodNotesSlider(
            label: str.panels.thickness,
            value: thickness,
            min: minTh,
            max: maxTh,
            displayValue: '${thickness.toStringAsFixed(0)}mm',
            activeColor: palette.accent,
            onChanged: notifier.setThickness,
          ),
          if (isNeon)
            GoodNotesSlider(
              label: str.panels.glow,
              value: settings.glowIntensity,
              min: 0.1,
              max: 1.0,
              displayValue: '${(settings.glowIntensity * 100).round()}%',
              activeColor: palette.accent,
              onChanged: notifier.setGlowIntensity,
            ),
          CompactToggle(
            label: str.panels.straightLine,
            value: settings.straightLineMode,
            onChanged: notifier.setStraightLineMode,
          ),
          const ChromeHairline(),
          ColorPickerStrip(
            selectedColor: settings.color,
            isHighlighter: true,
            onColorSelected: notifier.setColor,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _types.map((t) {
        final isNeon = t == ToolType.neonHighlighter;
        return ChromeIconButton(
          key: ValueKey('highlighter-type-${t.name}'),
          icon: isNeon
              ? PhosphorIconsLight.lightning
              : ElyanotesIcons.highlighter,
          iconSize: ChromeIconSizes.md,
          tooltip: t.label(context.drawingStrings),
          selected: t == selectedType,
          onPressed: () => onTypeSelected(t),
        );
      }).toList(),
    );
  }
}
