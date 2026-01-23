import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

// =============================================================================
// DYNAMIC BACKGROUND PAINTER
// =============================================================================

/// Paints the page background based on PageBackground settings.
/// Supports: blank, grid, lined, dotted patterns.
class DynamicBackgroundPainter extends CustomPainter {
  final PageBackground background;

  const DynamicBackgroundPainter({required this.background});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fill background color
    final bgPaint = Paint()..color = Color(background.color);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Draw pattern based on type
    final lineColor = background.lineColor ?? 0xFFE0E0E0;
    final linePaint = Paint()
      ..color = Color(lineColor)
      ..strokeWidth = 0.5
      ..isAntiAlias = true;

    switch (background.type) {
      case BackgroundType.blank:
        // No pattern - just background color
        break;

      case BackgroundType.grid:
        _drawGrid(canvas, size, linePaint, background.gridSpacing ?? 25.0);
        break;

      case BackgroundType.lined:
        _drawLines(canvas, size, linePaint, background.lineSpacing ?? 25.0);
        break;

      case BackgroundType.dotted:
        _drawDots(canvas, size, linePaint, background.gridSpacing ?? 20.0);
        break;

      case BackgroundType.pdf:
        // PDF background handled separately
        break;
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint, double spacing) {
    // Vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawLines(Canvas canvas, Size size, Paint paint, double spacing) {
    // Only horizontal lines
    for (double y = spacing; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint, double spacing) {
    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    
    const double dotRadius = 1.5;
    
    for (double x = spacing; x <= size.width; x += spacing) {
      for (double y = spacing; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DynamicBackgroundPainter oldDelegate) {
    return oldDelegate.background != background;
  }
}

// =============================================================================
// GRID PAINTER (Legacy - kept for compatibility)
// =============================================================================

/// Paints a grid background for the canvas.
/// @deprecated Use DynamicBackgroundPainter instead
class GridPainter extends CustomPainter {
  /// Grid spacing in logical pixels.
  static const double gridSize = 25.0;

  // CACHED Paint object - NO allocation in paint()!
  static final Paint _gridPaint = Paint()
    ..color = const Color(0xFFE0E0E0)
    ..strokeWidth = 0.5
    ..isAntiAlias = true;

  /// Creates a grid painter.
  const GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        _gridPaint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        _gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    // Grid never changes - NEVER repaint
    return false;
  }
}
