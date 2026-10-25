part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Eraser logic for strokes and shapes inside sticky notes.
mixin _NoteEraserGestures<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, DrawingCanvasHelpers<T>, _GestureState<T> {
  /// Checks if the eraser point hits strokes/shapes inside any sticky note.
  ///
  /// When [isPixelMode] is true, uses segment-level tracking via
  /// [pixelEraseNoteHits] so that only touched segments are removed.
  /// When false (stroke eraser), removes whole strokes via
  /// [erasedNoteStrokeIds].
  void _eraseInsideStickyNotes(
    Offset canvasPoint,
    double tolerance, {
    bool isPixelMode = false,
  }) {
    final notes = ref.read(activeLayerStickyNotesProvider);
    for (final note in notes) {
      if (note.minimized) continue;
      if (!note.containsPoint(canvasPoint.dx, canvasPoint.dy, tolerance)) {
        continue;
      }

      // Convert to relative coordinates
      final relX = canvasPoint.dx - note.x;
      final relY = canvasPoint.dy - note.y;

      // Check internal strokes
      if (isPixelMode) {
        _pixelEraseNoteStrokes(note, relX, relY, tolerance);
      } else {
        _strokeEraseNoteStrokes(note, relX, relY, tolerance);
      }

      // Check internal shapes (whole shape removal for both modes)
      for (final shape in note.shapes) {
        final noteShapeIds = erasedNoteShapeIds.putIfAbsent(note.id, () => {});
        if (noteShapeIds.contains(shape.id)) continue;
        if (shape.containsPoint(relX, relY, tolerance)) {
          noteShapeIds.add(shape.id);
        }
      }
    }
  }

  /// Pixel eraser: find individual segments hit inside a sticky note.
  void _pixelEraseNoteStrokes(
    core.StickyNote note,
    double relX,
    double relY,
    double tolerance,
  ) {
    final pixelTool = ref.read(pixelEraserToolProvider);
    final settings = ref.read(eraserSettingsProvider);

    final hits = pixelTool.findSegmentsAt(
      note.strokes,
      relX,
      relY,
      settings.size,
    );

    for (final hit in hits) {
      final noteHits = pixelEraseNoteHits.putIfAbsent(note.id, () => {});
      if (!noteHits.containsKey(hit.strokeId)) {
        final origStrokes =
            pixelEraseNoteOriginalStrokes.putIfAbsent(note.id, () => []);
        final originalStroke = note.strokes.firstWhere(
          (s) => s.id == hit.strokeId,
          orElse: () => core.Stroke.create(style: core.StrokeStyle.pen()),
        );
        if (originalStroke.id == hit.strokeId) {
          origStrokes.add(originalStroke);
        }
        noteHits[hit.strokeId] = [];
      }
      if (!noteHits[hit.strokeId]!.contains(hit.segmentIndex)) {
        noteHits[hit.strokeId]!.add(hit.segmentIndex);
      }
    }
  }

  /// Stroke eraser: mark whole strokes hit inside a sticky note.
  void _strokeEraseNoteStrokes(
    core.StickyNote note,
    double relX,
    double relY,
    double tolerance,
  ) {
    for (final stroke in note.strokes) {
      final noteStrokeIds = erasedNoteStrokeIds.putIfAbsent(note.id, () => {});
      if (noteStrokeIds.contains(stroke.id)) continue;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p = stroke.points[i];
        final dist = _pointDist(relX, relY, p.x, p.y);
        if (dist <= tolerance + stroke.style.thickness / 2) {
          noteStrokeIds.add(stroke.id);
          break;
        }
      }
      // Check last point
      if (!noteStrokeIds.contains(stroke.id) && stroke.points.isNotEmpty) {
        final p = stroke.points.last;
        final dist = _pointDist(relX, relY, p.x, p.y);
        if (dist <= tolerance + stroke.style.thickness / 2) {
          noteStrokeIds.add(stroke.id);
        }
      }
    }
  }

  /// Commits all erased note strokes/shapes via UpdateStickyNoteCommand.

  void _commitNoteErasures(int layerIndex) {
    // 1) Pixel-level stroke erasures inside notes (split strokes)
    for (final entry in pixelEraseNoteHits.entries) {
      final noteId = entry.key;
      final strokeHits = entry.value;
      if (strokeHits.isEmpty) continue;

      final origStrokes = pixelEraseNoteOriginalStrokes[noteId];
      if (origStrokes == null || origStrokes.isEmpty) continue;

      final doc = ref.read(documentProvider);
      final ly = doc.layers[layerIndex];
      final note = ly.getStickyNoteById(noteId);
      if (note == null) continue;

      final splitResult =
          core.StrokeSplitter.splitStrokes(origStrokes, strokeHits);
      final affectedIds = strokeHits.keys.toSet();
      final newStrokes = <core.Stroke>[];
      for (final stroke in note.strokes) {
        if (affectedIds.contains(stroke.id)) {
          final original =
              origStrokes.where((s) => s.id == stroke.id).firstOrNull;
          if (original != null) {
            final pieces = splitResult[original];
            if (pieces != null) newStrokes.addAll(pieces);
          }
        } else {
          newStrokes.add(stroke);
        }
      }

      final updated = note.copyWith(strokes: newStrokes);
      final command = core.UpdateStickyNoteCommand(
        layerIndex: layerIndex,
        newNote: updated,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }
    pixelEraseNoteHits.clear();
    pixelEraseNoteOriginalStrokes.clear();

    // 2) Whole-stroke erasures inside notes (stroke eraser mode)
    for (final entry in erasedNoteStrokeIds.entries) {
      final noteId = entry.key;
      final strokeIds = entry.value;
      if (strokeIds.isEmpty) continue;

      final doc = ref.read(documentProvider);
      final ly = doc.layers[layerIndex];
      final note = ly.getStickyNoteById(noteId);
      if (note == null) continue;

      final remaining =
          note.strokes.where((s) => !strokeIds.contains(s.id)).toList();
      final updated = note.copyWith(strokes: remaining);
      final command = core.UpdateStickyNoteCommand(
        layerIndex: layerIndex,
        newNote: updated,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }
    erasedNoteStrokeIds.clear();

    // 3) Erased shapes inside notes (same for both modes)
    for (final entry in erasedNoteShapeIds.entries) {
      final noteId = entry.key;
      final shapeIds = entry.value;
      if (shapeIds.isEmpty) continue;

      final doc = ref.read(documentProvider);
      final ly = doc.layers[layerIndex];
      final note = ly.getStickyNoteById(noteId);
      if (note == null) continue;

      final remaining =
          note.shapes.where((s) => !shapeIds.contains(s.id)).toList();
      final updated = note.copyWith(shapes: remaining);
      final command = core.UpdateStickyNoteCommand(
        layerIndex: layerIndex,
        newNote: updated,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }
    erasedNoteShapeIds.clear();
  }

  double _pointDist(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return math.sqrt(dx * dx + dy * dy);
  }
}
