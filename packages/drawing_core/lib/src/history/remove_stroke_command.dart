import 'package:drawing_core/src/internal.dart';

/// Command to remove a stroke from a layer.
///
/// This command removes a stroke by its ID from the specified layer.
/// The removed stroke is cached internally for undo operations.
class RemoveStrokeCommand implements DrawingCommand {
  /// The index of the layer to remove the stroke from.
  final int layerIndex;

  /// The ID of the stroke to remove.
  final String strokeId;

  /// Cached stroke for undo operation.
  /// This is set during execute and used during undo.
  Stroke? _removedStroke;

  /// Creates a new [RemoveStrokeCommand].
  RemoveStrokeCommand({
    required this.layerIndex,
    required this.strokeId,
  });

  /// The stroke that was removed (available after execute).
  ///
  /// Returns null if execute hasn't been called or the stroke wasn't found.
  Stroke? get removedStroke => _removedStroke;

  @override
  DrawingDocument execute(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layerCount) {
      return document;
    }

    final layer = document.layers[layerIndex];

    // Find and cache the stroke for undo
    _removedStroke = layer.getStrokeById(strokeId);

    if (_removedStroke == null) {
      // Stroke not found, return unchanged
      return document;
    }

    final updatedLayer = layer.removeStroke(strokeId);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_removedStroke == null) {
      // No stroke was removed, return unchanged
      return document;
    }

    if (layerIndex < 0 || layerIndex >= document.layerCount) {
      return document;
    }

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.addStroke(_removedStroke!);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Remove stroke $strokeId from layer $layerIndex';
}
