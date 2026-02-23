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

  /// IDs of images to delete.
  final List<String> imageIds;

  /// IDs of texts to delete.
  final List<String> textIds;

  /// Cache of deleted strokes for undo.
  final List<Stroke> _deletedStrokes = [];

  /// Cache of deleted shapes for undo.
  final List<Shape> _deletedShapes = [];

  /// Cache of deleted images for undo.
  final List<ImageElement> _deletedImages = [];

  /// Cache of deleted texts for undo.
  final List<TextElement> _deletedTexts = [];

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
    var layer = document.layers[layerIndex];

    // Cache elementOrder for undo
    _originalElementOrder = List<String>.from(layer.elementOrder);

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

    // Cache images to be deleted (for undo)
    _deletedImages.clear();
    for (final id in imageIds) {
      final image = layer.getImageById(id);
      if (image != null) {
        _deletedImages.add(image);
      }
    }

    // Cache texts to be deleted (for undo)
    _deletedTexts.clear();
    for (final id in textIds) {
      final text = layer.getTextById(id);
      if (text != null) {
        _deletedTexts.add(text);
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
    var layer = document.layers[layerIndex];

    // Restore deleted strokes in reverse order
    for (final stroke in _deletedStrokes.reversed) {
      layer = layer.addStroke(stroke);
    }

    // Restore deleted shapes in reverse order
    for (final shape in _deletedShapes.reversed) {
      layer = layer.addShape(shape);
    }

    // Restore deleted images in reverse order
    for (final image in _deletedImages.reversed) {
      layer = layer.addImage(image);
    }

    // Restore deleted texts in reverse order
    for (final text in _deletedTexts.reversed) {
      layer = layer.addText(text);
    }

    // Restore original elementOrder (addImage/addText would append new IDs)
    if (_originalElementOrder.isNotEmpty) {
      layer = layer.copyWith(elementOrder: _originalElementOrder);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description =>
      'Delete ${strokeIds.length + shapeIds.length + imageIds.length + textIds.length} element(s)';
}
