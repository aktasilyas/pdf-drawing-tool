import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;

/// Renders drawing layer content to a Flutter [Canvas] for raster fallback.
///
/// Used by [PDFExporter] when a layer cannot be vectorized (contains
/// textured strokes, glow effects, erasers, or text elements).
/// The result is captured as a PNG image and embedded in the PDF.
class PdfRasterLayerRenderer {
  void renderShapes(Canvas canvas, List<Shape> shapes) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final shape in shapes) {
      if (shape.isFilled) {
        paint.color = Color(shape.fillColor ?? shape.style.color);
        paint.style = PaintingStyle.fill;
        _drawShapeByType(canvas, shape, paint);

        paint.color = Color(shape.style.color).withValues(
          alpha: shape.style.opacity,
        );
        paint.strokeWidth = shape.style.thickness;
        paint.style = PaintingStyle.stroke;
        _drawShapeByType(canvas, shape, paint);
      } else {
        paint.color = Color(shape.style.color).withValues(
          alpha: shape.style.opacity,
        );
        paint.strokeWidth = shape.style.thickness;
        paint.style = PaintingStyle.stroke;
        _drawShapeByType(canvas, shape, paint);
      }
    }
  }

  void _drawShapeByType(Canvas canvas, Shape shape, Paint paint) {
    final s = Offset(shape.startPoint.x, shape.startPoint.y);
    final e = Offset(shape.endPoint.x, shape.endPoint.y);
    final rect = Rect.fromPoints(s, e);

    switch (shape.type) {
      case ShapeType.line:
        canvas.drawLine(s, e, paint);
      case ShapeType.arrow:
        canvas.drawLine(s, e, paint);
        _drawArrowHead(canvas, s, e, paint);
      case ShapeType.rectangle:
        canvas.drawRect(rect, paint);
      case ShapeType.ellipse:
        canvas.drawOval(rect, paint);
      case ShapeType.triangle:
        final l = min(s.dx, e.dx);
        final r = max(s.dx, e.dx);
        final t = min(s.dy, e.dy);
        final b = max(s.dy, e.dy);
        canvas.drawPath(
          Path()
            ..moveTo((l + r) / 2, t)
            ..lineTo(l, b)
            ..lineTo(r, b)
            ..close(),
          paint,
        );
      case ShapeType.diamond:
        final cx = (s.dx + e.dx) / 2;
        final cy = (s.dy + e.dy) / 2;
        final hw = (e.dx - s.dx).abs() / 2;
        final hh = (e.dy - s.dy).abs() / 2;
        canvas.drawPath(
          Path()
            ..moveTo(cx, cy - hh)
            ..lineTo(cx + hw, cy)
            ..lineTo(cx, cy + hh)
            ..lineTo(cx - hw, cy)
            ..close(),
          paint,
        );
      case ShapeType.star:
      case ShapeType.pentagon:
      case ShapeType.hexagon:
      case ShapeType.plus:
        canvas.drawRect(rect, paint);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 10) return;

    final ux = dx / len;
    final uy = dy / len;
    final sz = paint.strokeWidth * 4;
    final bx = end.dx - ux * sz;
    final by = end.dy - uy * sz;
    final px = -uy * sz * 0.5;
    final py = ux * sz * 0.5;

    canvas.drawPath(
      Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(bx + px, by + py)
        ..lineTo(bx - px, by - py)
        ..close(),
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  void renderTexts(Canvas canvas, List<TextElement> texts) {
    for (final t in texts) {
      if (t.text.isEmpty) continue;
      final style = ui.TextStyle(
        color: Color(t.color),
        fontSize: t.fontSize,
        fontFamily: t.fontFamily,
        fontWeight: t.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: t.isItalic ? FontStyle.italic : FontStyle.normal,
        decoration:
            t.isUnderline ? TextDecoration.underline : TextDecoration.none,
      );
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: t.alignment == TextAlignment.center
            ? TextAlign.center
            : t.alignment == TextAlignment.right
                ? TextAlign.right
                : TextAlign.left,
      ))
        ..pushStyle(style)
        ..addText(t.text);
      final paragraph = builder.build();
      paragraph.layout(ui.ParagraphConstraints(width: t.width ?? 1000.0));
      canvas.save();
      if (t.rotation != 0.0) {
        final cx = t.x + paragraph.maxIntrinsicWidth / 2;
        final cy = t.y + paragraph.height / 2;
        canvas.translate(cx, cy);
        canvas.rotate(t.rotation);
        canvas.translate(-cx, -cy);
      }
      canvas.drawParagraph(paragraph, Offset(t.x, t.y));
      canvas.restore();
    }
  }

  Future<void> renderImages(
    Canvas canvas,
    List<ImageElement> images,
  ) async {
    for (final img in images) {
      try {
        final file = File(img.filePath);
        if (!await file.exists()) continue;

        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        canvas.save();
        if (img.rotation != 0.0) {
          final cx = img.x + img.width / 2;
          final cy = img.y + img.height / 2;
          canvas.translate(cx, cy);
          canvas.rotate(img.rotation);
          canvas.translate(-cx, -cy);
        }

        final src = Rect.fromLTWH(
          0,
          0,
          uiImage.width.toDouble(),
          uiImage.height.toDouble(),
        );
        final dst = Rect.fromLTWH(img.x, img.y, img.width, img.height);
        canvas.drawImageRect(
          uiImage,
          src,
          dst,
          Paint()..filterQuality = FilterQuality.high,
        );
        canvas.restore();
      } catch (_) {
        // Skip images that fail to load
      }
    }
  }
}
