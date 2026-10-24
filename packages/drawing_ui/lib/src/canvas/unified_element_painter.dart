import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'package:drawing_ui/src/rendering/rendering.dart';

import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/shape_painter.dart';

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
  final Color selectionColor;

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
    this.selectionColor = const Color(0xFF10B981),
  }) : super(repaint: cacheManager);

  late final ElementSceneRenderer _scene = ElementSceneRenderer(
    strokes: strokes,
    shapes: shapes,
    images: images,
    texts: texts,
    elementOrder: elementOrder,
    renderer: renderer,
    cacheManager: cacheManager,
    excludedStrokeIds: excludedStrokeIds,
    excludedShapeIds: excludedShapeIds,
    excludedImageIds: excludedImageIds,
    excludedTextIds: excludedTextIds,
    pixelEraserPreview: pixelEraserPreview,
    strokeEraserPreview: strokeEraserPreview,
    selectionColor: selectionColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    _scene.paint(canvas);

    // Active shape preview always on top.
    if (activeShape != null) {
      ShapePainter.paintSingleShape(canvas, activeShape!);
    }

    // Active text always on top (editing preview).
    if (activeText != null) {
      _scene.drawText(canvas, activeText!, isActive: true);
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
        !identical(oldDelegate.strokeEraserPreview, strokeEraserPreview) ||
        oldDelegate.selectionColor != selectionColor;
  }
}
