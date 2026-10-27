import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_core/src/history/ordered_restore.dart';

/// Shape silme komutu
class RemoveShapeCommand implements DrawingCommand {
  /// Layer index
  final int layerIndex;

  /// Silinecek shape ID
  final String shapeId;

  /// Undo için silinen shape'i cache'le
  Shape? _removedShape;

  /// Original index of the removed shape in `Layer.shapes`.
  int _removedIndex = 0;

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
    _removedIndex = layer.shapes.indexWhere((s) => s.id == shapeId);

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
    layer = layer.copyWith(
      shapes:
          reinsertAt(layer.shapes, [MapEntry(_removedIndex, _removedShape!)]),
      elementOrder: _originalElementOrder,
    );

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description => 'Remove shape';
}
