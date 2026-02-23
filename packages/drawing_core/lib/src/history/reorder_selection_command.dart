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

  /// IDs of images to reorder.
  final List<String> imageIds;

  /// IDs of texts to reorder.
  final List<String> textIds;

  /// Direction to reorder.
  final ReorderDirection direction;

  /// Cached original stroke indices for undo (strokeId → index).
  final Map<String, int> _originalStrokeIndices = {};

  /// Cached original shape indices for undo (shapeId → index).
  final Map<String, int> _originalShapeIndices = {};

  /// Cached original image indices for undo (imageId → index).
  final Map<String, int> _originalImageIndices = {};

  /// Cached original text indices for undo (textId → index).
  final Map<String, int> _originalTextIndices = {};

  /// Cached original elementOrder for undo.
  List<String> _originalElementOrder = const [];

  ReorderSelectionCommand({
    required this.layerIndex,
    required this.strokeIds,
    this.shapeIds = const [],
    this.imageIds = const [],
    this.textIds = const [],
    required this.direction,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    // Cache original element order and indices
    _originalElementOrder = List<String>.from(layer.elementOrder);
    _originalStrokeIndices.clear();
    _originalShapeIndices.clear();
    _originalImageIndices.clear();
    _originalTextIndices.clear();
    for (final id in strokeIds) {
      final idx = layer.strokes.indexWhere((s) => s.id == id);
      if (idx != -1) _originalStrokeIndices[id] = idx;
    }
    for (final id in shapeIds) {
      final idx = layer.shapes.indexWhere((s) => s.id == id);
      if (idx != -1) _originalShapeIndices[id] = idx;
    }
    for (final id in imageIds) {
      final idx = layer.images.indexWhere((i) => i.id == id);
      if (idx != -1) _originalImageIndices[id] = idx;
    }
    for (final id in textIds) {
      final idx = layer.texts.indexWhere((t) => t.id == id);
      if (idx != -1) _originalTextIndices[id] = idx;
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

    // Reorder images
    if (imageIds.isNotEmpty) {
      final imageIdSet = imageIds.toSet();
      final selected = layer.images.where((i) => imageIdSet.contains(i.id)).toList();
      final others = layer.images.where((i) => !imageIdSet.contains(i.id)).toList();

      final reordered = direction == ReorderDirection.bringToFront
          ? [...others, ...selected]
          : [...selected, ...others];

      layer = layer.copyWith(images: reordered);
    }

    // Reorder texts
    if (textIds.isNotEmpty) {
      final textIdSet = textIds.toSet();
      final selected = layer.texts.where((t) => textIdSet.contains(t.id)).toList();
      final others = layer.texts.where((t) => !textIdSet.contains(t.id)).toList();

      final reordered = direction == ReorderDirection.bringToFront
          ? [...others, ...selected]
          : [...selected, ...others];

      layer = layer.copyWith(texts: reordered);
    }

    // Reorder elementOrder (all element types render order)
    final allSelectedIds = {...strokeIds, ...shapeIds, ...imageIds, ...textIds};
    if (allSelectedIds.isNotEmpty && layer.elementOrder.isNotEmpty) {
      final selected = layer.elementOrder
          .where((id) => allSelectedIds.contains(id))
          .toList();
      final others = layer.elementOrder
          .where((id) => !allSelectedIds.contains(id))
          .toList();

      final reordered = direction == ReorderDirection.bringToFront
          ? [...others, ...selected]
          : [...selected, ...others];

      layer = layer.copyWith(elementOrder: reordered);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    var layer = document.layers[layerIndex];

    // Restore strokes to original positions using ID-to-index rebuild
    if (_originalStrokeIndices.isNotEmpty) {
      layer = layer.copyWith(strokes: _restoreOrder<Stroke>(
        layer.strokes, _originalStrokeIndices, (s) => s.id));
    }

    // Restore shapes to original positions using ID-to-index rebuild
    if (_originalShapeIndices.isNotEmpty) {
      layer = layer.copyWith(shapes: _restoreOrder<Shape>(
        layer.shapes, _originalShapeIndices, (s) => s.id));
    }

    // Restore images to original positions using ID-to-index rebuild
    if (_originalImageIndices.isNotEmpty) {
      layer = layer.copyWith(images: _restoreOrder<ImageElement>(
        layer.images, _originalImageIndices, (i) => i.id));
    }

    // Restore texts to original positions using ID-to-index rebuild
    if (_originalTextIndices.isNotEmpty) {
      layer = layer.copyWith(texts: _restoreOrder<TextElement>(
        layer.texts, _originalTextIndices, (t) => t.id));
    }

    // Restore elementOrder
    if (_originalElementOrder.isNotEmpty) {
      layer = layer.copyWith(elementOrder: _originalElementOrder);
    }

    return document.updateLayer(layerIndex, layer);
  }

  /// Rebuilds [items] so that cached items land at their original indices
  /// and non-cached items fill the remaining slots in their current order.
  List<T> _restoreOrder<T>(
    List<T> items, Map<String, int> originalIndices, String Function(T) getId,
  ) {
    final idToItem = {for (final item in items) getId(item): item};
    final result = List<T?>.filled(items.length, null);
    final cachedIds = originalIndices.keys.toSet();

    // Place cached items at their original positions
    for (final entry in originalIndices.entries) {
      final item = idToItem[entry.key];
      if (item != null && entry.value < result.length) {
        result[entry.value] = item;
      }
    }

    // Fill remaining slots with non-cached items in current order
    final remaining = items.where((i) => !cachedIds.contains(getId(i)));
    final ri = remaining.iterator;
    for (var i = 0; i < result.length; i++) {
      if (result[i] == null && ri.moveNext()) result[i] = ri.current;
    }

    return result.whereType<T>().toList();
  }

  @override
  String get description =>
      '${direction == ReorderDirection.bringToFront ? 'Bring to front' : 'Send to back'}'
      ' ${strokeIds.length + shapeIds.length + imageIds.length + textIds.length} element(s)';
}
