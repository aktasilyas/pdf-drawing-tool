import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// A single color selection chip.
///
/// Displays a colored circle that can be tapped to select a color.
/// Shows a checkmark when selected.
class ColorChip extends StatelessWidget {
  const ColorChip({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.size,
    this.showOpacity = false,
  });

  /// The color to display.
  final Color color;

  /// Whether this chip is currently selected.
  final bool isSelected;

  /// Callback when the chip is tapped.
  final VoidCallback onTap;

  /// Size of the chip (defaults to theme's colorChipSize).
  final double? size;

  /// Whether to show opacity indicator (for semi-transparent colors).
  final bool showOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);
    final chipSize = size ?? theme.colorChipSize;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Checkerboard pattern for transparent colors
          if (showOpacity && (color.a * 255.0).round().clamp(0, 255) < 255)
            Container(
              width: chipSize,
              height: chipSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: ClipOval(
                child: CustomPaint(
                  size: Size(chipSize, chipSize),
                  painter: _CheckerboardPainter(),
                ),
              ),
            ),
          // Color chip
          AnimatedContainer(
            duration: theme.animationDuration,
            curve: theme.animationCurve,
            width: chipSize,
            height: chipSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? theme.toolbarIconSelectedColor
                    : color.computeLuminance() > 0.8
                        ? Colors.grey.shade300
                        : Colors.transparent,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.toolbarIconSelectedColor.withValues(alpha: 60.0 / 255.0),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? PhosphorIcon(
                    StarNoteIcons.check,
                    size: chipSize * 0.5,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// Painter for checkerboard pattern (indicates transparency).
class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = Colors.white;
    final paint2 = Paint()..color = Colors.grey.shade300;
    const squareSize = 4.0;

    for (var x = 0.0; x < size.width; x += squareSize) {
      for (var y = 0.0; y < size.height; y += squareSize) {
        final isEven = ((x ~/ squareSize) + (y ~/ squareSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPainter oldDelegate) => false;
}
