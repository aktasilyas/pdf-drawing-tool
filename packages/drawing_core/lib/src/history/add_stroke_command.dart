import 'package:drawing_core/src/internal.dart';

/// Command to add a stroke to a layer.
///
/// This command adds a [Stroke] to the specified layer index.
/// Undo removes the stroke by its ID.
class AddStrokeCommand implements DrawingCommand {
  /// The index of the layer to add the stroke to.
  final int layerIndex;

  /// The stroke to add.
  final Stroke stroke;

  /// Creates a new [AddStrokeCommand].
  AddStrokeCommand({
    required this.layerIndex,
    required this.stroke,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layerCount) {
      return document;
    }

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.addStroke(stroke);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layerCount) {
      return document;
    }

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.removeStroke(stroke.id);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Add stroke to layer $layerIndex';
}
