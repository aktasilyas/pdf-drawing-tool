import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_core/src/history/ordered_restore.dart';

/// Command for removing an image element from a layer.
class RemoveImageCommand implements DrawingCommand {
  final int layerIndex;
  final String imageId;

  ImageElement? _removedImage;
  int _removedIndex = 0;
  List<String> _originalElementOrder = const [];

  RemoveImageCommand({
    required this.layerIndex,
    required this.imageId,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];
    _originalElementOrder = List<String>.from(layer.elementOrder);
    _removedImage = layer.getImageById(imageId);
    _removedIndex = layer.images.indexWhere((e) => e.id == imageId);
    final updatedLayer = layer.removeImage(imageId);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_removedImage == null) return document;

    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.copyWith(
      images:
          reinsertAt(layer.images, [MapEntry(_removedIndex, _removedImage!)]),
      elementOrder: _originalElementOrder,
    );
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Remove image';
}
