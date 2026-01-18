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
    
    // Create empty layer with same properties
    final clearedLayer = _originalLayer!.copyWith(
      strokes: [],
      shapes: [],
      texts: [],
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
