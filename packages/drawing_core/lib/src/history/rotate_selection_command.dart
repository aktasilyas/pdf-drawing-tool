import 'dart:math';

import 'package:drawing_core/drawing_core.dart';

/// Command to rotate selected strokes and shapes around a center point.
///
/// Rotates all points of the selected strokes and the start/end points
/// of selected shapes by the specified angle around (centerX, centerY).
///
/// Supports undo by rotating in the opposite direction.
class RotateSelectionCommand implements DrawingCommand {
  /// The layer index containing the items.
  final int layerIndex;

  /// IDs of strokes to rotate.
  final List<String> strokeIds;

  /// IDs of shapes to rotate.
  final List<String> shapeIds;

  /// IDs of images to rotate.
  final List<String> imageIds;

  /// IDs of texts to rotate (position only, text stays upright).
  final List<String> textIds;

  /// Center X of rotation.
  final double centerX;

  /// Center Y of rotation.
  final double centerY;

  /// Rotation angle in radians.
  final double angle;

  RotateSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
    this.shapeIds = const [],
    this.imageIds = const [],
    this.textIds = const [],
    required this.centerX,
    required this.centerY,
    required this.angle,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    return _applyRotation(document, angle);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    return _applyRotation(document, -angle);
  }

  DrawingDocument _applyRotation(DrawingDocument document, double a) {
    var layer = document.layers[layerIndex];
    final cosA = cos(a);
    final sinA = sin(a);

    for (final id in strokeIds) {
      final idx = layer.strokes.indexWhere((s) => s.id == id);
      if (idx == -1) continue;

      final stroke = layer.strokes[idx];
      final rotatedPoints = stroke.points.map((p) {
        final dx = p.x - centerX;
        final dy = p.y - centerY;
        return DrawingPoint(
          x: centerX + dx * cosA - dy * sinA,
          y: centerY + dx * sinA + dy * cosA,
          pressure: p.pressure,
          tilt: p.tilt,
          timestamp: p.timestamp,
        );
      }).toList();
      layer = layer.updateStroke(stroke.copyWith(points: rotatedPoints));
    }

    for (final id in shapeIds) {
      final shape = layer.getShapeById(id);
      if (shape == null) continue;

      final sp = shape.startPoint;
      final ep = shape.endPoint;
      final dxS = sp.x - centerX, dyS = sp.y - centerY;
      final dxE = ep.x - centerX, dyE = ep.y - centerY;

      layer = layer.updateShape(shape.copyWith(
        startPoint: DrawingPoint(
          x: centerX + dxS * cosA - dyS * sinA,
          y: centerY + dxS * sinA + dyS * cosA,
          pressure: sp.pressure,
        ),
        endPoint: DrawingPoint(
          x: centerX + dxE * cosA - dyE * sinA,
          y: centerY + dxE * sinA + dyE * cosA,
          pressure: ep.pressure,
        ),
      ));
    }

    // Rotate images
    for (final id in imageIds) {
      final image = layer.getImageById(id);
      if (image == null) continue;

      final imgCx = image.x + image.width / 2;
      final imgCy = image.y + image.height / 2;
      final dx = imgCx - centerX, dy = imgCy - centerY;
      final newCx = centerX + dx * cosA - dy * sinA;
      final newCy = centerY + dx * sinA + dy * cosA;
      layer = layer.updateImage(image.copyWith(
        x: newCx - image.width / 2,
        y: newCy - image.height / 2,
        rotation: image.rotation + a,
      ));
    }

    // Rotate texts (position only — text has no rotation property)
    for (final id in textIds) {
      final text = layer.getTextById(id);
      if (text == null) continue;

      final dx = text.x - centerX, dy = text.y - centerY;
      final newX = centerX + dx * cosA - dy * sinA;
      final newY = centerY + dx * sinA + dy * cosA;
      layer = layer.updateText(text.copyWith(x: newX, y: newY));
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description =>
      'Rotate ${strokeIds.length + shapeIds.length + imageIds.length + textIds.length} element(s)';
}
