part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Pixel eraser handlers.
mixin _PixelEraserGestures<T extends ConsumerStatefulWidget>
    on
        ConsumerState<T>,
        DrawingCanvasHelpers<T>,
        _GestureState<T>,
        _NoteEraserGestures<T> {
  void handlePixelEraseAt(Offset canvasPoint, double pressure) {
    final strokes = ref.read(activeLayerStrokesProvider);
    final shapes = ref.read(activeLayerShapesProvider);
    final settings = ref.read(eraserSettingsProvider);
    final pixelTool = ref.read(pixelEraserToolProvider);

    // Apply eraser filters first
    final filteredStrokes = applyEraserFilters(strokes, settings);

    // Pressure-scaled size (same helper the cursor uses), converted from
    // screen space to canvas space.
    final zoom = ref.read(canvasTransformProvider).zoom;
    final effectiveSize = settings.effectiveSize(pressure) / zoom;

    // Join this sample to the previous one so fast moves leave no gaps.
    final capsule = pixelEraseSweep.add(
      canvasPoint.dx,
      canvasPoint.dy,
      effectiveSize / 2,
    );
    final hits = pixelTool.findSegmentsAlong(filteredStrokes, capsule);

    for (final hit in hits) {
      // Track original stroke if not already tracked
      if (!pixelEraseHits.containsKey(hit.strokeId)) {
        final originalStroke = filteredStrokes.firstWhere(
          (s) => s.id == hit.strokeId,
          orElse: () => core.Stroke.create(style: core.StrokeStyle.pen()),
        );
        if (originalStroke.id == hit.strokeId) {
          pixelEraseOriginalStrokes.add(originalStroke);
        }
        pixelEraseHits[hit.strokeId] = [];
      }

      // Add segment index if not already present
      if (!pixelEraseHits[hit.strokeId]!.contains(hit.segmentIndex)) {
        pixelEraseHits[hit.strokeId]!.add(hit.segmentIndex);
      }
    }

    // Check shapes (use eraser size as tolerance)
    final tolerance = effectiveSize / 2;
    for (final shape in shapes) {
      if (!erasedShapeIds.contains(shape.id)) {
        if (shape.containsPoint(canvasPoint.dx, canvasPoint.dy, tolerance)) {
          erasedShapeIds.add(shape.id);
        }
      }
    }

    // Eraser does NOT erase texts, images, or stickers.
    // Those are deleted via their own context menu (tap → delete).

    // Erase inside sticky notes (pixel mode: segment-level tracking)
    _eraseInsideStickyNotes(canvasPoint, tolerance, isPixelMode: true);

    // Update preview provider for visual feedback
    // Copy the lists too: the tile cache diffs previews by value, and a
    // shared mutable list would look unchanged.
    ref.read(pixelEraserPreviewProvider.notifier).state = {
      for (final e in pixelEraseHits.entries) e.key: List<int>.of(e.value),
    };
  }

  void commitPixelErase(int layerIndex) {
    // Commit strokes
    if (pixelEraseHits.isNotEmpty && pixelEraseOriginalStrokes.isNotEmpty) {
      // Cut exactly the swept area out of every touched stroke.
      final capsules = pixelEraseSweep.capsules;
      final originals = <core.Stroke>[];
      final resultingStrokes = <core.Stroke>[];
      for (final stroke in pixelEraseOriginalStrokes) {
        final pieces = core.SweepStrokeEraser.erase(stroke, capsules);
        if (pieces == null) continue;
        originals.add(stroke);
        resultingStrokes.addAll(pieces);
      }

      if (originals.isNotEmpty) {
        final command = core.ErasePointsCommand(
          layerIndex: layerIndex,
          originalStrokes: originals,
          resultingStrokes: resultingStrokes,
        );
        ref.read(historyManagerProvider.notifier).execute(command);
      }
    }

    // Commit shapes
    for (final shapeId in erasedShapeIds) {
      final command = core.RemoveShapeCommand(
        layerIndex: layerIndex,
        shapeId: shapeId,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }

    // Commit note internal erasures
    _commitNoteErasures(layerIndex);

    // Clear tracking
    pixelEraseHits.clear();
    pixelEraseOriginalStrokes.clear();
    pixelEraseSweep.clear();
    erasedShapeIds.clear();
    ref.read(pixelEraserPreviewProvider.notifier).state = {};
  }
}
