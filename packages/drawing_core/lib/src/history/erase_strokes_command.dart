import 'package:drawing_core/src/history/indexed_removal.dart';
import 'package:drawing_core/src/internal.dart';

/// Removes several strokes in one command.
///
/// One gesture = one command (batching), which keeps undo/redo history
/// clean. Undo puts every stroke back at its original list position and
/// restores elementOrder, so the layer equals the one before execute.
class EraseStrokesCommand implements DrawingCommand {
  /// Index of the layer to erase from.
  final int layerIndex;

  /// IDs of the strokes to erase.
  final List<String> strokeIds;

  /// Erased strokes with their original indices, cached for undo.
  List<IndexedRemoval<Stroke>> _erased = const [];

  /// Cached elementOrder before execute (for undo z-order restore).
  List<String> _originalElementOrder = const [];

  /// Whether execute has cached state for undo.
  bool _executed = false;

  /// Creates an [EraseStrokesCommand] for [strokeIds] on [layerIndex].
  EraseStrokesCommand({
    required this.layerIndex,
    required this.strokeIds,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];

    // Cache elementOrder and erased strokes (with positions) for undo
    _originalElementOrder = List<String>.from(layer.elementOrder);
    _erased = collectRemovals(layer.strokes, strokeIds, (s) => s.id);
    _executed = true;

    var updatedLayer = layer;
    for (final id in strokeIds) {
      updatedLayer = updatedLayer.removeStroke(id);
    }

    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (!_executed || layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];
    final restored = layer.copyWith(
      strokes: reinsertRemovals(layer.strokes, _erased),
      elementOrder: _originalElementOrder,
    );

    return document.updateLayer(layerIndex, restored);
  }

  @override
  String get description => 'Erase ${strokeIds.length} stroke(s)';
}
