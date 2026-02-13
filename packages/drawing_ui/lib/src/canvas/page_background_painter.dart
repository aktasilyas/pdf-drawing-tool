import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/canvas_color_scheme.dart';
import 'package:drawing_ui/src/painters/template_pattern_painter.dart';

/// Sayfa içi arka plan pattern çizici (LIMITED mod için).
/// Transform zaten zoom/pan uyguladığı için bu painter
/// sadece sayfa boyutları içinde pattern çizer.
/// 
/// PERFORMANCE: Uses Picture caching to avoid redrawing patterns
class PageBackgroundPatternPainter extends CustomPainter {
  final PageBackground background;
  final CanvasColorScheme? colorScheme;

  // Static cache for pattern pictures
  static final Map<String, ui.Picture> _pictureCache = {};
  static const int _maxCacheSize = 20;

  const PageBackgroundPatternPainter({
    required this.background,
    this.colorScheme,
  });
  
  /// Generate cache key from background properties
  String _getCacheKey(Size size) {
    return '${background.type}_${background.lineColor}_'
        '${background.gridSpacing}_${background.lineSpacing}_'
        '${background.templatePattern}_${background.templateSpacingMm}_'
        '${background.coverId}_${size.width}_${size.height}_'
        '${colorScheme?.hashCode}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    // For PDF and blank, no caching needed
    if (background.type == BackgroundType.pdf || 
        background.type == BackgroundType.blank) {
      return;
    }
    
    // Try to get from cache
    final cacheKey = _getCacheKey(size);
    ui.Picture? cachedPicture = _pictureCache[cacheKey];
    
    if (cachedPicture == null) {
      // Cache miss - draw and cache
      final recorder = ui.PictureRecorder();
      final recordingCanvas = Canvas(recorder);
      
      _drawPattern(recordingCanvas, size);
      
      cachedPicture = recorder.endRecording();
      
      // Evict oldest if cache is full
      if (_pictureCache.length >= _maxCacheSize) {
        _pictureCache.remove(_pictureCache.keys.first);
      }
      
      _pictureCache[cacheKey] = cachedPicture;
    }
    
    // Draw cached picture
    canvas.drawPicture(cachedPicture);
  }
  
  void _drawPattern(Canvas canvas, Size size) {
    final rawLineColor = background.lineColor ?? 0xFFE0E0E0;
    final lineColor = colorScheme?.effectiveLineColor(background.lineColor)
        ?? Color(rawLineColor);
    final linePaint = Paint()
      ..color = lineColor
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
        final dotColor = colorScheme?.effectiveDotColor(background.lineColor)
            ?? lineColor;
        _drawDots(canvas, size, background.gridSpacing ?? 20.0, dotColor);
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
            lineColor: lineColor,
            backgroundColor: Colors.transparent, // Already painted by canvas
            pageSize: size,
          );
          templatePainter.paint(canvas, size);
        }
        break;
        
      case BackgroundType.cover:
        // Render cover background similar to CoverPreviewWidget
        if (background.coverId != null) {
          _drawCoverBackground(canvas, size, background.coverId!);
        }
        break;
    }
  }

  void _drawCoverBackground(Canvas canvas, Size size, String coverId) {
    final cover = CoverRegistry.byId(coverId);
    if (cover == null) return;

    switch (cover.style) {
      case CoverStyle.solid:
        // Solid already painted by canvas background color
        break;

      case CoverStyle.gradient:
        // Gradient
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(cover.primaryColor),
            Color(cover.secondaryColor ?? cover.primaryColor),
          ],
        );
        final paint = Paint()..shader = gradient.createShader(Offset.zero & size);
        canvas.drawRect(Offset.zero & size, paint);
        break;

      case CoverStyle.pattern:
        // Pattern (dots or lines)
        final bgColor = Color(cover.primaryColor);
        final luminance = bgColor.computeLuminance();
        final patternColor = luminance > 0.5
            ? bgColor.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.15);

        if (coverId.contains('dots')) {
          _drawCoverDots(canvas, size, patternColor);
        } else {
          _drawCoverLines(canvas, size, patternColor);
        }
        break;

      case CoverStyle.minimal:
        // Minimal frame (already rendered correctly via solid color)
        // Note: The frame decoration is typically done in UI layer, not canvas
        break;
    }
  }

  void _drawCoverDots(Canvas canvas, Size size, Color patternColor) {
    const spacing = 15.0;
    final paint = Paint()
      ..color = patternColor
      ..style = PaintingStyle.fill;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  void _drawCoverLines(Canvas canvas, Size size, Color patternColor) {
    const spacing = 12.0;
    final paint = Paint()
      ..color = patternColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Diagonal lines
    for (double i = -size.height; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
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
    return oldDelegate.background != background ||
        oldDelegate.colorScheme != colorScheme;
  }
}
