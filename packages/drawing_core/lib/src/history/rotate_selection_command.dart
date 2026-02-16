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

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description =>
      'Rotate ${strokeIds.length + shapeIds.length} element(s)';
}
