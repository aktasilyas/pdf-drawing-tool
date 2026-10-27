import 'package:drawing_core/src/history/indexed_removal.dart';
import 'package:drawing_core/src/internal.dart';

/// Command to remove a stroke from a layer.
///
/// This command removes a stroke by its ID from the specified layer.
/// The removed stroke and its list position are cached for undo, so undo
/// restores the layer exactly (stroke order and elementOrder).
class RemoveStrokeCommand implements DrawingCommand {
  /// The index of the layer to remove the stroke from.
  final int layerIndex;

  /// The ID of the stroke to remove.
  final String strokeId;

  /// Cached stroke and its original index, set during execute.
  IndexedRemoval<Stroke>? _removal;

  /// Cached elementOrder before execute (for undo z-order restore).
  List<String> _originalElementOrder = const [];

  /// Creates a new [RemoveStrokeCommand].
  RemoveStrokeCommand({
    required this.layerIndex,
    required this.strokeId,
  });

  /// The stroke that was removed (available after execute).
  ///
  /// Returns null if execute hasn't been called or the stroke wasn't found.
  Stroke? get removedStroke => _removal?.element;

  @override
  DrawingDocument execute(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layerCount) {
      return document;
    }

    final layer = document.layers[layerIndex];

    // Cache elementOrder before removal (for undo z-order restore)
    _originalElementOrder = List<String>.from(layer.elementOrder);

    // Find and cache the stroke with its position for undo
    final removals = collectRemovals(layer.strokes, [strokeId], (s) => s.id);
    _removal = removals.isEmpty ? null : removals.first;

    if (_removal == null) {
      // Stroke not found, return unchanged
      return document;
    }

    final updatedLayer = layer.removeStroke(strokeId);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    final removal = _removal;
    if (removal == null) {
      // No stroke was removed, return unchanged
      return document;
    }

    if (layerIndex < 0 || layerIndex >= document.layerCount) {
      return document;
    }

    final layer = document.layers[layerIndex];
    final restored = layer.copyWith(
      strokes: reinsertRemovals(layer.strokes, [removal]),
      elementOrder: _originalElementOrder,
    );

    return document.updateLayer(layerIndex, restored);
  }

  @override
  String get description => 'Remove stroke $strokeId from layer $layerIndex';
}
