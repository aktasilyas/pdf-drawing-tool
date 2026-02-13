import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';
import 'package:drawing_ui/src/painters/template_pattern_painter.dart';

// =============================================================================
// INFINITE BACKGROUND PAINTER
// =============================================================================

/// Sonsuz arka plan pattern çizer.
/// Zoom ile birlikte pattern de ölçeklenir ama tüm ekranı kaplar.
/// GoodNotes benzeri "sonsuz kağıt" efekti sağlar.
class InfiniteBackgroundPainter extends CustomPainter {
  final PageBackground background;
  final double zoom;
  final Offset offset;
  final CanvasColorScheme? colorScheme;

  const InfiniteBackgroundPainter({
    required this.background,
    this.zoom = 1.0,
    this.offset = Offset.zero,
    this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Arka plan rengi (tüm ekran)
    final bgColor = colorScheme?.effectiveBackground(background.color)
        ?? Color(background.color);
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Pattern çiz (tüm ekranı kaplar)
    final rawLineColor = background.lineColor ?? 0xFFE0E0E0;
    final lineColor = colorScheme?.effectiveLineColor(background.lineColor)
        ?? Color(rawLineColor);
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5
      ..isAntiAlias = true;

    switch (background.type) {
      case BackgroundType.blank:
        // No pattern - sadece renk
        break;

      case BackgroundType.grid:
        _drawInfiniteGrid(canvas, size, linePaint, (background.gridSpacing ?? 25.0) * zoom);
        break;

      case BackgroundType.lined:
        _drawInfiniteLines(canvas, size, linePaint, (background.lineSpacing ?? 25.0) * zoom);
        break;

      case BackgroundType.dotted:
        final dotColor = colorScheme?.effectiveDotColor(background.lineColor)
            ?? lineColor;
        final dotPaint = Paint()
          ..color = dotColor
          ..strokeWidth = 0.5
          ..isAntiAlias = true;
        _drawInfiniteDots(canvas, size, dotPaint, (background.gridSpacing ?? 20.0) * zoom);
        break;

      case BackgroundType.pdf:
        // PDF background handled separately
        break;

      case BackgroundType.template:
        // Use TemplatePatternPainter for accurate template rendering
        // Note: For infinite mode, we render a large tile and it repeats with pan/zoom
        if (background.templatePattern != null) {
          // Calculate effective spacing with zoom
          final spacingMm = background.templateSpacingMm ?? 8.0;
          final effectiveSpacingMm = spacingMm * zoom;
          
          // Only render if zoomed enough to see patterns
          if (effectiveSpacingMm > 1.0) {
            final templatePainter = TemplatePatternPainter(
              pattern: background.templatePattern!,
              spacingMm: spacingMm,
              lineWidth: (background.templateLineWidth ?? 0.5) * zoom,
              lineColor: lineColor,
              backgroundColor: Colors.transparent,
              pageSize: size,
            );
            
            // Apply zoom transformation
            canvas.save();
            canvas.scale(zoom);
            canvas.translate(offset.dx / zoom, offset.dy / zoom);
            templatePainter.paint(canvas, Size(size.width / zoom, size.height / zoom));
            canvas.restore();
          }
        }
        break;
        
      case BackgroundType.cover:
        // Cover backgrounds are rendered via PageBackgroundPatternPainter
        // Not applicable in infinite canvas mode
        break;
    }
  }

  void _drawInfiniteGrid(Canvas canvas, Size size, Paint paint, double spacing) {
    if (spacing < 2) return; // Prevent infinite loop when zoomed out too much
    
    // Calculate start position based on offset to align with canvas
    final startX = offset.dx % spacing;
    final startY = offset.dy % spacing;
    
    // Vertical lines (tüm ekran genişliği)
    for (double x = startX; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Draw lines before startX too
    for (double x = startX - spacing; x >= 0; x -= spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines (tüm ekran yüksekliği)
    for (double y = startY; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double y = startY - spacing; y >= 0; y -= spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawInfiniteLines(Canvas canvas, Size size, Paint paint, double spacing) {
    if (spacing < 2) return; // Prevent infinite loop
    
    // Calculate start position based on offset
    final startY = offset.dy % spacing;
    
    // Horizontal lines (tüm ekran)
    for (double y = startY; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double y = startY - spacing; y >= 0; y -= spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawInfiniteDots(Canvas canvas, Size size, Paint paint, double spacing) {
    // Very zoomed out - use larger spacing to maintain performance
    double effectiveSpacing = spacing;
    if (spacing < 5) {
      // Skip every other dot when very zoomed out
      effectiveSpacing = spacing * 2;
      if (effectiveSpacing < 5) effectiveSpacing = spacing * 4;
      if (effectiveSpacing < 5) return; // Too zoomed out
    }
    
    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    // Scale dot size with zoom, but keep it visible
    final dotRadius = (1.2 * zoom).clamp(0.5, 2.5);
    
    // Calculate start position based on offset
    final startX = offset.dx % effectiveSpacing;
    final startY = offset.dy % effectiveSpacing;

    // Use drawPoints for better performance
    final points = <Offset>[];
    
    // Collect all dot positions
    for (double x = startX - effectiveSpacing; x <= size.width + effectiveSpacing; x += effectiveSpacing) {
      for (double y = startY - effectiveSpacing; y <= size.height + effectiveSpacing; y += effectiveSpacing) {
        if (x >= -dotRadius && x <= size.width + dotRadius &&
            y >= -dotRadius && y <= size.height + dotRadius) {
          points.add(Offset(x, y));
        }
      }
    }
    
    // Draw all points at once
    if (points.isNotEmpty) {
      // For small dots, use drawPoints which is faster
      if (dotRadius <= 1.5) {
        canvas.drawPoints(
          PointMode.points,
          points,
          dotPaint..strokeWidth = dotRadius * 2..strokeCap = StrokeCap.round,
        );
      } else {
        // For larger dots, draw circles
        for (final point in points) {
          canvas.drawCircle(point, dotRadius, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant InfiniteBackgroundPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offset != offset ||
        oldDelegate.colorScheme != colorScheme;
  }
}
