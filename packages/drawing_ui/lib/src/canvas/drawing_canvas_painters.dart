import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';
import 'package:drawing_ui/src/painters/template_pattern_painter.dart';

// =============================================================================
// DYNAMIC BACKGROUND PAINTER
// =============================================================================

/// Paints the page background based on PageBackground settings.
/// Supports: blank, grid, lined, dotted patterns, and PDF images.
class DynamicBackgroundPainter extends CustomPainter {
  final PageBackground background;
  final ui.Image? pdfImage;
  final CanvasColorScheme? colorScheme;

  const DynamicBackgroundPainter({
    required this.background,
    this.pdfImage,
    this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fill background color
    final bgColor = colorScheme?.effectiveBackground(background.color)
        ?? Color(background.color);
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Draw pattern based on type
    final rawLineColor = background.lineColor ?? 0xFFE0E0E0;
    final lineColor = colorScheme?.effectiveLineColor(background.lineColor)
        ?? Color(rawLineColor);
    final linePaint = Paint()
      ..color = lineColor
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
        final dotColor = colorScheme?.effectiveDotColor(background.lineColor)
            ?? lineColor;
        final dotLinePaint = Paint()
          ..color = dotColor
          ..strokeWidth = 0.5
          ..isAntiAlias = true;
        _drawDots(canvas, size, dotLinePaint, background.gridSpacing ?? 20.0);
        break;

      case BackgroundType.pdf:
        // Draw PDF image if available
        if (pdfImage != null) {
          _drawPdfImage(canvas, size, pdfImage!);
        }
        break;

      case BackgroundType.template:
        // Use TemplatePatternPainter for accurate template rendering
        if (background.templatePattern != null) {
          final templatePainter = TemplatePatternPainter(
            pattern: background.templatePattern!,
            spacingMm: background.templateSpacingMm ?? 8.0,
            lineWidth: background.templateLineWidth ?? 0.5,
            lineColor: lineColor,
            backgroundColor: Colors.transparent, // Already painted above
            pageSize: size,
          );
          templatePainter.paint(canvas, size);
        }
        break;
        
      case BackgroundType.cover:
        // Cover backgrounds are rendered via PageBackgroundPatternPainter
        // Drawing canvas painters don't handle cover rendering
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

  void _drawPdfImage(Canvas canvas, Size size, ui.Image image) {
    // Draw image to fill the entire size
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant DynamicBackgroundPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.pdfImage != pdfImage ||
        oldDelegate.colorScheme != colorScheme;
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
