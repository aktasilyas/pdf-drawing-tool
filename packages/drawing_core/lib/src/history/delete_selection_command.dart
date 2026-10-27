import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_core/src/history/indexed_removal.dart';

/// Command to delete selected strokes and shapes.
///
/// Removes all strokes and shapes with the specified IDs from the layer.
/// Caches deleted items with their list positions so undo restores the
/// layer exactly, including stacking order.
class DeleteSelectionCommand implements DrawingCommand {
  /// The layer index containing the items.
  final int layerIndex;

  /// IDs of strokes to delete.
  final List<String> strokeIds;

  /// IDs of shapes to delete.
  final List<String> shapeIds;

  /// IDs of images to delete.
  final List<String> imageIds;

  /// IDs of texts to delete.
  final List<String> textIds;

  /// Deleted strokes with their original indices, cached for undo.
  List<IndexedRemoval<Stroke>> _deletedStrokes = const [];

  /// Deleted shapes with their original indices, cached for undo.
  List<IndexedRemoval<Shape>> _deletedShapes = const [];

  /// Deleted images with their original indices, cached for undo.
  List<IndexedRemoval<ImageElement>> _deletedImages = const [];

  /// Deleted texts with their original indices, cached for undo.
  List<IndexedRemoval<TextElement>> _deletedTexts = const [];

  /// Cached original elementOrder for undo.
  List<String> _originalElementOrder = const [];

  /// Whether execute has cached state for undo.
  bool _executed = false;

  /// Creates a delete selection command.
  DeleteSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
    this.shapeIds = const [],
    this.imageIds = const [],
    this.textIds = const [],
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    var layer = document.layers[layerIndex];

    // Cache elementOrder and every deleted element with its list position,
    // so undo can rebuild the layer exactly.
    _originalElementOrder = List<String>.from(layer.elementOrder);
    _deletedStrokes = collectRemovals(layer.strokes, strokeIds, (s) => s.id);
    _deletedShapes = collectRemovals(layer.shapes, shapeIds, (s) => s.id);
    _deletedImages = collectRemovals(layer.images, imageIds, (i) => i.id);
    _deletedTexts = collectRemovals(layer.texts, textIds, (t) => t.id);
    _executed = true;

    // Remove strokes
    for (final id in strokeIds) {
      layer = layer.removeStroke(id);
    }

    // Remove shapes
    for (final id in shapeIds) {
      layer = layer.removeShape(id);
    }

    // Remove images
    for (final id in imageIds) {
      layer = layer.removeImage(id);
    }

    // Remove texts
    for (final id in textIds) {
      layer = layer.removeText(id);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (!_executed || layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];

    // Re-insert every element at its original index and restore the
    // original elementOrder (empty for legacy layers, which then fall back
    // to list order).
    final restored = layer.copyWith(
      strokes: reinsertRemovals(layer.strokes, _deletedStrokes),
      shapes: reinsertRemovals(layer.shapes, _deletedShapes),
      images: reinsertRemovals(layer.images, _deletedImages),
      texts: reinsertRemovals(layer.texts, _deletedTexts),
      elementOrder: _originalElementOrder,
    );

    return document.updateLayer(layerIndex, restored);
  }

  @override
  String get description =>
      'Delete ${strokeIds.length + shapeIds.length + imageIds.length + textIds.length} element(s)';
}
