import 'package:drawing_core/src/internal.dart';

/// Command to clear all content from every layer of the current page.
///
/// Run it with `HistoryManager.execute(..., pageId:)` to target another page.
/// Layers keep their properties; one undo restores all of them.
class ClearPageCommand implements DrawingCommand {
  ClearPageCommand();

  List<Layer>? _originalLayers;

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layers = document.layers;
    _originalLayers = List<Layer>.of(layers);

    var result = document;
    for (var i = 0; i < layers.length; i++) {
      result = result.updateLayer(
        i,
        layers[i].copyWith(
          strokes: [],
          shapes: [],
          texts: [],
          images: [],
          stickyNotes: [],
          elementOrder: [],
        ),
      );
    }
    return result;
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    final originals = _originalLayers;
    if (originals == null) return document;

    var result = document;
    for (var i = 0; i < originals.length && i < result.layers.length; i++) {
      result = result.updateLayer(i, originals[i]);
    }
    return result;
  }

  @override
  String get description => 'Clear page';
}
