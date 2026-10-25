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

    // Convert eraser size from screen space to canvas space
    final zoom = ref.read(canvasTransformProvider).zoom;
    final baseSize = settings.size / zoom;

    // Scale eraser size based on pressure when pressure sensitivity is on
    final effectiveSize = settings.pressureSensitive
        ? baseSize * (0.3 + 0.7 * pressure)
        : baseSize;

    final hits = pixelTool.findSegmentsAt(
      filteredStrokes,
      canvasPoint.dx,
      canvasPoint.dy,
      effectiveSize,
    );

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
    ref.read(pixelEraserPreviewProvider.notifier).state =
        Map<String, List<int>>.from(pixelEraseHits);
  }

  void commitPixelErase(int layerIndex) {
    // Commit strokes
    if (pixelEraseHits.isNotEmpty && pixelEraseOriginalStrokes.isNotEmpty) {
      // Split strokes and create resulting strokes
      final splitResult = core.StrokeSplitter.splitStrokes(
        pixelEraseOriginalStrokes,
        pixelEraseHits,
      );

      final resultingStrokes = <core.Stroke>[];
      for (final pieces in splitResult.values) {
        resultingStrokes.addAll(pieces);
      }

      final command = core.ErasePointsCommand(
        layerIndex: layerIndex,
        originalStrokes: pixelEraseOriginalStrokes.toList(),
        resultingStrokes: resultingStrokes,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
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
    erasedShapeIds.clear();
    ref.read(pixelEraserPreviewProvider.notifier).state = {};
  }
}
