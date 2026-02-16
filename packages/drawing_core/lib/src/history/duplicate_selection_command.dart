import 'package:drawing_core/drawing_core.dart';

/// Command to duplicate selected strokes and shapes with an offset.
///
/// Clones strokes/shapes with new IDs and applies an offset.
/// Caches new IDs for undo removal.
class DuplicateSelectionCommand implements DrawingCommand {
  /// The layer index containing the items.
  final int layerIndex;

  /// IDs of strokes to duplicate.
  final List<String> strokeIds;

  /// IDs of shapes to duplicate.
  final List<String> shapeIds;

  /// Horizontal offset for duplicated items.
  final double offsetX;

  /// Vertical offset for duplicated items.
  final double offsetY;

  /// New stroke IDs created by execute (for post-execute selection update).
  final List<String> newStrokeIds = [];

  /// New shape IDs created by execute (for post-execute selection update).
  final List<String> newShapeIds = [];

  DuplicateSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
    this.shapeIds = const [],
    this.offsetX = 40.0,
    this.offsetY = 40.0,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    var layer = document.layers[layerIndex];
    newStrokeIds.clear();
    newShapeIds.clear();

    for (final id in strokeIds) {
      final idx = layer.strokes.indexWhere((s) => s.id == id);
      if (idx == -1) continue;

      final stroke = layer.strokes[idx];
      final movedPoints = stroke.points
          .map((p) => DrawingPoint(
                x: p.x + offsetX,
                y: p.y + offsetY,
                pressure: p.pressure,
                tilt: p.tilt,
                timestamp: p.timestamp,
              ))
          .toList();

      final newStroke = Stroke.create(
        style: stroke.style,
        points: movedPoints,
      );
      newStrokeIds.add(newStroke.id);
      layer = layer.addStroke(newStroke);
    }

    for (final id in shapeIds) {
      final shape = layer.getShapeById(id);
      if (shape == null) continue;

      final newId = DateTime.now().microsecondsSinceEpoch.toString();
      final newShape = Shape(
        id: newId,
        type: shape.type,
        startPoint: DrawingPoint(
          x: shape.startPoint.x + offsetX,
          y: shape.startPoint.y + offsetY,
          pressure: shape.startPoint.pressure,
        ),
        endPoint: DrawingPoint(
          x: shape.endPoint.x + offsetX,
          y: shape.endPoint.y + offsetY,
          pressure: shape.endPoint.pressure,
        ),
        style: shape.style,
        isFilled: shape.isFilled,
        fillColor: shape.fillColor,
      );
      newShapeIds.add(newId);
      layer = layer.addShape(newShape);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    for (final id in newStrokeIds) {
      layer = layer.removeStroke(id);
    }
    for (final id in newShapeIds) {
      layer = layer.removeShape(id);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description =>
      'Duplicate ${strokeIds.length + shapeIds.length} element(s)';
}
