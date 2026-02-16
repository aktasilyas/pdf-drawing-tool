import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/goodnotes_slider.dart';

/// Laser pointer settings panel — pen popup style.
///
/// Layout: preview → mode icons → thickness slider → duration slider.
/// Color is handled by the left FloatingQuickColors bar.
class LaserPointerPanel extends ConsumerWidget {
  const LaserPointerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(laserSettingsProvider);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Lazer İşaretçi',
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
          ),
          const SizedBox(height: 16),

          // Mode selector (line / dot)
          _LaserModeSelector(
            selectedMode: settings.mode,
            selectedColor: settings.color,
            onModeSelected: (m) =>
                ref.read(laserSettingsProvider.notifier).setMode(m),
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
        ],
      ),
    );
  }
}

/// Neon-glow preview of the current laser settings.
class _LaserPreview extends StatelessWidget {
  const _LaserPreview({
    required this.color,
    required this.thickness,
    required this.mode,
  });

  final Color color;
  final double thickness;
  final LaserMode mode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: _LaserPreviewPainter(color, thickness, mode),
      ),
    );
  }
}

/// Draws a neon-glow laser preview (S-curve for line, dot for dot mode).
class _LaserPreviewPainter extends CustomPainter {
  _LaserPreviewPainter(this.color, this.thickness, this.mode);

  final Color color;
  final double thickness;
  final LaserMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = thickness.clamp(0.5, 5.0);

    if (mode == LaserMode.dot) {
      _drawDot(canvas, Offset(w / 2, h / 2), t);
      return;
    }

    // S-curve path (same as pen preview)
    final path = Path()
      ..moveTo(w * 0.10, h * 0.75)
      ..cubicTo(w * 0.20, h * 0.10, w * 0.35, h * 0.05, w * 0.50, h * 0.30)
      ..cubicTo(w * 0.65, h * 0.55, w * 0.75, h * 0.85, w * 0.90, h * 0.25);

    // Layer 1: Outer glow
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = t * 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 4),
    );

    // Layer 2: Middle glow
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = t * 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 1.5),
    );

    // Layer 3: Core
    final coreColor = Color.lerp(color, Colors.white, 0.5)!;
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = coreColor
        ..strokeWidth = t * 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawDot(Canvas canvas, Offset center, double t) {
    final r = t * 1.5;

    canvas.drawCircle(
      center,
      r * 4,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, r * 4),
    );

    canvas.drawCircle(
      center,
      r * 2,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, r * 1.5),
    );

    final coreColor = Color.lerp(color, Colors.white, 0.5)!;
    canvas.drawCircle(center, r, Paint()..color = coreColor);
  }

  @override
  bool shouldRepaint(_LaserPreviewPainter o) =>
      color != o.color || thickness != o.thickness || mode != o.mode;
}

/// Two icon buttons for line/dot mode selection.
class _LaserModeSelector extends StatelessWidget {
  const _LaserModeSelector({
    required this.selectedMode,
    required this.selectedColor,
    required this.onModeSelected,
  });

  final LaserMode selectedMode;
  final Color selectedColor;
  final ValueChanged<LaserMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _ModeIcon(
        icon: StarNoteIcons.chartLine,
        label: 'Çizgi',
        isSelected: selectedMode == LaserMode.line,
        accentColor: selectedColor,
        onTap: () => onModeSelected(LaserMode.line),
      ),
      const SizedBox(width: 8),
      _ModeIcon(
        icon: StarNoteIcons.circle,
        label: 'Nokta',
        isSelected: selectedMode == LaserMode.dot,
        accentColor: selectedColor,
        onTap: () => onModeSelected(LaserMode.dot),
      ),
    ]);
  }
}

/// A single mode icon button.
class _ModeIcon extends StatelessWidget {
  const _ModeIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.1)
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : cs.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20,
              color: isSelected ? accentColor : cs.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? accentColor : cs.onSurfaceVariant,
          )),
        ]),
      ),
    );
  }
}
