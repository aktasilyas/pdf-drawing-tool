import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/selection_provider.dart';
import 'package:drawing_ui/src/widgets/selection_geometry.dart';

/// The history command that commits a finished selection drag, or `null`
/// when the live transform in [ui] is a no-op.
///
/// Rotation and scale pivot around the centre of [originalBounds].
DrawingCommand? selectionTransformCommand({
  required SelectionDragMode mode,
  required Selection selection,
  required int layerIndex,
  required BoundingBox originalBounds,
  required SelectionUiState ui,
}) {
  final c = SelectionGeometry.center(originalBounds);
  switch (mode) {
    case SelectionDragMode.move:
      if (ui.moveDelta.dx == 0 && ui.moveDelta.dy == 0) return null;
      return MoveSelectionCommand(
        layerIndex: layerIndex,
        strokeIds: selection.selectedStrokeIds,
        shapeIds: selection.selectedShapeIds,
        imageIds: selection.selectedImageIds,
        textIds: selection.selectedTextIds,
        deltaX: ui.moveDelta.dx,
        deltaY: ui.moveDelta.dy,
      );
    case SelectionDragMode.rotate:
      if (ui.rotation == 0.0) return null;
      return RotateSelectionCommand(
        layerIndex: layerIndex,
        strokeIds: selection.selectedStrokeIds,
        shapeIds: selection.selectedShapeIds,
        imageIds: selection.selectedImageIds,
        textIds: selection.selectedTextIds,
        centerX: c.dx,
        centerY: c.dy,
        angle: ui.rotation,
      );
    case SelectionDragMode.scale:
      if (ui.scaleX == 1.0 && ui.scaleY == 1.0) return null;
      return ScaleSelectionCommand(
        layerIndex: layerIndex,
        strokeIds: selection.selectedStrokeIds,
        shapeIds: selection.selectedShapeIds,
        imageIds: selection.selectedImageIds,
        textIds: selection.selectedTextIds,
        centerX: c.dx,
        centerY: c.dy,
        scaleX: ui.scaleX,
        scaleY: ui.scaleY,
      );
  }
}

/// Bounds of every element of [selection] still present in the active layer
/// of [doc], or `null` when none is left.
BoundingBox? selectedElementBounds(DrawingDocument doc, Selection selection) {
  final layer = doc.layers[doc.activeLayerIndex];
  return SelectionGeometry.union([
    for (final id in selection.selectedStrokeIds)
      if (layer.getStrokeById(id)?.bounds case final b?) b,
    for (final id in selection.selectedShapeIds)
      if (layer.getShapeById(id) case final s?) s.bounds,
    for (final id in selection.selectedImageIds)
      if (layer.getImageById(id) case final i?) i.bounds,
    for (final id in selection.selectedTextIds)
      if (layer.getTextById(id) case final t?) t.bounds,
  ]);
}
