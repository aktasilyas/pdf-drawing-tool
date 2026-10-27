import 'package:drawing_core/src/internal.dart';

// Commands that change the layer structure of the current page.
//
// They act on `document.layers` (the current page for multi-page documents).
// `HistoryManager` makes the recording page current before undo/redo, which
// resets the active layer index, so every command saves the active index it
// first saw and sets the index explicitly in both `execute` and `undo`.
// Inverses locate layers by id, so unrelated layer edits (rename, visibility,
// lock, opacity) are never reverted.

/// Adds [layer] at [index] (default: top) and makes it the active layer.
class AddLayerCommand implements DrawingCommand {
  AddLayerCommand({
    required this.layer,
    this.index,
    this.description = 'Add layer',
  });

  final Layer layer;

  /// Insert position; `null` appends on top.
  final int? index;

  @override
  final String description;

  int? _activeBefore;

  @override
  DrawingDocument execute(DrawingDocument document) {
    _activeBefore ??= document.activeLayerIndex;
    final layers = List<Layer>.from(document.layers);
    final at = (index ?? layers.length).clamp(0, layers.length).toInt();
    layers.insert(at, layer);
    return document.withLayers(layers, activeLayerIndex: at);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    final layers = List<Layer>.from(document.layers);
    final at = layers.indexWhere((l) => l.id == layer.id);
    if (at < 0) return document;
    layers.removeAt(at);
    return document.withLayers(
      layers,
      activeLayerIndex: _activeBefore ?? document.activeLayerIndex,
    );
  }
}

/// Removes the layer at [layerIndex] with all its content.
///
/// A no-op when the index is invalid or only one layer is left.
class RemoveLayerCommand implements DrawingCommand {
  RemoveLayerCommand({required this.layerIndex});

  final int layerIndex;

  Layer? _removed;
  int? _activeBefore;

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layers = List<Layer>.from(document.layers);
    if (layers.length <= 1 || layerIndex < 0 || layerIndex >= layers.length) {
      _removed = null;
      return document;
    }
    final active = _activeBefore ??= document.activeLayerIndex;
    _removed = layers.removeAt(layerIndex);

    // Same adjustment as DrawingDocument.removeLayer.
    var newActive = active;
    if (active >= layers.length) {
      newActive = layers.length - 1;
    } else if (active > layerIndex) {
      newActive = active - 1;
    }
    return document.withLayers(layers, activeLayerIndex: newActive);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    final removed = _removed;
    if (removed == null) return document;
    final layers = List<Layer>.from(document.layers);
    if (layers.any((l) => l.id == removed.id)) return document;
    layers.insert(layerIndex.clamp(0, layers.length).toInt(), removed);
    return document.withLayers(
      layers,
      activeLayerIndex: _activeBefore ?? document.activeLayerIndex,
    );
  }

  @override
  String get description => 'Remove layer';
}

/// Moves the layer at [oldIndex] so it ends at [newIndex].
///
/// Remove-then-insert semantics: [newIndex] is the position after the layer
/// has been removed. The active index follows the active layer.
class ReorderLayersCommand implements DrawingCommand {
  ReorderLayersCommand({required this.oldIndex, required this.newIndex});

  final int oldIndex;
  final int newIndex;

  String? _movedId;
  int? _activeBefore;

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layers = List<Layer>.from(document.layers);
    if (oldIndex < 0 ||
        oldIndex >= layers.length ||
        newIndex < 0 ||
        newIndex >= layers.length ||
        oldIndex == newIndex) {
      _movedId = null;
      return document;
    }
    final active = _activeBefore ??= document.activeLayerIndex;
    final inRange = active >= 0 && active < layers.length;
    final activeId = inRange ? layers[active].id : null;

    final moved = layers.removeAt(oldIndex);
    layers.insert(newIndex, moved);
    _movedId = moved.id;

    var newActive = active;
    if (activeId != null) {
      newActive = layers.indexWhere((l) => l.id == activeId);
    }
    return document.withLayers(layers, activeLayerIndex: newActive);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    final movedId = _movedId;
    if (movedId == null) return document;
    final layers = List<Layer>.from(document.layers);
    final at = layers.indexWhere((l) => l.id == movedId);
    if (at < 0) return document;
    final moved = layers.removeAt(at);
    layers.insert(oldIndex.clamp(0, layers.length).toInt(), moved);
    return document.withLayers(
      layers,
      activeLayerIndex: _activeBefore ?? document.activeLayerIndex,
    );
  }

  @override
  String get description => 'Reorder layers';
}
