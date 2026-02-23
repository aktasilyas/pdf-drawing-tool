import 'package:drawing_core/drawing_core.dart';

/// Shape silme komutu
class RemoveShapeCommand implements DrawingCommand {
  /// Layer index
  final int layerIndex;

  /// Silinecek shape ID
  final String shapeId;

  /// Undo için silinen shape'i cache'le
  Shape? _removedShape;

  /// Cached elementOrder before execute (for undo z-order restore).
  List<String> _originalElementOrder = const [];

  /// Constructor
  RemoveShapeCommand({
    required this.layerIndex,
    required this.shapeId,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];

    // Cache elementOrder before removal (for undo z-order restore)
    _originalElementOrder = List<String>.from(layer.elementOrder);

    // Silinecek shape'i cache'le
    _removedShape = layer.getShapeById(shapeId);

    final updatedLayer = layer.removeShape(shapeId);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_removedShape == null) return document;

    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    var layer = document.layers[layerIndex];
    layer = layer.addShape(_removedShape!);

    // Restore original elementOrder (addShape appends to end, wrong z-order)
    if (_originalElementOrder.isNotEmpty) {
      layer = layer.copyWith(elementOrder: _originalElementOrder);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description => 'Remove shape';
}
