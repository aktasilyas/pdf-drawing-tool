import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_core/src/history/ordered_restore.dart';

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

  /// IDs of images to delete.
  final List<String> imageIds;

  /// IDs of texts to delete.
  final List<String> textIds;

  /// Cache of deleted strokes for undo.
  List<MapEntry<int, Stroke>> _deletedStrokes = const [];

  /// Cache of deleted shapes for undo.
  List<MapEntry<int, Shape>> _deletedShapes = const [];

  /// Cache of deleted images for undo.
  List<MapEntry<int, ImageElement>> _deletedImages = const [];

  /// Cache of deleted texts for undo.
  List<MapEntry<int, TextElement>> _deletedTexts = const [];

  /// Cached original elementOrder for undo.
  List<String> _originalElementOrder = const [];

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

    // Cache elementOrder for undo
    _originalElementOrder = List<String>.from(layer.elementOrder);

    // Cache deleted elements with their original indices (for undo)
    _deletedStrokes = indexedRemoved(layer.strokes, strokeIds, (e) => e.id);
    _deletedShapes = indexedRemoved(layer.shapes, shapeIds, (e) => e.id);
    _deletedImages = indexedRemoved(layer.images, imageIds, (e) => e.id);
    _deletedTexts = indexedRemoved(layer.texts, textIds, (e) => e.id);

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
    if (_deletedStrokes.isEmpty &&
        _deletedShapes.isEmpty &&
        _deletedImages.isEmpty &&
        _deletedTexts.isEmpty) {
      return document;
    }

    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    var layer = document.layers[layerIndex];

    layer = layer.copyWith(
      strokes: reinsertAt(layer.strokes, _deletedStrokes),
      shapes: reinsertAt(layer.shapes, _deletedShapes),
      images: reinsertAt(layer.images, _deletedImages),
      texts: reinsertAt(layer.texts, _deletedTexts),
      elementOrder: _originalElementOrder,
    );

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description =>
      'Delete ${strokeIds.length + shapeIds.length + imageIds.length + textIds.length} element(s)';
}
