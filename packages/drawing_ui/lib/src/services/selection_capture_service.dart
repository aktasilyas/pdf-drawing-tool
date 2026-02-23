import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:pasteboard/pasteboard.dart';

import 'package:drawing_ui/src/canvas/image_painter.dart';

/// Service for capturing selected elements as PNG images.
///
/// Renders strokes, shapes, images, and texts to an offscreen canvas,
/// then provides save-to-gallery and copy-to-clipboard functionality.
class SelectionCaptureService {
  const SelectionCaptureService._();

  /// Captures the selected elements as a PNG image.
  ///
  /// Returns PNG bytes, or null if rendering fails.
  /// Renders the page [background] (color, pattern, PDF) behind elements.
  static Future<Uint8List?> captureSelection({
    required Selection selection,
    required Layer layer,
    required ImageCacheManager cacheManager,
    PageBackground? background,
    Uint8List? pdfImageBytes,
    Size? pageSize,
    double padding = 16.0,
  }) async {
    try {
      final bounds = selection.bounds;
      final w = bounds.right - bounds.left + padding * 2;
      final h = bounds.bottom - bounds.top + padding * 2;
      if (w <= 0 || h <= 0) return null;

      // Decode PDF background image before recording (async operation)
      ui.Image? pdfImage;
      if (background?.type == BackgroundType.pdf && pdfImageBytes != null) {
        pdfImage = await _decodePdfImage(pdfImageBytes);
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Background color (from page background or white default)
      final bgColor =
          background != null ? Color(background.color) : Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = bgColor);

      // Translate so selection bounds start at (padding, padding)
      canvas.translate(-bounds.left + padding, -bounds.top + padding);

      // Render background pattern clipped to selection area
      if (background != null) {
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(
            bounds.left, bounds.top, bounds.right, bounds.bottom));
        _renderBackground(canvas, background, pdfImage, pageSize);
        canvas.restore();
      }

      // Render selected strokes
      final strokeIds = selection.selectedStrokeIds.toSet();
      final selectedStrokes =
          layer.strokes.where((s) => strokeIds.contains(s.id)).toList();
      _renderStrokes(canvas, selectedStrokes);

      // Render selected shapes
      final shapeIds = selection.selectedShapeIds.toSet();
      final selectedShapes =
          layer.shapes.where((s) => shapeIds.contains(s.id)).toList();
      _renderShapes(canvas, selectedShapes);

      // Render selected images
      final imageIds = selection.selectedImageIds.toSet();
      final selectedImages =
          layer.images.where((i) => imageIds.contains(i.id)).toList();
      _renderImages(canvas, selectedImages, cacheManager);

      // Render selected texts
      final textIds = selection.selectedTextIds.toSet();
      final selectedTexts =
          layer.texts.where((t) => textIds.contains(t.id)).toList();
      _renderTexts(canvas, selectedTexts);

      final picture = recorder.endRecording();
      final image = await picture.toImage(w.ceil(), h.ceil());
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('SelectionCaptureService: captureSelection failed: $e');
      return null;
    }
  }

  /// Saves PNG bytes to the device gallery.
  static Future<bool> saveToGallery(Uint8List bytes) async {
    try {
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'starnote_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result is Map) {
        return result['isSuccess'] == true;
      }
      return result != null;
    } catch (e) {
      debugPrint('SelectionCaptureService: saveToGallery failed: $e');
      return false;
    }
  }

  /// Copies PNG bytes to the system clipboard.
  static Future<bool> copyToClipboard(Uint8List bytes) async {
    try {
      await Pasteboard.writeImage(bytes);
      return true;
    } catch (e) {
      debugPrint('SelectionCaptureService: copyToClipboard failed: $e');
      return false;
    }
  }

  // ── Rendering helpers (adapted from ThumbnailGenerator) ──

  static void _renderStrokes(Canvas canvas, List<Stroke> strokes) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = Color(stroke.style.color)
        ..strokeWidth = stroke.style.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(stroke.points.first.x, stroke.points.first.y);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].x, stroke.points[i].y);
      }
      canvas.drawPath(path, paint);
    }
  }

  static void _renderShapes(Canvas canvas, List<Shape> shapes) {
    for (final shape in shapes) {
      final sp = Paint()
        ..color = Color(shape.style.color)
        ..strokeWidth = shape.style.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      Paint? fp;
      if (shape.isFilled && shape.fillColor != null) {
        fp = Paint()..color = Color(shape.fillColor!)..style = PaintingStyle.fill;
      }
      final s = Offset(shape.startPoint.x, shape.startPoint.y);
      final e = Offset(shape.endPoint.x, shape.endPoint.y);
      final rect = Rect.fromPoints(s, e);
      switch (shape.type) {
        case ShapeType.line:
          canvas.drawLine(s, e, sp);
        case ShapeType.arrow:
          canvas.drawLine(s, e, sp);
          final angle = math.atan2(e.dy - s.dy, e.dx - s.dx);
          final al = sp.strokeWidth * 3;
          for (final aa in [0.5, -0.5]) {
            canvas.drawLine(e,
                Offset(e.dx - al * math.cos(angle - aa),
                    e.dy - al * math.sin(angle - aa)), sp);
          }
        case ShapeType.rectangle:
          if (fp != null) canvas.drawRect(rect, fp);
          canvas.drawRect(rect, sp);
        case ShapeType.ellipse:
          if (fp != null) canvas.drawOval(rect, fp);
          canvas.drawOval(rect, sp);
        default:
          canvas.drawLine(s, e, sp);
      }
    }
  }

  static void _renderImages(
      Canvas canvas, List<ImageElement> images, ImageCacheManager cache) {
    for (final el in images) {
      final img = cache.get(el.filePath);
      if (img == null) continue;
      canvas.save();
      if (el.rotation != 0.0) {
        final cx = el.x + el.width / 2, cy = el.y + el.height / 2;
        canvas.translate(cx, cy);
        canvas.rotate(el.rotation);
        canvas.translate(-cx, -cy);
      }
      final src = Rect.fromLTWH(
          0, 0, img.width.toDouble(), img.height.toDouble());
      canvas.drawImageRect(
          img, src, Rect.fromLTWH(el.x, el.y, el.width, el.height), Paint());
      canvas.restore();
    }
  }

  static void _renderTexts(Canvas canvas, List<TextElement> texts) {
    for (final t in texts) {
      if (t.text.isEmpty) continue;
      final style = ui.TextStyle(
        color: Color(t.color), fontSize: t.fontSize, fontFamily: t.fontFamily,
        fontWeight: t.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: t.isItalic ? FontStyle.italic : FontStyle.normal,
        decoration: t.isUnderline ? TextDecoration.underline : TextDecoration.none,
      );
      final align = switch (t.alignment) {
        TextAlignment.left => ui.TextAlign.left,
        TextAlignment.center => ui.TextAlign.center,
        TextAlignment.right => ui.TextAlign.right,
      };
      final p = (ui.ParagraphBuilder(
          ui.ParagraphStyle(textAlign: align, maxLines: null))
            ..pushStyle(style)..addText(t.text))
          .build()..layout(ui.ParagraphConstraints(width: t.width ?? 1000.0));
      canvas.drawParagraph(p, Offset(t.x, t.y));
    }
  }

  // ── Background rendering helpers ──

  static Future<ui.Image?> _decodePdfImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('SelectionCaptureService: decode PDF image failed: $e');
      return null;
    }
  }

  static void _renderBackground(
    Canvas canvas, PageBackground bg, ui.Image? pdfImage, Size? pageSize,
  ) {
    final size = pageSize ?? const Size(2000, 2000);
    final linePaint = Paint()
      ..color = Color(bg.lineColor ?? 0xFFE0E0E0)
      ..strokeWidth = 0.5;

    switch (bg.type) {
      case BackgroundType.blank || BackgroundType.cover ||
           BackgroundType.template:
        break; // Color already filled / not supported
      case BackgroundType.grid:
        final sp = bg.gridSpacing ?? 25.0;
        for (double x = sp; x < size.width; x += sp) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
        }
        for (double y = sp; y < size.height; y += sp) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
        }
      case BackgroundType.lined:
        final sp = bg.lineSpacing ?? 25.0;
        for (double y = sp * 2; y < size.height; y += sp) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
        }
      case BackgroundType.dotted:
        final sp = bg.gridSpacing ?? 20.0;
        linePaint
          ..color = Color(bg.lineColor ?? 0xFFCCCCCC)
          ..style = PaintingStyle.fill;
        for (double x = sp; x < size.width; x += sp) {
          for (double y = sp; y < size.height; y += sp) {
            canvas.drawCircle(Offset(x, y), 1.0, linePaint);
          }
        }
      case BackgroundType.pdf:
        if (pdfImage != null) {
          final src = Rect.fromLTWH(
              0, 0, pdfImage.width.toDouble(), pdfImage.height.toDouble());
          canvas.drawImageRect(
              pdfImage, src, Offset.zero & size, Paint());
        }
    }
  }
}
