import 'package:flutter/material.dart';

/// Pattern painter for legacy (pre-family) pattern covers.
class LegacyCoverPatternPainter extends CustomPainter {
  final Color backgroundColor;
  final String patternType;

  LegacyCoverPatternPainter({
    required this.backgroundColor,
    required this.patternType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Arka plan
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Desen rengi (kontrast)
    final luminance = backgroundColor.computeLuminance();
    final patternColor = luminance > 0.5
        ? backgroundColor.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.15);

    final paint = Paint()
      ..color = patternColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (patternType == 'dots') {
      // Noktalı desen
      final spacing = 15.0;
      for (double x = spacing / 2; x < size.width; x += spacing) {
        for (double y = spacing / 2; y < size.height; y += spacing) {
          canvas.drawCircle(
            Offset(x, y),
            1.5,
            Paint()
              ..color = patternColor
              ..style = PaintingStyle.fill,
          );
        }
      }
    } else {
      // Çizgili desen (diagonal)
      final spacing = 12.0;
      for (double i = -size.height; i < size.width; i += spacing) {
        canvas.drawLine(
          Offset(i, 0),
          Offset(i + size.height, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(LegacyCoverPatternPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.patternType != patternType;
}
