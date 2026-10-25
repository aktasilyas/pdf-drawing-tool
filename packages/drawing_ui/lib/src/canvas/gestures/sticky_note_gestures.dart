part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Sticky-note helpers shared by the drawing gestures.
mixin _StickyNoteGestures<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, DrawingCanvasHelpers<T>, _GestureState<T> {
  /// Detects if the pointer starts inside a (non-minimized) sticky note
  /// and stores it for point clamping during the stroke.
  void _detectDrawingInsideNote(PointerEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final cp = transform.screenToCanvas(event.localPosition);
    final notes = ref.read(activeLayerStickyNotesProvider);
    drawingInsideNote = null;
    for (final note in notes.reversed) {
      if (!note.minimized && note.containsPoint(cp.dx, cp.dy, 0)) {
        drawingInsideNote = note;
        return;
      }
    }
  }

  /// Clamps a drawing point to the sticky note bounds when drawing inside one.
  core.DrawingPoint _clampToNote(core.DrawingPoint point) {
    final note = drawingInsideNote;
    if (note == null) return point;
    return core.DrawingPoint(
      x: point.x.clamp(note.x, note.x + note.width),
      y: point.y.clamp(note.y, note.y + note.height),
      pressure: point.pressure,
      tilt: point.tilt,
      timestamp: point.timestamp,
    );
  }

  /// Converts a stroke to relative coordinates and adds it to the sticky note.
  void _addStrokeToStickyNote(core.Stroke stroke, core.StickyNote note) {
    final relPoints = stroke.points
        .map((p) => core.DrawingPoint(
              x: p.x - note.x,
              y: p.y - note.y,
              pressure: p.pressure,
              tilt: p.tilt,
              timestamp: p.timestamp,
            ))
        .toList();
    final relStroke = stroke.copyWith(points: relPoints);

    // Get the current note from the document (may have changed)
    final document = ref.read(documentProvider);
    final layer = document.layers[document.activeLayerIndex];
    final currentNote = layer.getStickyNoteById(note.id);
    if (currentNote == null) return;

    final updated =
        currentNote.copyWith(strokes: [...currentNote.strokes, relStroke]);
    final command = core.UpdateStickyNoteCommand(
      layerIndex: document.activeLayerIndex,
      newNote: updated,
    );
    ref.read(historyManagerProvider.notifier).execute(command);

    // Sync the selected note so overrideNote renders the updated version
    final placement = ref.read(stickyNotePlacementProvider);
    if (placement.selectedNote?.id == note.id) {
      ref
          .read(stickyNotePlacementProvider.notifier)
          .updateSelectedNote(updated);
    }
  }

  /// Converts a shape to relative coordinates and adds it to the sticky note.
  void _addShapeToStickyNote(core.Shape shape, core.StickyNote note) {
    final relShape = shape.copyWith(
      startPoint: core.DrawingPoint(
        x: shape.startPoint.x - note.x,
        y: shape.startPoint.y - note.y,
        pressure: shape.startPoint.pressure,
        tilt: shape.startPoint.tilt,
        timestamp: shape.startPoint.timestamp,
      ),
      endPoint: core.DrawingPoint(
        x: shape.endPoint.x - note.x,
        y: shape.endPoint.y - note.y,
        pressure: shape.endPoint.pressure,
        tilt: shape.endPoint.tilt,
        timestamp: shape.endPoint.timestamp,
      ),
    );

    final document = ref.read(documentProvider);
    final layer = document.layers[document.activeLayerIndex];
    final currentNote = layer.getStickyNoteById(note.id);
    if (currentNote == null) return;

    final updated =
        currentNote.copyWith(shapes: [...currentNote.shapes, relShape]);
    final command = core.UpdateStickyNoteCommand(
      layerIndex: document.activeLayerIndex,
      newNote: updated,
    );
    ref.read(historyManagerProvider.notifier).execute(command);

    // Sync the selected note so overrideNote renders the updated version
    final placement = ref.read(stickyNotePlacementProvider);
    if (placement.selectedNote?.id == note.id) {
      ref
          .read(stickyNotePlacementProvider.notifier)
          .updateSelectedNote(updated);
    }
  }

  /// Minimizes (if not already) and deselects a sticky note.
  void _minimizeAndDeselectNote(core.StickyNote note) {
    if (!note.minimized) {
      final document = ref.read(documentProvider);
      final updated = note.copyWith(minimized: true);
      final command = core.UpdateStickyNoteCommand(
        layerIndex: document.activeLayerIndex,
        newNote: updated,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }
    ref.read(stickyNotePlacementProvider.notifier).deselectNote();
  }

  /// Handles pointer down while the sticky note tool is active.
  void _handleStickyNoteToolDown(PointerDownEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint =
        (event.localPosition - transform.offset) / transform.zoom;
    final currentNoteState = ref.read(stickyNotePlacementProvider);

    // If a selected (non-minimized) note is showing resize handles,
    // check if tap is inside the note → let handles handle it.
    // If outside → minimize and deselect, then check other notes.
    if (currentNoteState.selectedNote != null &&
        !currentNoteState.showMenu &&
        !currentNoteState.selectedNote!.minimized) {
      if (currentNoteState.selectedNote!
          .containsPoint(canvasPoint.dx, canvasPoint.dy, 0)) {
        return; // Inside note → resize handles handle it
      }
      // Outside note → minimize and deselect
      _minimizeAndDeselectNote(currentNoteState.selectedNote!);
    }

    final notes = ref.read(activeLayerStickyNotesProvider);
    for (final note in notes.reversed) {
      if (note.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
        if (note.minimized) {
          // Maximize the note
          final maximized = note.copyWith(minimized: false);
          final document = ref.read(documentProvider);
          final command = core.UpdateStickyNoteCommand(
            layerIndex: document.activeLayerIndex,
            newNote: maximized,
          );
          ref.read(historyManagerProvider.notifier).execute(command);
          ref.read(stickyNotePlacementProvider.notifier).selectNote(maximized);
          return;
        }
        ref.read(stickyNotePlacementProvider.notifier).selectNote(note);
        return;
      }
    }
    // Tap on empty area → deselect
    ref.read(stickyNotePlacementProvider.notifier).deselectNote();
    return;
  }
}
