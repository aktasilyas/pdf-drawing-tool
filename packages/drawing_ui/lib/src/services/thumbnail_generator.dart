import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart' hide Page;
import 'package:drawing_core/drawing_core.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

/// Generates thumbnail images for pages.
///
/// Uses Flutter's rendering system to convert page content into PNG thumbnails.
/// Thumbnails are scaled proportionally to fit the specified dimensions.
class ThumbnailGenerator {
  /// Default thumbnail width in pixels.
  static const double defaultWidth = 150;

  /// Default thumbnail height in pixels.
  static const double defaultHeight = 200;

  /// Generates a cache key for a page.
  ///
  /// The key includes the page ID and last update timestamp,
  /// ensuring the cache is invalidated when content changes.
  static String getCacheKey(Page page) {
    return '${page.id}_${page.updatedAt.millisecondsSinceEpoch}';
  }

  /// Generates a thumbnail image for the given page.
  ///
  /// Returns a PNG image as [Uint8List], or null if generation fails.
  ///
  /// The thumbnail is scaled proportionally to fit within [width] x [height],
  /// maintaining the aspect ratio of the page.
  static Future<Uint8List?> generate(
    Page page, {
    double width = defaultWidth,
    double height = defaultHeight,
    Color backgroundColor = Colors.white,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        Paint()..color = backgroundColor,
      );

      // Calculate scale to fit page within thumbnail
      final scaleX = width / page.size.width;
      final scaleY = height / page.size.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      // Center the content
      final scaledWidth = page.size.width * scale;
      final scaledHeight = page.size.height * scale;
      final offsetX = (width - scaledWidth) / 2;
      final offsetY = (height - scaledHeight) / 2;

      canvas.save();
      canvas.translate(offsetX, offsetY);
      canvas.scale(scale);

      // CRITICAL: Render page background (cover color, template pattern, etc.)
      _renderPageBackground(canvas, page);

      // CRITICAL: Render PDF background if exists
      if (page.background.type == BackgroundType.pdf) {
        await _renderPdfBackground(canvas, page);
      }

      // Render all layers
      for (final layer in page.layers) {
        _renderStrokes(canvas, layer.strokes);
        _renderShapes(canvas, layer.shapes);
        _renderTexts(canvas, layer.texts);
      }

      canvas.restore();

      // Convert to PNG
      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      // Return null on any error (e.g., invalid dimensions, rendering issues)
      return null;
    }
  }

  /// Renders page background (cover color, template patterns, etc.)
  static void _renderPageBackground(Canvas canvas, Page page) {
    final background = page.background;

    // 1. Draw base background color
    final bgColor = Color(background.color);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, page.size.width, page.size.height),
      Paint()..color = bgColor,
    );

    // 2. Draw pattern/grid/lines for template types
    final lineColor = background.lineColor ?? 0xFFE0E0E0;
    final linePaint = Paint()
      ..color = Color(lineColor)
      ..strokeWidth = background.templateLineWidth ?? 0.5
      ..isAntiAlias = true;

    switch (background.type) {
      case BackgroundType.blank:
        // Solid color only (for covers)
        break;

      case BackgroundType.grid:
        final spacing = background.gridSpacing ?? 25.0;
        _drawGrid(canvas, Size(page.size.width, page.size.height), linePaint,
            spacing);
        break;

      case BackgroundType.lined:
        final spacing = background.lineSpacing ?? 25.0;
        _drawLines(canvas, Size(page.size.width, page.size.height), linePaint,
            spacing);
        break;

      case BackgroundType.dotted:
        final spacing = background.gridSpacing ?? 20.0;
        _drawDots(canvas, Size(page.size.width, page.size.height), spacing,
            Color(lineColor));
        break;

      case BackgroundType.template:
        // Template patterns (kareli, çizgili vb.)
        if (background.templatePattern != null) {
          _drawTemplatePattern(
            canvas,
            Size(page.size.width, page.size.height),
            background.templatePattern!,
            background.templateSpacingMm ?? 8.0,
            background.templateLineWidth ?? 0.5,
            Color(lineColor),
          );
        }
        break;

      case BackgroundType.pdf:
        // PDF handled separately
        break;
        
      case BackgroundType.cover:
        // Cover backgrounds rendered via PageBackgroundPatternPainter in main canvas
        // Thumbnails will show solid color from background.color
        break;
    }
  }

  /// Draw grid pattern
  static void _drawGrid(Canvas canvas, Size size, Paint paint, double spacing) {
    // Vertical lines
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  /// Draw lined pattern
  static void _drawLines(
      Canvas canvas, Size size, Paint paint, double spacing) {
    final topMargin = spacing * 2;
    for (double y = topMargin; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  /// Draw dotted pattern
  static void _drawDots(Canvas canvas, Size size, double spacing, Color color) {
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

  /// Draw template pattern (simplified for thumbnail)
  static void _drawTemplatePattern(
    Canvas canvas,
    Size size,
    TemplatePattern pattern,
    double spacingMm,
    double lineWidth,
    Color lineColor,
  ) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..isAntiAlias = true;

    // Convert mm to pixels (assuming 96 DPI, 1mm ≈ 3.78 pixels)
    final spacingPx = spacingMm * 3.78;

    switch (pattern) {
      case TemplatePattern.blank:
        break;
      case TemplatePattern.smallGrid:
      case TemplatePattern.mediumGrid:
      case TemplatePattern.largeGrid:
        _drawGrid(canvas, size, paint, spacingPx);
        break;
      case TemplatePattern.thinLines:
      case TemplatePattern.mediumLines:
      case TemplatePattern.thickLines:
        _drawLines(canvas, size, paint, spacingPx);
        break;
      case TemplatePattern.smallDots:
      case TemplatePattern.mediumDots:
      case TemplatePattern.largeDots:
        _drawDots(canvas, size, spacingPx, lineColor);
        break;
      default:
        // For other patterns, draw a simple grid as fallback
        _drawGrid(canvas, size, paint, spacingPx);
        break;
    }
  }

  /// Renders PDF background on canvas.
  ///
  /// Supports both in-memory [pdfData] and lazy-loaded PDFs via [pdfFilePath].
  static Future<void> _renderPdfBackground(
    Canvas canvas,
    Page page,
  ) async {
    if (page.background.pdfPageIndex == null) return;

    try {
      Uint8List? bytes = page.background.pdfData;

      // Lazy-loaded PDF: render from file path
      if (bytes == null && page.background.pdfFilePath != null) {
        bytes = await _renderPdfPageFromFile(
          page.background.pdfFilePath!,
          page.background.pdfPageIndex!,
        );
      }

      if (bytes == null) return;

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final pdfImage = frame.image;

      canvas.drawImageRect(
        pdfImage,
        Rect.fromLTWH(
            0, 0, pdfImage.width.toDouble(), pdfImage.height.toDouble()),
        Rect.fromLTWH(0, 0, page.size.width, page.size.height),
        Paint()..filterQuality = FilterQuality.high,
      );
    } catch (e) {
      // PDF render error - continue silently
    }
  }

  /// Renders a single PDF page from file path, returning PNG bytes.
  static Future<Uint8List?> _renderPdfPageFromFile(
    String filePath,
    int pageIndex,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    pdfx.PdfDocument? document;
    pdfx.PdfPage? pdfPage;
    try {
      document = await pdfx.PdfDocument.openFile(filePath);
      pdfPage = await document.getPage(pageIndex);

      final pageImage = await pdfPage.render(
        width: pdfPage.width * 0.5,
        height: pdfPage.height * 0.5,
        format: pdfx.PdfPageImageFormat.png,
      );

      return pageImage?.bytes;
    } finally {
      try { await pdfPage?.close(); } catch (_) {}
      try { await document?.close(); } catch (_) {}
    }
  }

  /// Renders strokes on the canvas.
  static void _renderStrokes(Canvas canvas, List<Stroke> strokes) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) {
        // Skip strokes with less than 2 points (can't draw a line)
        continue;
      }

      final paint = Paint()
        ..color = Color(stroke.style.color)
        ..strokeWidth = stroke.style.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points.first.x, stroke.points.first.y);

      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].x, stroke.points[i].y);
      }

      canvas.drawPath(path, paint);
    }
  }

  /// Renders shapes on the canvas.
  static void _renderShapes(Canvas canvas, List<Shape> shapes) {
    for (final shape in shapes) {
      final strokePaint = Paint()
        ..color = Color(shape.style.color)
        ..strokeWidth = shape.style.thickness
        ..style = PaintingStyle.stroke;

      Paint? fillPaint;
      if (shape.isFilled && shape.fillColor != null) {
        fillPaint = Paint()
          ..color = Color(shape.fillColor!)
          ..style = PaintingStyle.fill;
      }

      final start = shape.startPoint;
      final end = shape.endPoint;

      switch (shape.type) {
        case ShapeType.line:
          canvas.drawLine(
            Offset(start.x, start.y),
            Offset(end.x, end.y),
            strokePaint,
          );
          break;

        case ShapeType.arrow:
          _drawArrow(canvas, start, end, strokePaint);
          break;

        case ShapeType.rectangle:
          final rect = Rect.fromPoints(
            Offset(start.x, start.y),
            Offset(end.x, end.y),
          );
          if (fillPaint != null) {
            canvas.drawRect(rect, fillPaint);
          }
          canvas.drawRect(rect, strokePaint);
          break;

        case ShapeType.ellipse:
          final rect = Rect.fromPoints(
            Offset(start.x, start.y),
            Offset(end.x, end.y),
          );
          if (fillPaint != null) {
            canvas.drawOval(rect, fillPaint);
          }
          canvas.drawOval(rect, strokePaint);
          break;

        case ShapeType.triangle:
        case ShapeType.diamond:
        default:
          // For now, draw a simple line as placeholder
          canvas.drawLine(
            Offset(start.x, start.y),
            Offset(end.x, end.y),
            strokePaint,
          );
          break;
      }
    }
  }

  /// Draws an arrow from start to end point.
  static void _drawArrow(
    Canvas canvas,
    DrawingPoint start,
    DrawingPoint end,
    Paint paint,
  ) {
    // Draw line
    canvas.drawLine(
      Offset(start.x, start.y),
      Offset(end.x, end.y),
      paint,
    );

    // Calculate arrow head
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final angle = math.atan2(dy, dx);
    final arrowLength = paint.strokeWidth * 3;
    final arrowAngle = 0.5;

    final arrowPoint1 = Offset(
      end.x - arrowLength * math.cos(angle - arrowAngle),
      end.y - arrowLength * math.sin(angle - arrowAngle),
    );
    final arrowPoint2 = Offset(
      end.x - arrowLength * math.cos(angle + arrowAngle),
      end.y - arrowLength * math.sin(angle + arrowAngle),
    );

    canvas.drawLine(Offset(end.x, end.y), arrowPoint1, paint);
    canvas.drawLine(Offset(end.x, end.y), arrowPoint2, paint);
  }

  /// Renders text elements on the canvas.
  static void _renderTexts(Canvas canvas, List<TextElement> texts) {
    for (final textElement in texts) {
      final textStyle = TextStyle(
        color: Color(textElement.color),
        fontSize: textElement.fontSize,
        fontWeight: textElement.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: textElement.isItalic ? FontStyle.italic : FontStyle.normal,
        decoration: textElement.isUnderline
            ? TextDecoration.underline
            : TextDecoration.none,
      );

      final textSpan = TextSpan(
        text: textElement.text,
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textElement.x, textElement.y),
      );
    }
  }
}
