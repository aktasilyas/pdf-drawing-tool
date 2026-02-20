import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/color_picker_strip.dart';
import 'package:drawing_ui/src/widgets/goodnotes_slider.dart';

/// Returns display title based on current mode + line style.
String _titleFor(LaserMode mode, LaserLineStyle style) {
  if (mode == LaserMode.dot) return 'Lazer Nokta';
  return switch (style) {
    LaserLineStyle.solid => 'Lazer Çizgi',
    LaserLineStyle.hollow => 'Lazer Çizgi (Boş)',
    LaserLineStyle.rainbow => 'Lazer Gökkuşağı',
  };
}

/// Laser pointer settings panel — pen popup style.
class LaserPointerPanel extends ConsumerWidget {
  const LaserPointerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(laserSettingsProvider);
    final cs = Theme.of(context).colorScheme;

    final title = _titleFor(settings.mode, settings.lineStyle);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Preview
          _LaserPreview(
            color: settings.color,
            thickness: settings.thickness,
            mode: settings.mode,
            lineStyle: settings.lineStyle,
          ),
          const SizedBox(height: 16),

          // Combined mode + line style selector (4 options)
          _LaserTypeSelector(
            mode: settings.mode,
            lineStyle: settings.lineStyle,
            onSelected: (mode, style) {
              ref.read(laserSettingsProvider.notifier).setMode(mode);
              ref.read(laserSettingsProvider.notifier).setLineStyle(style);
            },
          ),
          const SizedBox(height: 20),

          // Thickness slider
          GoodNotesSlider(
            label: 'KALINLIK',
            value: settings.thickness.clamp(0.5, 5.0),
            min: 0.5,
            max: 5.0,
            displayValue: '${settings.thickness.toStringAsFixed(1)}mm',
            activeColor: cs.primary,
            onChanged: (v) =>
                ref.read(laserSettingsProvider.notifier).setThickness(v),
          ),
          const SizedBox(height: 8),

          // Duration slider
          GoodNotesSlider(
            label: 'SÜRE',
            value: settings.duration.clamp(0.5, 5.0),
            min: 0.5,
            max: 5.0,
            displayValue: '${settings.duration.toStringAsFixed(1)}s',
            activeColor: cs.primary,
            onChanged: (v) =>
                ref.read(laserSettingsProvider.notifier).setDuration(v),
          ),
          // Color strip (hidden for rainbow)
          if (settings.lineStyle != LaserLineStyle.rainbow) ...[
            const SizedBox(height: 16),
            ColorPickerStrip(
              selectedColor: settings.color,
              onColorSelected: (c) =>
                  ref.read(laserSettingsProvider.notifier).setColor(c),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview
// ─────────────────────────────────────────────────────────────────────────────

class _LaserPreview extends StatelessWidget {
  const _LaserPreview({
    required this.color,
    required this.thickness,
    required this.mode,
    required this.lineStyle,
  });

  final Color color;
  final double thickness;
  final LaserMode mode;
  final LaserLineStyle lineStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: _LaserPreviewPainter(color, thickness, mode, lineStyle),
      ),
    );
  }
}

class _LaserPreviewPainter extends CustomPainter {
  _LaserPreviewPainter(this.color, this.thickness, this.mode, this.lineStyle);

  final Color color;
  final double thickness;
  final LaserMode mode;
  final LaserLineStyle lineStyle;

  static const _rainbowColors = [
    Color(0xFFFF0000),
    Color(0xFFFF8800),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF0088FF),
    Color(0xFF8800FF),
    Color(0xFFFF00FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = thickness.clamp(0.5, 5.0);

    if (mode == LaserMode.dot) {
      _drawDot(canvas, Offset(w / 2, h / 2), t);
      return;
    }

    final path = Path()
      ..moveTo(w * 0.10, h * 0.75)
      ..cubicTo(w * 0.20, h * 0.10, w * 0.35, h * 0.05, w * 0.50, h * 0.30)
      ..cubicTo(w * 0.65, h * 0.55, w * 0.75, h * 0.85, w * 0.90, h * 0.25);

    switch (lineStyle) {
      case LaserLineStyle.solid:
        _drawSolid(canvas, path, t);
      case LaserLineStyle.hollow:
        _drawHollow(canvas, path, t);
      case LaserLineStyle.rainbow:
        _drawRainbow(canvas, path, t);
    }
  }

