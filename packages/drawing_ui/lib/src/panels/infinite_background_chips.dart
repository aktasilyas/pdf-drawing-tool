import 'package:flutter/material.dart';

import 'package:drawing_ui/src/theme/drawing_colors.dart';
import 'infinite_background_logic.dart';

/// Announces a chip as one selectable button named by its visible label.
/// Child semantics are excluded, so the tap action is exposed here.
Widget _chipSemantics({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
  required Widget child,
}) =>
    Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );

/// Pattern chip: mini pattern icon over a label.
class InfiniteBackgroundPatternChip extends StatelessWidget {
  const InfiniteBackgroundPatternChip({
    super.key,
    required this.label,
    required this.pattern,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final InfiniteBackgroundPattern pattern;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    return Expanded(
      child: _chipSemantics(
        label: label,
        isSelected: isSelected,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            color: isSelected ? cs.primaryContainer : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: cs.primary, width: 2)
                : Border.all(color: cs.outlineVariant, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CustomPaint(
                    painter: MiniPatternPainter(pattern: pattern, color: fg)),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws the 24dp pattern icon. Paints are built once per painter instance.
class MiniPatternPainter extends CustomPainter {
  MiniPatternPainter({required this.pattern, required this.color})
      : _outline = Paint()
          ..color = color
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
        _dot = Paint()
          ..color = color
          ..style = PaintingStyle.fill,
        _line = Paint()
          ..color = color
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

  final InfiniteBackgroundPattern pattern;
  final Color color;
  final Paint _outline;
  final Paint _dot;
  final Paint _line;

  static const _spacing = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    switch (pattern) {
      case InfiniteBackgroundPattern.plain:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Offset.zero & size, const Radius.circular(3)),
            _outline);
      case InfiniteBackgroundPattern.dotted:
        for (double x = _spacing; x < size.width; x += _spacing) {
          for (double y = _spacing; y < size.height; y += _spacing) {
            canvas.drawCircle(Offset(x, y), 1, _dot);
          }
        }
      case InfiniteBackgroundPattern.grid:
        for (double x = _spacing; x < size.width; x += _spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), _line);
        }
        for (double y = _spacing; y < size.height; y += _spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), _line);
        }
    }
  }

  @override
  bool shouldRepaint(covariant MiniPatternPainter old) =>
      old.pattern != pattern || old.color != color;
}

/// Colour swatch chip with a check mark when selected.
class InfiniteBackgroundColorChip extends StatelessWidget {
  const InfiniteBackgroundColorChip({
    super.key,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final int color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onDark = InfiniteBackgroundColors.isDark(color);
    // Contrast-safe colours based on the chip background, not the theme.
    final textColor =
        onDark ? DrawingColors.onDarkPaper : DrawingColors.onLightPaper;
    final checkColor = onDark ? DrawingColors.onDarkPaper : cs.primary;
    return Expanded(
      child: _chipSemantics(
        label: label,
        isSelected: isSelected,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: Color(color),
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: cs.primary, width: 2)
                : Border.all(color: cs.outlineVariant, width: 1),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                Icon(Icons.check, size: 14, color: checkColor),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
