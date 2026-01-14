import 'package:drawing_core/drawing_core.dart';

/// Text güncelleme komutu
class UpdateTextCommand implements DrawingCommand {
  final int layerIndex;
  final TextElement newText;

  TextElement? _oldText;

  UpdateTextCommand({
    required this.layerIndex,
    required this.newText,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    _oldText = layer.getTextById(newText.id);
    final updatedLayer = layer.updateText(newText);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_oldText == null) return document;

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.updateText(_oldText!);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Update text';
}
