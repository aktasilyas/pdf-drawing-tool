import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/selection_transform_commands.dart';

// Keeps the lasso selection tied to the document it points into (#432).

/// [selection] re-read against [after], the document as it is now.
///
/// Returns [selection] itself when every selected element still exists and
/// none of them changed since [before]. Otherwise returns a rectangle
/// selection of the elements still present, with bounds around their
/// current positions, or `null` when none is left (or the page or layer
/// changed underneath it).
Selection? reconcileSelection({
  required DrawingDocument before,
  required DrawingDocument after,
  required Selection selection,
}) {
  if (before.currentPage?.id != after.currentPage?.id ||
      before.activeLayerIndex != after.activeLayerIndex) {
    return null;
  }
  final layers = after.layers;
  final index = after.activeLayerIndex;
  if (index < 0 || index >= layers.length) return null;
  final layer = layers[index];

  final live = Selection(
    id: selection.id,
    type: SelectionType.rectangle,
    selectedStrokeIds: [
      for (final id in selection.selectedStrokeIds)
        if (layer.getStrokeById(id) != null) id,
    ],
    selectedShapeIds: [
      for (final id in selection.selectedShapeIds)
        if (layer.getShapeById(id) != null) id,
    ],
    selectedImageIds: [
      for (final id in selection.selectedImageIds)
        if (layer.getImageById(id) != null) id,
    ],
    selectedTextIds: [
      for (final id in selection.selectedTextIds)
        if (layer.getTextById(id) != null) id,
    ],
    bounds: selection.bounds,
  );
  if (live.isEmpty) return null;

  final nowBounds = selectedElementBounds(after, live);
  if (nowBounds == null) return null;
  final unchanged = live.count == selection.count &&
      _sameElements(before, after, selection);
  if (unchanged) return selection;
  return live.copyWith(bounds: nowBounds);
}

/// [selection] limited to the elements that exist in [doc], or `null` when
/// none does. Actions use it so a stale selection records no history entry.
Selection? liveSelection(DrawingDocument doc, Selection selection) =>
    reconcileSelection(before: doc, after: doc, selection: selection);

bool _sameElements(
  DrawingDocument before,
  DrawingDocument after,
  Selection selection,
) {
  final bi = before.activeLayerIndex;
  if (bi < 0 || bi >= before.layers.length) return false;
  final b = before.layers[bi];
  final a = after.layers[after.activeLayerIndex];
  if (identical(a, b)) return true;
  for (final id in selection.selectedStrokeIds) {
    if (!identical(b.getStrokeById(id), a.getStrokeById(id))) return false;
  }
  for (final id in selection.selectedShapeIds) {
    if (!identical(b.getShapeById(id), a.getShapeById(id))) return false;
  }
  for (final id in selection.selectedImageIds) {
    if (!identical(b.getImageById(id), a.getImageById(id))) return false;
  }
  for (final id in selection.selectedTextIds) {
    if (!identical(b.getTextById(id), a.getTextById(id))) return false;
  }
  return true;
}
