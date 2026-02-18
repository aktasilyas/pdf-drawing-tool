import 'package:drawing_core/drawing_core.dart';

/// Command for removing an image element from a layer.
class RemoveImageCommand implements DrawingCommand {
  final int layerIndex;
  final String imageId;

  ImageElement? _removedImage;

  RemoveImageCommand({
    required this.layerIndex,
    required this.imageId,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    _removedImage = layer.getImageById(imageId);
    final updatedLayer = layer.removeImage(imageId);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_removedImage == null) return document;

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.addImage(_removedImage!);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Remove image';
}
