part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Eraser tool pointer handlers (stroke, lasso, pixel dispatch).
mixin _EraserGestures<T extends ConsumerStatefulWidget>
    on
        ConsumerState<T>,
        DrawingCanvasHelpers<T>,
        _GestureState<T>,
        _PixelEraserGestures<T>,
        _NoteEraserGestures<T> {
  // ─────────────────────────────────────────────────────────────────────────
  // ERASER EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleEraserDown(PointerDownEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    // Update cursor position and pressure
    ref.read(eraserCursorPositionProvider.notifier).state = event.localPosition;
    ref.read(eraserCursorPressureProvider.notifier).state =
        event.pressure.clamp(0.0, 1.0);

    switch (ref.read(activeEraserModeProvider)) {
      case EraserMode.pixel:
        // Start pixel eraser session
        final pixelTool = ref.read(pixelEraserToolProvider);
        pixelTool.onPointerDown(
          canvasPoint.dx,
          canvasPoint.dy,
          event.pressure.clamp(0.0, 1.0),
        );
        pixelEraseHits.clear();
        pixelEraseOriginalStrokes.clear();
        pixelEraseSweep.clear();
        erasedNoteStrokeIds.clear();
        erasedNoteShapeIds.clear();
        pixelEraseNoteHits.clear();
        pixelEraseNoteOriginalStrokes.clear();
        ref.read(pixelEraserPreviewProvider.notifier).state = {};
        handlePixelEraseAt(canvasPoint, event.pressure.clamp(0.0, 1.0));
        break;

      case EraserMode.stroke:
        // Existing stroke eraser logic
        final eraserTool = ref.read(eraserToolProvider);
        eraserTool.startErasing();
        erasedShapeIds.clear();
        erasedNoteStrokeIds.clear();
        erasedNoteShapeIds.clear();
        pixelEraseNoteHits.clear();
        pixelEraseNoteOriginalStrokes.clear();
        ref.read(strokeEraserPreviewProvider.notifier).state = {};
        eraseAtPoint(event.localPosition);
        break;

      case EraserMode.lasso:
        // Start lasso selection
        final lassoTool = ref.read(lassoEraserToolProvider);
        lassoTool.onPointerDown(canvasPoint.dx, canvasPoint.dy);
        ref.read(lassoEraserPointsProvider.notifier).state = [
          event.localPosition
        ];
        break;
    }
  }

  void handleEraserMove(PointerMoveEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    // Update cursor position and pressure
    ref.read(eraserCursorPositionProvider.notifier).state = event.localPosition;
    ref.read(eraserCursorPressureProvider.notifier).state =
        event.pressure.clamp(0.0, 1.0);

    switch (ref.read(activeEraserModeProvider)) {
      case EraserMode.pixel:
        final pixelTool = ref.read(pixelEraserToolProvider);
        pixelTool.onPointerMove(
          canvasPoint.dx,
          canvasPoint.dy,
          event.pressure.clamp(0.0, 1.0),
        );
        handlePixelEraseAt(canvasPoint, event.pressure.clamp(0.0, 1.0));
        break;

      case EraserMode.stroke:
        eraseAtPoint(event.localPosition);
        break;

      case EraserMode.lasso:
        final lassoTool = ref.read(lassoEraserToolProvider);
        lassoTool.onPointerMove(canvasPoint.dx, canvasPoint.dy);
        ref.read(lassoEraserPointsProvider.notifier).update(
              (points) => [...points, event.localPosition],
            );
        break;
    }
  }

  void handleEraserUp(PointerUpEvent event) {
    final settings = ref.read(eraserSettingsProvider);
    final document = ref.read(documentProvider);
    final layerIndex = document.activeLayerIndex;

    // Clear cursor position and pressure
    ref.read(eraserCursorPositionProvider.notifier).state = null;
    ref.read(eraserCursorPressureProvider.notifier).state = 1.0;

    // One gesture = one undo step, however many commands it commits.
    ref.read(historyManagerProvider.notifier).runBatch(() {
      switch (ref.read(activeEraserModeProvider)) {
        case EraserMode.pixel:
          commitPixelErase(layerIndex);
          break;

        case EraserMode.stroke:
          final eraserTool = ref.read(eraserToolProvider);
          final erasedStrokeIds = eraserTool.endErasing();

          // Commit erased strokes
          if (erasedStrokeIds.isNotEmpty) {
            final command = core.EraseStrokesCommand(
              layerIndex: layerIndex,
              strokeIds: erasedStrokeIds.toList(),
            );
            ref.read(historyManagerProvider.notifier).execute(command);
          }

          // Commit erased shapes
          for (final shapeId in erasedShapeIds) {
            final command = core.RemoveShapeCommand(
              layerIndex: layerIndex,
              shapeId: shapeId,
            );
            ref.read(historyManagerProvider.notifier).execute(command);
          }
          erasedShapeIds.clear();

          // Commit erased note internal strokes/shapes
          _commitNoteErasures(layerIndex);

          // Clear stroke eraser preview
          ref.read(strokeEraserPreviewProvider.notifier).state = {};
          break;

        case EraserMode.lasso:
          commitLassoErase(layerIndex);
          ref.read(lassoEraserPointsProvider.notifier).state = [];
          break;
      }
    }, description: 'Erase');

    // AutoLift: switch back to previous tool after erasing
    if (settings.autoLift) {
      final prevTool = ref.read(previousToolProvider);
      if (prevTool != null) {
        ref.read(currentToolProvider.notifier).selectTool(prevTool);
        ref.read(previousToolProvider.notifier).state = null;
      }
    }
  }

  void commitLassoErase(int layerIndex) {
    final settings = ref.read(eraserSettingsProvider);
    final allStrokes = ref.read(activeLayerStrokesProvider);
    final strokes = applyEraserFilters(allStrokes, settings);
    final lassoTool = ref.read(lassoEraserToolProvider);

    final result = lassoTool.onPointerUp(strokes);

    if (result.affectedSegments.isEmpty) {
      return;
    }

    // Split strokes and create resulting strokes (same as pixel eraser)
    final splitResult = core.StrokeSplitter.splitStrokes(
      result.affectedStrokes,
      result.affectedSegments,
    );

    final resultingStrokes = <core.Stroke>[];
    for (final pieces in splitResult.values) {
      resultingStrokes.addAll(pieces);
    }

    final command = core.ErasePointsCommand(
      layerIndex: layerIndex,
      originalStrokes: result.affectedStrokes,
      resultingStrokes: resultingStrokes,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
  }

  void eraseAtPoint(Offset point) {
    // Transform screen coordinates to canvas coordinates (zoom/pan)
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(point);

    final strokes = ref.read(activeLayerStrokesProvider);
    final shapes = ref.read(activeLayerShapesProvider);
    final eraserTool = ref.read(eraserToolProvider);
    final eraserSettings = ref.read(eraserSettingsProvider);

    // Convert eraser tolerance from screen space to canvas space
    final canvasTolerance = eraserTool.tolerance / transform.zoom;

    // Find strokes to erase
    var toErase = eraserTool.findStrokesToErase(
      strokes,
      canvasPoint.dx,
      canvasPoint.dy,
      toleranceOverride: canvasTolerance,
    );

    // Apply eraser filters
    toErase = applyEraserFilters(toErase, eraserSettings);

    var previewChanged = false;
    for (final stroke in toErase) {
      if (!eraserTool.isAlreadyErased(stroke.id)) {
        eraserTool.markAsErased(stroke.id);
        previewChanged = true;
      }
    }

    // Update real-time visual feedback
    if (previewChanged) {
      ref.read(strokeEraserPreviewProvider.notifier).state =
          Set<String>.from(eraserTool.erasedIds);
    }

    // Find shapes to erase (no filters for shapes)
    for (final shape in shapes) {
      if (!erasedShapeIds.contains(shape.id)) {
        if (shape.containsPoint(
            canvasPoint.dx, canvasPoint.dy, canvasTolerance)) {
          erasedShapeIds.add(shape.id);
        }
      }
    }

    // Eraser does NOT erase texts, images, or stickers.
    // Those are deleted via their own context menu (tap → delete).

    // Erase inside sticky notes (strokes/shapes only)
    _eraseInsideStickyNotes(canvasPoint, canvasTolerance);
  }
}
