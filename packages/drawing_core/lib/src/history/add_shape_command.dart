import 'package:drawing_core/drawing_core.dart';

/// Shape ekleme komutu
class AddShapeCommand implements DrawingCommand {
  /// Layer index
  final int layerIndex;

  /// Eklenecek shape
  final Shape shape;

  /// Constructor
  AddShapeCommand({
    required this.layerIndex,
    required this.shape,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.addShape(shape);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.removeShape(shape.id);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Add ${shape.type.name}';
}
