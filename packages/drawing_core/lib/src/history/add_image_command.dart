import 'package:drawing_core/drawing_core.dart';

/// Command for adding an image element to a layer.
class AddImageCommand implements DrawingCommand {
  final int layerIndex;
  final ImageElement imageElement;

  AddImageCommand({
    required this.layerIndex,
    required this.imageElement,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    final updatedLayer = layer.addImage(imageElement);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    final updatedLayer = layer.removeImage(imageElement.id);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Add image';
}
