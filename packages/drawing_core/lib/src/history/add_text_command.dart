import 'package:drawing_core/drawing_core.dart';

/// Text ekleme komutu
class AddTextCommand implements DrawingCommand {
  final int layerIndex;
  final TextElement textElement;

  AddTextCommand({
    required this.layerIndex,
    required this.textElement,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    final updatedLayer = layer.addText(textElement);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    final updatedLayer = layer.removeText(textElement.id);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Add text';
}