  void _drawSolid(Canvas canvas, Path path, double t) {
    final p = _strokePaint();
    // Layer 1: Wide outer glow
    canvas.drawPath(path, p
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = t * 10
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 6));
    // Layer 2: Middle glow
    canvas.drawPath(path, p
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = t * 5
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 2));
    // Layer 3: Tight bright glow
    canvas.drawPath(path, p
      ..color = color.withValues(alpha: 0.95)
      ..strokeWidth = t * 2.5
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 0.5));
    // Layer 4: White core
    final coreColor = Color.lerp(color, Colors.white, 0.7)!;
    canvas.drawPath(path, p
      ..color = coreColor
      ..strokeWidth = t * 1.2
      ..maskFilter = null);
  }

  void _drawHollow(Canvas canvas, Path path, double t) {
    final p = _strokePaint();
    // Layer 1: Subtle outer glow (narrow)
    canvas.drawPath(path, p
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = t * 6
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 3));
    // Layer 2: Tight inner glow
    canvas.drawPath(path, p
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = t * 3
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 0.8));
    // Layer 3: Sharp solid color core (dominant)
    canvas.drawPath(path, p
      ..color = color
      ..strokeWidth = t * 1.8
      ..maskFilter = null);
  }

  void _drawRainbow(Canvas canvas, Path path, double t) {
    final bounds = path.getBounds();
    final gradient = ui.Gradient.linear(
      bounds.topLeft,
      bounds.bottomRight,
      _rainbowColors,
      List.generate(
        _rainbowColors.length,
        (i) => i / (_rainbowColors.length - 1),
      ),
    );
    final p = _strokePaint();
    // Outer glow
    canvas.drawPath(path, p
      ..shader = gradient
      ..strokeWidth = t * 10
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 6));
    // Middle glow
    canvas.drawPath(path, p
      ..strokeWidth = t * 5
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 2));
    p.shader = null;
    // White core
    canvas.drawPath(path, p
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = t * 1.2
      ..maskFilter = null);
  }

  void _drawDot(Canvas canvas, Offset center, double t) {
    final r = t * 1.5;
    canvas.drawCircle(center, r * 5, Paint()
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, r * 5));
    canvas.drawCircle(center, r * 2.5, Paint()
      ..color = color.withValues(alpha: 0.85)
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, r * 2));
    final coreColor = Color.lerp(color, Colors.white, 0.7)!;
    canvas.drawCircle(center, r, Paint()..color = coreColor);
  }

  Paint _strokePaint() => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  bool shouldRepaint(_LaserPreviewPainter o) =>
      color != o.color || thickness != o.thickness ||
      mode != o.mode || lineStyle != o.lineStyle;
}

// ─────────────────────────────────────────────────────────────────────────────
// Combined type selector (4 options in one row)
// ─────────────────────────────────────────────────────────────────────────────

class _LaserTypeSelector extends StatelessWidget {
  const _LaserTypeSelector({
    required this.mode,
    required this.lineStyle,
    required this.onSelected,
  });

  final LaserMode mode;
  final LaserLineStyle lineStyle;
  final void Function(LaserMode mode, LaserLineStyle style) onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _PillCard(
          icon: PhosphorIconsLight.lineSegment,
          isSelected: mode == LaserMode.line &&
              lineStyle == LaserLineStyle.solid,
          cs: cs,
          onTap: () => onSelected(LaserMode.line, LaserLineStyle.solid),
        ),
        _PillCard(
          icon: PhosphorIconsLight.lineSegments,
          isSelected: mode == LaserMode.line &&
              lineStyle == LaserLineStyle.hollow,
          cs: cs,
          onTap: () => onSelected(LaserMode.line, LaserLineStyle.hollow),
        ),
        _PillCard(
          icon: PhosphorIconsLight.rainbow,
          isSelected: mode == LaserMode.line &&
              lineStyle == LaserLineStyle.rainbow,
          cs: cs,
          onTap: () => onSelected(LaserMode.line, LaserLineStyle.rainbow),
        ),
        _PillCard(
          icon: StarNoteIcons.circle,
          isSelected: mode == LaserMode.dot,
          cs: cs,
          onTap: () => onSelected(LaserMode.dot, lineStyle),
        ),
      ],
    );
  }
}

/// Reusable 40x40 pill card (same as PenCard).
class _PillCard extends StatelessWidget {
  const _PillCard({
    required this.icon,
    required this.isSelected,
    required this.cs,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: PhosphorIcon(
            icon,
            size: StarNoteIcons.toolSize,
            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
