import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:drawing_ui/src/canvas/shape_painter.dart';

/// Renders only the selected strokes and shapes with a live transform.
///
/// During drag/rotate, the committed painters exclude these elements,
/// and this painter draws them with the live delta/rotation applied
/// via canvas.translate/rotate.
class SelectedElementsPainter extends CustomPainter {
  /// Selected strokes to render.
  final List<Stroke> selectedStrokes;

  /// Selected shapes to render.
  final List<Shape> selectedShapes;

  /// Live drag offset.
  final Offset moveDelta;

  /// Live rotation angle in radians.
  final double rotation;

  /// Live horizontal scale factor.
  final double scaleX;

  /// Live vertical scale factor.
  final double scaleY;

  /// Center X of the selection (for rotation/scale pivot).
  final double centerX;

  /// Center Y of the selection (for rotation/scale pivot).
  final double centerY;

  final FlutterStrokeRenderer _renderer;

  SelectedElementsPainter({
    required this.selectedStrokes,
    required this.selectedShapes,
    required this.moveDelta,
    required this.rotation,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    required this.centerX,
    required this.centerY,
    FlutterStrokeRenderer? renderer,
  }) : _renderer = renderer ?? FlutterStrokeRenderer();

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedStrokes.isEmpty && selectedShapes.isEmpty) return;

    canvas.save();

    // Apply live transform: translate to center, rotate, scale, translate back + delta
    canvas.translate(centerX + moveDelta.dx, centerY + moveDelta.dy);
    if (rotation != 0) {
      canvas.rotate(rotation);
    }
    if (scaleX != 1.0 || scaleY != 1.0) {
      canvas.scale(scaleX, scaleY);
    }
    canvas.translate(-centerX, -centerY);

    // Render strokes
    _renderer.renderStrokes(canvas, selectedStrokes);

    // Render shapes using a temporary ShapePainter's draw logic
    if (selectedShapes.isNotEmpty) {
      final shapePainter = ShapePainter(shapes: selectedShapes);
      shapePainter.paint(canvas, size);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SelectedElementsPainter oldDelegate) {
    return oldDelegate.moveDelta != moveDelta ||
        oldDelegate.rotation != rotation ||
        oldDelegate.scaleX != scaleX ||
        oldDelegate.scaleY != scaleY ||
        oldDelegate.centerX != centerX ||
        oldDelegate.centerY != centerY ||
        !identical(oldDelegate.selectedStrokes, selectedStrokes) ||
        !identical(oldDelegate.selectedShapes, selectedShapes);
  }
}
