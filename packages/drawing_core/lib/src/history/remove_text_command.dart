import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_core/src/history/ordered_restore.dart';

/// Text silme komutu
class RemoveTextCommand implements DrawingCommand {
  final int layerIndex;
  final String textId;

  TextElement? _removedText;
  int _removedIndex = 0;
  List<String> _originalElementOrder = const [];

  RemoveTextCommand({
    required this.layerIndex,
    required this.textId,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];
    _originalElementOrder = List<String>.from(layer.elementOrder);
    _removedText = layer.getTextById(textId);
    _removedIndex = layer.texts.indexWhere((e) => e.id == textId);
    final updatedLayer = layer.removeText(textId);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_removedText == null) return document;

    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.copyWith(
      texts: reinsertAt(layer.texts, [MapEntry(_removedIndex, _removedText!)]),
      elementOrder: _originalElementOrder,
    );
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Remove text';
}
