part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Pointer move/up/cancel handlers for single-finger drawing.
mixin _PointerMoveUpGestures<T extends ConsumerStatefulWidget>
    on
        ConsumerState<T>,
        DrawingCanvasHelpers<T>,
        _GestureState<T>,
        _RulerSnapping<T>,
        _StickyNoteGestures<T>,
        _TextGestures<T>,
        _PlacementGestures<T>,
        _SelectionGestures<T>,
        _ShapeGestures<T>,
        _StraightLineGestures<T>,
        _LaserGestures<T>,
        _NoteEraserGestures<T>,
        _PixelEraserGestures<T>,
        _EraserGestures<T>,
        _ScaleGestures<T> {
  /// Handles pointer move - adds points to active stroke, erases, updates selection, or shape.
  void handlePointerMove(PointerMoveEvent event) {
    // Only handle with single finger
    if (pointerCount != 1) return;

    // ══════════════════════════════════════════════════════════════
    // Sayfa sınırı kontrolü (LIMITED mod için)
    // ══════════════════════════════════════════════════════════════
    final mode = canvasMode ?? const core.CanvasMode(isInfinite: true);

    if (!mode.allowDrawingOutsidePage && drawingController.isDrawing) {
      final currentPage = ref.read(currentPageProvider);
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint = transform.screenToCanvas(event.localPosition);

      // Sayfa dışındaysa - çizime devam etme
      if (canvasPoint.dx < 0 ||
          canvasPoint.dx > currentPage.size.width ||
          canvasPoint.dy < 0 ||
          canvasPoint.dy > currentPage.size.height) {
        return;
      }
    }
    // ══════════════════════════════════════════════════════════════

    // Cancel long press timer if finger moved too far
    if (_longPressTimer != null && _longPressScreenPos != null) {
      final dist = (event.localPosition - _longPressScreenPos!).distance;
      if (dist > 10) {
        _longPressTimer?.cancel();
        _longPressTimer = null;
      }
    }

    // Selection mode
    if (isSelecting) {
      handleSelectionMove(event);
      return;
    }

    // Shape mode
    if (isDrawingShape) {
      handleShapeMove(event);
      return;
    }

    // Straight line mode (highlighter)
    if (isStraightLineDrawing) {
      handleStraightLineMove(event);
      return;
    }

    // Laser pointer mode
    if (isLaserDrawing) {
      handleLaserMove(event);
      return;
    }

    // Check if eraser is active
    final isEraser = ref.read(isEraserToolProvider);
    if (isEraser) {
      handleEraserMove(event);
      return;
    }

    // Drawing mode
    if (!drawingController.isDrawing) return;

    // Performance: Skip points that are too close together
    final lastPointValue = lastPoint;
    if (lastPointValue != null) {
      final distance = (event.localPosition - lastPointValue).distance;
      if (distance < DrawingCanvasGestureHandlers.minPointDistance) return;
    }

    var point = _clampToNote(createDrawingPoint(event));
    point = _snapToRuler(point);
    drawingController.addPoint(point);
    lastPoint = event.localPosition;
  }

  /// Handles pointer up - finishes stroke, eraser, selection, or shape.
  void handlePointerUp(PointerUpEvent event) {
    _longPressTimer?.cancel();
    _longPressTimer = null;

    pointerCount = (pointerCount - 1).clamp(0, 10);

    // Guard against disposed widget (e.g. page transition disposes canvas)
    if (!mounted) return;

    // Selection mode
    if (isSelecting) {
      handleSelectionUp(event);
      return;
    }

    // Shape mode
    if (isDrawingShape) {
      handleShapeUp(event);
      return;
    }

    // Straight line mode
    if (isStraightLineDrawing) {
      handleStraightLineUp(event);
      return;
    }

    // Laser pointer mode
    if (isLaserDrawing) {
      handleLaserUp(event);
      return;
    }

    // Check if eraser is active
    final isEraser = ref.read(isEraserToolProvider);
    if (isEraser) {
      handleEraserUp(event);
      return;
    }

    // Drawing mode - commit if we were drawing with single finger
    if (pointerCount == 0 && drawingController.isDrawing) {
      final stroke = drawingController.endStroke();

      if (stroke != null) {
        if (drawingInsideNote != null) {
          _addStrokeToStickyNote(stroke, drawingInsideNote!);
        } else {
          ref.read(historyManagerProvider.notifier).addStroke(stroke);
        }
      }
    }
    drawingInsideNote = null;
    lastPoint = null;
  }

  /// Handles pointer cancel - cancels the current operation.
  void handlePointerCancel(PointerCancelEvent event) {
    _longPressTimer?.cancel();
    _longPressTimer = null;

    pointerCount = (pointerCount - 1).clamp(0, 10);

    if (!mounted) return;

    // Selection mode
    if (isSelecting) {
      ref.read(activeSelectionToolProvider).cancelSelection();
      isSelecting = false;
      setState(() {});
      return;
    }

    // Shape mode
    if (isDrawingShape) {
      activeShapeTool?.cancelShape();
      activeShapeTool = null;
      isDrawingShape = false;
      setState(() {});
      return;
    }

    // Straight line mode
    if (isStraightLineDrawing) {
      straightLineStart = null;
      straightLineEnd = null;
      straightLineStyle = null;
      isStraightLineDrawing = false;
      setState(() {});
      return;
    }

    // Laser pointer mode
    if (isLaserDrawing) {
      laserController.cancelStroke();
      isLaserDrawing = false;
      return;
    }

    // Check if eraser is active
    final isEraser = ref.read(isEraserToolProvider);
    if (isEraser) {
      handleEraserCancel();
    } else {
      drawingController.cancelStroke();
    }
    drawingInsideNote = null;
    lastPoint = null;
  }
}
