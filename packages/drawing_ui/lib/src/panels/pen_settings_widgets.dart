import 'package:flutter/material.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Darkens a color by the given amount (0.0 to 1.0).
Color darkenColor(Color c, double amt) {
  final h = HSLColor.fromColor(c);
  return h
      .withLightness((h.lightness * (1 - amt)).clamp(0.0, 1.0))
      .toColor();
}

/// Live stroke preview — 50dp height sine wave.
class LiveStrokePreview extends StatelessWidget {
  const LiveStrokePreview({
    super.key,
    required this.color,
    required this.thickness,
    required this.toolType,
  });

  final Color color;
  final double thickness;
  final ToolType toolType;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: CustomPaint(
          size: const Size(double.infinity, 50),
          painter: StrokePainter(color, thickness, toolType, isDark),
        ),
      ),
    );
  }
}

/// Custom painter for the sine wave stroke preview.
class StrokePainter extends CustomPainter {
  StrokePainter(this.color, this.thickness, this.toolType, this.isDark);

  final Color color;
  final double thickness;
  final ToolType toolType;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? darkenColor(color, 0.3) : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(16, size.height / 2);
    for (var x = 16.0; x < size.width - 16; x += 24) {
      path.quadraticBezierTo(
          x + 6, size.height / 2 - 10, x + 12, size.height / 2);
      path.quadraticBezierTo(
          x + 18, size.height / 2 + 10, x + 24, size.height / 2);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(StrokePainter o) =>
      color != o.color ||
      thickness != o.thickness ||
      toolType != o.toolType ||
      isDark != o.isDark;
}

/// GoodNotes-style horizontal pen type selector.
class PenTypeSelector extends StatelessWidget {
  const PenTypeSelector({
    super.key,
    required this.selectedType,
    required this.selectedColor,
    required this.onTypeSelected,
  });

  final ToolType selectedType;
  final Color selectedColor;
  final ValueChanged<ToolType> onTypeSelected;

  static const _types = [
    ToolType.pencil,
    ToolType.ballpointPen,
    ToolType.dashedPen,
    ToolType.brushPen,
    ToolType.rulerPen,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final t in _types)
          PenCard(
            type: t,
            isSelected: t == selectedType,
            selectedColor: selectedColor,
            onTap: () => onTypeSelected(t),
          ),
      ],
    );
  }
}

/// Pen card matching toolbar selection style:
/// Selected → primary pill bg + white icon (Regular weight)
/// Deselected → transparent + grey icon (Light weight)
class PenCard extends StatelessWidget {
  const PenCard({
    super.key,
    required this.type,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final ToolType type;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
            StarNoteIcons.iconForTool(type, active: isSelected),
            size: StarNoteIcons.toolSize,
            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
