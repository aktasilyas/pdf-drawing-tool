import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart' hide Page;
import 'package:drawing_core/drawing_core.dart';

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

  /// Renders PDF background on canvas
  static Future<void> _renderPdfBackground(
    Canvas canvas,
    Page page,
  ) async {
    if (page.background.pdfFilePath == null || 
        page.background.pdfPageIndex == null) {
      return;
    }

    try {
      // Bu kısım widget context'inden çağrılmalı
      // Alternatif: PDF cache'den direkt oku
      if (page.background.pdfData != null) {
        final bytes = page.background.pdfData!;
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final pdfImage = frame.image;

        // PDF'i page boyutuna sığdır
        canvas.drawImageRect(
          pdfImage,
          Rect.fromLTWH(0, 0, pdfImage.width.toDouble(), pdfImage.height.toDouble()),
          Rect.fromLTWH(0, 0, page.size.width, page.size.height),
          Paint()..filterQuality = FilterQuality.high,
        );
      }
    } catch (e) {
      // PDF render hatası - sessizce devam et
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
          // TODO: Implement triangle and diamond rendering
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
