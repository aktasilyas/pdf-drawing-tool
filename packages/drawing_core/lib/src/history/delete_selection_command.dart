import 'package:drawing_core/drawing_core.dart';

/// Command to delete selected strokes.
///
/// Removes all strokes with the specified IDs from the layer.
/// Caches deleted strokes for undo support.
class DeleteSelectionCommand implements DrawingCommand {
  /// The layer index containing the strokes.
  final int layerIndex;

  /// IDs of strokes to delete.
  final List<String> strokeIds;

  /// Cache of deleted strokes for undo.
  final List<Stroke> _deletedStrokes = [];

  /// Creates a delete selection command.
  DeleteSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
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

    // Remove strokes
    for (final id in strokeIds) {
      layer = layer.removeStroke(id);
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

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description => 'Delete ${strokeIds.length} element(s)';
}
