import 'dart:math';

import 'package:drawing_core/drawing_core.dart';

/// Command to scale selected strokes and shapes around a center point.
///
/// Scales all points and stroke thicknesses. Caches original thicknesses
/// for accurate undo.
class ScaleSelectionCommand implements DrawingCommand {
  /// The layer index containing the items.
  final int layerIndex;

  /// IDs of strokes to scale.
  final List<String> strokeIds;

  /// IDs of shapes to scale.
  final List<String> shapeIds;

  /// Center X of scale transformation.
  final double centerX;

  /// Center Y of scale transformation.
  final double centerY;

  /// Horizontal scale factor.
  final double scaleX;

  /// Vertical scale factor.
  final double scaleY;

  /// Cached original thicknesses for undo (strokeId → thickness).
  final Map<String, double> _originalThicknesses = {};

  ScaleSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
    this.shapeIds = const [],
    required this.centerX,
    required this.centerY,
    required this.scaleX,
    required this.scaleY,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    return _applyScale(document, scaleX, scaleY, cacheThickness: true);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    return _applyScale(
      document,
      1.0 / scaleX,
      1.0 / scaleY,
      restoreThickness: true,
    );
  }

  DrawingDocument _applyScale(
    DrawingDocument document,
    double sx,
    double sy, {
    bool cacheThickness = false,
    bool restoreThickness = false,
  }) {
    var layer = document.layers[layerIndex];
    final thicknessScale = max(sx.abs(), sy.abs());

    for (final id in strokeIds) {
      final idx = layer.strokes.indexWhere((s) => s.id == id);
      if (idx == -1) continue;

      final stroke = layer.strokes[idx];

      if (cacheThickness) {
        _originalThicknesses[id] = stroke.style.thickness;
      }

      final scaledPoints = stroke.points.map((p) {
        return DrawingPoint(
          x: centerX + (p.x - centerX) * sx,
          y: centerY + (p.y - centerY) * sy,
          pressure: p.pressure,
          tilt: p.tilt,
          timestamp: p.timestamp,
        );
      }).toList();

      final newThickness = restoreThickness && _originalThicknesses.containsKey(id)
          ? _originalThicknesses[id]!
          : (stroke.style.thickness * thicknessScale).clamp(0.1, 50.0);

      layer = layer.updateStroke(stroke.copyWith(
        points: scaledPoints,
        style: stroke.style.copyWith(thickness: newThickness),
      ));
    }

    for (final id in shapeIds) {
      final shape = layer.getShapeById(id);
      if (shape == null) continue;

      final sp = shape.startPoint;
      final ep = shape.endPoint;

      layer = layer.updateShape(shape.copyWith(
        startPoint: DrawingPoint(
          x: centerX + (sp.x - centerX) * sx,
          y: centerY + (sp.y - centerY) * sy,
          pressure: sp.pressure,
        ),
        endPoint: DrawingPoint(
          x: centerX + (ep.x - centerX) * sx,
          y: centerY + (ep.y - centerY) * sy,
          pressure: ep.pressure,
        ),
      ));
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description =>
      'Scale ${strokeIds.length + shapeIds.length} element(s)';
}
