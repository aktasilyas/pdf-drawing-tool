import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/shape_painter.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';

/// Draws the uncached editing previews above the tiled committed content:
/// the shape being dragged and the text being edited.
class ElementPreviewPainter extends CustomPainter {
  ElementPreviewPainter({
    required this.renderer,
    required this.cacheManager,
    this.activeShape,
    this.activeText,
    this.selectionColor = const Color(0xFF10B981),
  }) : super(repaint: cacheManager);

  final FlutterStrokeRenderer renderer;
  final ImageCacheManager cacheManager;
  final Shape? activeShape;
  final TextElement? activeText;
  final Color selectionColor;

  late final ElementSceneRenderer _scene = ElementSceneRenderer(
    strokes: const [],
    shapes: const [],
    images: const [],
    texts: const [],
    elementOrder: const [],
    renderer: renderer,
    cacheManager: cacheManager,
    selectionColor: selectionColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final shape = activeShape;
    if (shape != null) ShapePainter.paintSingleShape(canvas, shape);
    final text = activeText;
    if (text != null) _scene.drawText(canvas, text, isActive: true);
  }

  @override
  bool shouldRepaint(covariant ElementPreviewPainter oldDelegate) =>
      oldDelegate.activeShape != activeShape ||
      oldDelegate.activeText != activeText ||
      oldDelegate.selectionColor != selectionColor;
}
