import 'package:drawing_core/src/internal.dart';

/// Command to clear all content from a layer.
class ClearLayerCommand implements DrawingCommand {
  ClearLayerCommand({required this.layerIndex});

  final int layerIndex;

  // Store original content for undo
  Layer? _originalLayer;

  @override
  DrawingDocument execute(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    // Store original layer for undo
    _originalLayer = document.layers[layerIndex];

    // Empty layer with the same properties: every element type and the
    // z-order go, so images and sticky notes are cleared too (#424).
    final clearedLayer = _originalLayer!.copyWith(
      strokes: [],
      shapes: [],
      texts: [],
      images: [],
      stickyNotes: [],
      elementOrder: [],
    );

    return document.updateLayer(layerIndex, clearedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_originalLayer == null ||
        layerIndex < 0 ||
        layerIndex >= document.layers.length) {
      return document;
    }

    return document.updateLayer(layerIndex, _originalLayer!);
  }

  @override
  String get description => 'Clear layer';
}
