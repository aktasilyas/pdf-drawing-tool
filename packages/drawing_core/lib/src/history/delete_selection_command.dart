import 'package:drawing_core/drawing_core.dart';

/// Command to delete selected strokes and shapes.
///
/// Removes all strokes and shapes with the specified IDs from the layer.
/// Caches deleted items for undo support.
class DeleteSelectionCommand implements DrawingCommand {
  /// The layer index containing the items.
  final int layerIndex;

  /// IDs of strokes to delete.
  final List<String> strokeIds;

  /// IDs of shapes to delete.
  final List<String> shapeIds;

  /// Cache of deleted strokes for undo.
  final List<Stroke> _deletedStrokes = [];

  /// Cache of deleted shapes for undo.
  final List<Shape> _deletedShapes = [];

  /// Creates a delete selection command.
  DeleteSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
    this.shapeIds = const [],
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    // Cache strokes to be deleted (for undo)
    _deletedStrokes.clear();
    for (final id in strokeIds) {
      final stroke = layer.strokes.cast<Stroke?>().firstWhere(
            (s) => s?.id == id,
            orElse: () => null,
          );
      if (stroke != null) {
        _deletedStrokes.add(stroke);
      }
    }

    // Cache shapes to be deleted (for undo)
    _deletedShapes.clear();
    for (final id in shapeIds) {
      final shape = layer.getShapeById(id);
      if (shape != null) {
        _deletedShapes.add(shape);
      }
    }

    // Remove strokes
    for (final id in strokeIds) {
      layer = layer.removeStroke(id);
    }

    // Remove shapes
    for (final id in shapeIds) {
      layer = layer.removeShape(id);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    // Restore deleted strokes in reverse order
    for (final stroke in _deletedStrokes.reversed) {
      layer = layer.addStroke(stroke);
    }

    // Restore deleted shapes in reverse order
    for (final shape in _deletedShapes.reversed) {
      layer = layer.addShape(shape);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description =>
      'Delete ${strokeIds.length + shapeIds.length} element(s)';
}
