import 'package:drawing_core/drawing_core.dart';

/// Text silme komutu
class RemoveTextCommand implements DrawingCommand {
  final int layerIndex;
  final String textId;

  TextElement? _removedText;

  RemoveTextCommand({
    required this.layerIndex,
    required this.textId,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    _removedText = layer.getTextById(textId);
    final updatedLayer = layer.removeText(textId);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_removedText == null) return document;

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.addText(_removedText!);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Remove text';
}
