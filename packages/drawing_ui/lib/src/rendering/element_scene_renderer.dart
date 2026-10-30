import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/painting.dart';

import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/shape_painter.dart';
import 'package:drawing_ui/src/rendering/element_paint_order.dart';
import 'package:drawing_ui/src/rendering/element_text_layout.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';
import 'package:drawing_ui/src/rendering/tiles/element_bounds.dart';

/// Paints the committed elements of a scene (strokes, shapes, images, texts)
/// interleaved by [elementOrder] for correct z-ordering.
///
/// Used by `UnifiedElementPainter` and, via [paintRegion], by the tile cache.
class ElementSceneRenderer {
  final List<Stroke> strokes;
  final List<Shape> shapes;
  final List<ImageElement> images;
  final List<TextElement> texts;
  final List<String> elementOrder;
  final FlutterStrokeRenderer renderer;
  final ImageCacheManager cacheManager;
  final Set<String> excludedStrokeIds;
  final Set<String> excludedShapeIds;
  final Set<String> excludedImageIds;
  final Set<String> excludedTextIds;
  final Map<String, List<int>> pixelEraserPreview;
  final Set<String> strokeEraserPreview;
  final Color selectionColor;

  const ElementSceneRenderer({
    required this.strokes,
    required this.shapes,
    required this.images,
    required this.texts,
    required this.elementOrder,
    required this.renderer,
    required this.cacheManager,
    this.excludedStrokeIds = const {},
    this.excludedShapeIds = const {},
    this.excludedImageIds = const {},
    this.excludedTextIds = const {},
    this.pixelEraserPreview = const {},
    this.strokeEraserPreview = const {},
    this.selectionColor = const Color(0xFF10B981),
  });

  /// Paints every visible element in z-order.
  void paint(Canvas canvas) {
    for (final e in _orderedEntries()) {
      _paintEntry(canvas, e);
    }
  }

  /// Paints only the elements whose inflated bounds intersect [cull], in
  /// z-order. The caller is responsible for clipping to [cull].
  void paintRegion(Canvas canvas, Rect cull) {
    for (final e in _orderedEntries()) {
      if (_boundsOf(e).overlaps(cull)) _paintEntry(canvas, e);
    }
  }

  /// Draws [text]. When [isActive] the editing outline is drawn too.
  void drawText(Canvas canvas, TextElement text, {bool isActive = false}) {
    if (text.text.isEmpty && !isActive) return;

    final paragraph = layoutTextParagraph(text);

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
        ..color = selectionColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(
        Rect.fromLTWH(text.x - 2, text.y - 2, paragraph.maxIntrinsicWidth + 4,
            paragraph.height + 4),
        paint,
      );
    }
    canvas.restore();
  }

  // ── Ordering ──

  /// Visible elements (Stroke/Shape/ImageElement/TextElement) in z-order.
  List<Object> _orderedEntries() => elementPaintOrder<Object>(
        elementOrder: elementOrder,
        strokes: {
          for (final s in strokes)
            if (!excludedStrokeIds.contains(s.id) &&
                !strokeEraserPreview.contains(s.id))
              s.id: s,
        },
        shapes: {
          for (final s in shapes)
            if (!excludedShapeIds.contains(s.id)) s.id: s,
        },
        images: {
          for (final img in images)
            if (!excludedImageIds.contains(img.id)) img.id: img,
        },
        texts: {
          for (final txt in texts)
            if (!excludedTextIds.contains(txt.id)) txt.id: txt,
        },
        entry: (_, element) => element,
      );

  Rect _boundsOf(Object e) => switch (e) {
        final Stroke s => strokeBounds(s),
        final Shape s => shapeBounds(s),
        final ImageElement i => imageBounds(i),
        final TextElement t => textBounds(t),
        _ => Rect.zero,
      };

  void _paintEntry(Canvas canvas, Object e) {
    switch (e) {
      case final Stroke s:
        _renderStroke(canvas, s);
      case final Shape s:
        ShapePainter.paintSingleShape(canvas, s);
      case final ImageElement i:
        _drawImage(canvas, i);
      case final TextElement t:
        drawText(canvas, t);
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
}
