import 'package:drawing_core/drawing_core.dart';

/// Direction for reordering elements in the layer.
enum ReorderDirection {
  /// Move selected elements to the front (end of list).
  bringToFront,

  /// Move selected elements to the back (beginning of list).
  sendToBack,
}

/// Command to reorder selected strokes and shapes within a layer.
///
/// Moves selected items to the front or back of the layer's rendering order.
/// Caches original indices for undo.
class ReorderSelectionCommand implements DrawingCommand {
  /// The layer index containing the items.
  final int layerIndex;

  /// IDs of strokes to reorder.
  final List<String> strokeIds;

  /// IDs of shapes to reorder.
  final List<String> shapeIds;

  /// Direction to reorder.
  final ReorderDirection direction;

  /// Cached original stroke indices for undo (strokeId → index).
  final Map<String, int> _originalStrokeIndices = {};

  /// Cached original shape indices for undo (shapeId → index).
  final Map<String, int> _originalShapeIndices = {};

  ReorderSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
    this.shapeIds = const [],
    required this.direction,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    // Cache original indices
    _originalStrokeIndices.clear();
    _originalShapeIndices.clear();
    for (final id in strokeIds) {
      final idx = layer.strokes.indexWhere((s) => s.id == id);
      if (idx != -1) _originalStrokeIndices[id] = idx;
    }
    for (final id in shapeIds) {
      final idx = layer.shapes.indexWhere((s) => s.id == id);
      if (idx != -1) _originalShapeIndices[id] = idx;
    }

    // Reorder strokes
    if (strokeIds.isNotEmpty) {
      final strokeIdSet = strokeIds.toSet();
      final selected = layer.strokes.where((s) => strokeIdSet.contains(s.id)).toList();
      final others = layer.strokes.where((s) => !strokeIdSet.contains(s.id)).toList();

      final reordered = direction == ReorderDirection.bringToFront
          ? [...others, ...selected]
          : [...selected, ...others];

      layer = layer.copyWith(strokes: reordered);
    }

    // Reorder shapes
    if (shapeIds.isNotEmpty) {
      final shapeIdSet = shapeIds.toSet();
      final selected = layer.shapes.where((s) => shapeIdSet.contains(s.id)).toList();
      final others = layer.shapes.where((s) => !shapeIdSet.contains(s.id)).toList();

      final reordered = direction == ReorderDirection.bringToFront
          ? [...others, ...selected]
          : [...selected, ...others];

      layer = layer.copyWith(shapes: reordered);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    // Restore strokes to original positions
    if (_originalStrokeIndices.isNotEmpty) {
      final strokeList = List<Stroke>.from(layer.strokes);
      final entries = _originalStrokeIndices.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      for (final entry in entries) {
        final currentIdx = strokeList.indexWhere((s) => s.id == entry.key);
        if (currentIdx == -1) continue;
        final stroke = strokeList.removeAt(currentIdx);
        final targetIdx = entry.value.clamp(0, strokeList.length);
        strokeList.insert(targetIdx, stroke);
      }
      layer = layer.copyWith(strokes: strokeList);
    }

    // Restore shapes to original positions
    if (_originalShapeIndices.isNotEmpty) {
      final shapeList = List<Shape>.from(layer.shapes);
      final entries = _originalShapeIndices.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      for (final entry in entries) {
        final currentIdx = shapeList.indexWhere((s) => s.id == entry.key);
        if (currentIdx == -1) continue;
        final shape = shapeList.removeAt(currentIdx);
        final targetIdx = entry.value.clamp(0, shapeList.length);
        shapeList.insert(targetIdx, shape);
      }
      layer = layer.copyWith(shapes: shapeList);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description =>
      '${direction == ReorderDirection.bringToFront ? 'Bring to front' : 'Send to back'}'
      ' ${strokeIds.length + shapeIds.length} element(s)';
}
