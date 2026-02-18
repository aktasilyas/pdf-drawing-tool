import 'package:drawing_core/drawing_core.dart';

/// Command for updating an image element in a layer.
class UpdateImageCommand implements DrawingCommand {
  final int layerIndex;
  final ImageElement newImage;

  ImageElement? _oldImage;

  UpdateImageCommand({
    required this.layerIndex,
    required this.newImage,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    _oldImage = layer.getImageById(newImage.id);
    final updatedLayer = layer.updateImage(newImage);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_oldImage == null) return document;

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.updateImage(_oldImage!);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Update image';
}
