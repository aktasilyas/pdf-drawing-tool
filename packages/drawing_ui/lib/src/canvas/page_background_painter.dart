import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/painters/template_pattern_painter.dart';

/// Sayfa içi arka plan pattern çizici (LIMITED mod için).
/// Transform zaten zoom/pan uyguladığı için bu painter
/// sadece sayfa boyutları içinde pattern çizer.
class PageBackgroundPatternPainter extends CustomPainter {
  final PageBackground background;

  const PageBackgroundPatternPainter({required this.background});

  @override
  void paint(Canvas canvas, Size size) {
    final lineColor = background.lineColor ?? 0xFFE0E0E0;
    final linePaint = Paint()
      ..color = Color(lineColor)
      ..strokeWidth = 0.5
      ..isAntiAlias = true;

    switch (background.type) {
      case BackgroundType.blank:
        // No pattern
        break;

      case BackgroundType.grid:
        _drawGrid(canvas, size, linePaint, background.gridSpacing ?? 25.0);
        break;

      case BackgroundType.lined:
        _drawLines(canvas, size, linePaint, background.lineSpacing ?? 25.0);
        break;

      case BackgroundType.dotted:
        _drawDots(canvas, size, background.gridSpacing ?? 20.0, Color(lineColor));
        break;

      case BackgroundType.pdf:
        // PDF background now handled by Image.memory widget
        break;

      case BackgroundType.template:
        // Use TemplatePatternPainter for accurate template rendering
        if (background.templatePattern != null) {
          final templatePainter = TemplatePatternPainter(
            pattern: background.templatePattern!,
            spacingMm: background.templateSpacingMm ?? 8.0,
            lineWidth: background.templateLineWidth ?? 0.5,
            lineColor: Color(lineColor),
            backgroundColor: Colors.transparent, // Already painted by canvas
            pageSize: size,
          );
          templatePainter.paint(canvas, size);
        }
        break;
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint, double spacing) {
    // Vertical lines
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawLines(Canvas canvas, Size size, Paint paint, double spacing) {
    // Top margin (like real notebook paper)
    final topMargin = spacing * 2;
    // Horizontal lines only
    for (double y = topMargin; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDots(Canvas canvas, Size size, double spacing, Color color) {
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const dotRadius = 1.0;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PageBackgroundPatternPainter oldDelegate) {
    return oldDelegate.background != background;
  }
}
