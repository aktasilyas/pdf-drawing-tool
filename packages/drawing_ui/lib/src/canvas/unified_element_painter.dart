import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'package:drawing_ui/src/rendering/rendering.dart';

import 'image_painter.dart';
import 'shape_painter.dart';

/// Renders all element types (strokes, shapes, images, texts) interleaved
/// by [elementOrder] for correct z-ordering.
///
/// This replaces the previous approach of separate CommittedStrokesPainter,
/// ShapePainter, and InterleavedObjectPainter which always rendered strokes
/// below shapes below images/texts regardless of creation order.
class UnifiedElementPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Shape> shapes;
  final List<ImageElement> images;
  final List<TextElement> texts;
  final List<String> elementOrder;
  final FlutterStrokeRenderer renderer;
  final ImageCacheManager cacheManager;
  final Shape? activeShape;
  final TextElement? activeText;
  final Set<String> excludedStrokeIds;
  final Set<String> excludedShapeIds;
  final Set<String> excludedImageIds;
  final Set<String> excludedTextIds;
  final Map<String, List<int>> pixelEraserPreview;
  final Set<String> strokeEraserPreview;

  UnifiedElementPainter({
    required this.strokes,
    required this.shapes,
    required this.images,
    required this.texts,
    required this.elementOrder,
    required this.renderer,
    required this.cacheManager,
    this.activeShape,
    this.activeText,
    this.excludedStrokeIds = const {},
    this.excludedShapeIds = const {},
    this.excludedImageIds = const {},
    this.excludedTextIds = const {},
    this.pixelEraserPreview = const {},
    this.strokeEraserPreview = const {},
  }) : super(repaint: cacheManager);

  @override
  void paint(Canvas canvas, Size size) {
    // Build ID→element maps for O(1) lookup.
    final strokeMap = <String, Stroke>{};
    for (final s in strokes) {
      if (!excludedStrokeIds.contains(s.id) &&
          !strokeEraserPreview.contains(s.id)) {
        strokeMap[s.id] = s;
      }
    }
    final shapeMap = <String, Shape>{};
    for (final s in shapes) {
      if (!excludedShapeIds.contains(s.id)) shapeMap[s.id] = s;
    }
    final imageMap = <String, ImageElement>{};
    for (final img in images) {
      if (!excludedImageIds.contains(img.id)) imageMap[img.id] = img;
    }
    final textMap = <String, TextElement>{};
    for (final txt in texts) {
      if (!excludedTextIds.contains(txt.id)) textMap[txt.id] = txt;
    }

    if (elementOrder.isNotEmpty) {
      final painted = <String>{};

      // Paint in explicit order.
      for (final id in elementOrder) {
        painted.add(id);
        if (_tryPaintElement(canvas, id, strokeMap, shapeMap, imageMap, textMap)) {
          continue;
        }
      }

      // Render remaining elements not in elementOrder (backward compat).
      _paintRemaining(canvas, painted, strokeMap, shapeMap, imageMap, textMap);
    } else {
      // No elementOrder: render strokes first, then shapes, then images/texts by ID.
      // This preserves old behavior for documents without elementOrder.
      for (final s in strokes) {
        if (strokeMap.containsKey(s.id)) {
          _renderStroke(canvas, s);
        }
      }
      for (final s in shapes) {
        if (shapeMap.containsKey(s.id)) {
          ShapePainter.paintSingleShape(canvas, s);
        }
      }
      // Images + texts sorted by ID (microsecond timestamp).
      final objectEntries = <_PaintEntry>[];
      for (final e in imageMap.entries) {
        objectEntries.add(_PaintEntry(id: e.key, image: e.value));
      }
      for (final e in textMap.entries) {
        objectEntries.add(_PaintEntry(id: e.key, text: e.value));
      }
      objectEntries.sort((a, b) => a.id.compareTo(b.id));
      for (final e in objectEntries) {
        if (e.image != null) {
          _drawImage(canvas, e.image!);
        } else {
          _drawText(canvas, e.text!);
        }
      }
    }

    // Active shape preview always on top.
    if (activeShape != null) {
      ShapePainter.paintSingleShape(canvas, activeShape!);
    }

    // Active text always on top (editing preview).
    if (activeText != null) {
      _drawText(canvas, activeText!, isActive: true);
    }
  }

  bool _tryPaintElement(
    Canvas canvas,
    String id,
    Map<String, Stroke> strokeMap,
    Map<String, Shape> shapeMap,
    Map<String, ImageElement> imageMap,
    Map<String, TextElement> textMap,
  ) {
    final stroke = strokeMap[id];
    if (stroke != null) {
      _renderStroke(canvas, stroke);
      return true;
    }
    final shape = shapeMap[id];
    if (shape != null) {
      ShapePainter.paintSingleShape(canvas, shape);
      return true;
    }
    final img = imageMap[id];
    if (img != null) {
      _drawImage(canvas, img);
      return true;
    }
    final txt = textMap[id];
    if (txt != null) {
      _drawText(canvas, txt);
      return true;
    }
    return false;
  }

  void _paintRemaining(
    Canvas canvas,
    Set<String> painted,
    Map<String, Stroke> strokeMap,
    Map<String, Shape> shapeMap,
    Map<String, ImageElement> imageMap,
    Map<String, TextElement> textMap,
  ) {
    final remaining = <_PaintEntry>[];
    for (final e in strokeMap.entries) {
      if (!painted.contains(e.key)) {
        remaining.add(_PaintEntry(id: e.key, stroke: e.value));
      }
    }
    for (final e in shapeMap.entries) {
      if (!painted.contains(e.key)) {
        remaining.add(_PaintEntry(id: e.key, shape: e.value));
      }
    }
    for (final e in imageMap.entries) {
      if (!painted.contains(e.key)) {
        remaining.add(_PaintEntry(id: e.key, image: e.value));
      }
    }
    for (final e in textMap.entries) {
      if (!painted.contains(e.key)) {
        remaining.add(_PaintEntry(id: e.key, text: e.value));
      }
    }
    remaining.sort((a, b) => a.id.compareTo(b.id));
    for (final e in remaining) {
      if (e.stroke != null) {
        _renderStroke(canvas, e.stroke!);
      } else if (e.shape != null) {
        ShapePainter.paintSingleShape(canvas, e.shape!);
      } else if (e.image != null) {
        _drawImage(canvas, e.image!);
      } else {
        _drawText(canvas, e.text!);
      }
    }
  }

  void _renderStroke(Canvas canvas, Stroke stroke) {
    final excluded = pixelEraserPreview[stroke.id];
    if (excluded != null && excluded.isNotEmpty) {
      renderer.renderStrokeExcluding(canvas, stroke, excluded.toSet());
    } else {
      renderer.renderStroke(canvas, stroke);
    }
  }

  // ── Image rendering ──

  void _drawImage(Canvas canvas, ImageElement element) {
    final cachedImage = cacheManager.get(element.filePath);
    if (cachedImage == null) {
      _drawPlaceholder(canvas, element);
      cacheManager.loadImage(element.filePath);
      return;
    }

    canvas.save();
    if (element.rotation != 0.0) {
      final cx = element.x + element.width / 2;
      final cy = element.y + element.height / 2;
      canvas.translate(cx, cy);
      canvas.rotate(element.rotation);
      canvas.translate(-cx, -cy);
    }

    final src = Rect.fromLTWH(
        0, 0, cachedImage.width.toDouble(), cachedImage.height.toDouble());
    final dst =
        Rect.fromLTWH(element.x, element.y, element.width, element.height);
    canvas.drawImageRect(cachedImage, src, dst, Paint());
    canvas.restore();
  }

  void _drawPlaceholder(Canvas canvas, ImageElement element) {
    final rect =
        Rect.fromLTWH(element.x, element.y, element.width, element.height);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFE0E0E0));
    canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFFBDBDBD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    final iconSize =
        (element.width < element.height ? element.width : element.height) * 0.3;
    canvas.drawRect(
        Rect.fromCenter(center: rect.center, width: iconSize, height: iconSize),
        Paint()
          ..color = const Color(0xFF9E9E9E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
  }

  // ── Text rendering ──

  void _drawText(Canvas canvas, TextElement text, {bool isActive = false}) {
    if (text.text.isEmpty && !isActive) return;

    final textStyle = ui.TextStyle(
      color: Color(text.color),
      fontSize: text.fontSize,
      fontFamily: text.fontFamily,
      fontWeight: text.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: text.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration:
          text.isUnderline ? TextDecoration.underline : TextDecoration.none,
    );

    final paragraph = (ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: _convertAlignment(text.alignment),
        maxLines: null,
      ),
    )
          ..pushStyle(textStyle)
          ..addText(text.text.isEmpty ? ' ' : text.text))
        .build();

    paragraph.layout(ui.ParagraphConstraints(width: text.width ?? 1000.0));

    canvas.save();
    if (text.rotation != 0.0) {
      final cx = text.x + paragraph.maxIntrinsicWidth / 2;
      final cy = text.y + paragraph.height / 2;
      canvas.translate(cx, cy);
      canvas.rotate(text.rotation);
      canvas.translate(-cx, -cy);
    }

    canvas.drawParagraph(paragraph, Offset(text.x, text.y));

    if (isActive) {
      final paint = Paint()
        ..color = const Color(0xFF2196F3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(
        Rect.fromLTWH(text.x - 2, text.y - 2,
            paragraph.maxIntrinsicWidth + 4, paragraph.height + 4),
        paint,
      );
    }
    canvas.restore();
  }

  static TextAlign _convertAlignment(TextAlignment alignment) {
    switch (alignment) {
      case TextAlignment.left:
        return TextAlign.left;
      case TextAlignment.center:
        return TextAlign.center;
      case TextAlignment.right:
        return TextAlign.right;
    }
  }

  @override
  bool shouldRepaint(covariant UnifiedElementPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.shapes != shapes ||
        oldDelegate.images != images ||
        oldDelegate.texts != texts ||
        oldDelegate.elementOrder != elementOrder ||
        oldDelegate.activeShape != activeShape ||
        oldDelegate.activeText != activeText ||
        !identical(oldDelegate.excludedStrokeIds, excludedStrokeIds) ||
        !identical(oldDelegate.excludedShapeIds, excludedShapeIds) ||
        !identical(oldDelegate.excludedImageIds, excludedImageIds) ||
        !identical(oldDelegate.excludedTextIds, excludedTextIds) ||
        !identical(oldDelegate.pixelEraserPreview, pixelEraserPreview) ||
        !identical(oldDelegate.strokeEraserPreview, strokeEraserPreview);
  }
}

/// Lightweight wrapper to tag an element for sorting.
class _PaintEntry {
  final String id;
  final Stroke? stroke;
  final Shape? shape;
  final ImageElement? image;
  final TextElement? text;

  const _PaintEntry({
    required this.id,
    this.stroke,
    this.shape,
    this.image,
    this.text,
  });
}
