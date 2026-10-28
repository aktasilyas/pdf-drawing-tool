part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Pointer-down dispatch: routes a single-finger down event to the active tool.
mixin _PointerDownGestures<T extends ConsumerStatefulWidget>
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
  // ─────────────────────────────────────────────────────────────────────────
  // POINTER EVENT HANDLERS (Single Finger Drawing)
  // ─────────────────────────────────────────────────────────────────────────

  /// Handles pointer down - starts a new stroke, eraser, selection, shape, or text.
  void handlePointerDown(PointerDownEvent event) {
    // ══════════════════════════════════════════════════════════════
    // Sayfa sınırı kontrolü (LIMITED mod için)
    // ══════════════════════════════════════════════════════════════
    final mode = canvasMode ?? const core.CanvasMode(isInfinite: true);

    if (!mode.allowDrawingOutsidePage) {
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint = transform.screenToCanvas(event.localPosition);
      final currentPage = ref.read(currentPageProvider);

      // Sayfa dışında mı?
      if (canvasPoint.dx < 0 ||
          canvasPoint.dx > currentPage.size.width ||
          canvasPoint.dy < 0 ||
          canvasPoint.dy > currentPage.size.height) {
        return; // Sayfa dışı - çizim başlatma
      }
    }
    // ══════════════════════════════════════════════════════════════

    // Block drawing on locked or hidden active layer
    final activeLayer = ref.read(documentProvider).activeLayer;
    if (activeLayer != null &&
        (activeLayer.isLocked || !activeLayer.isVisible)) {
      return;
    }

    pointerCount++;

    // Only handle with single finger
    if (pointerCount != 1) return;

    // Get current tool type
    final toolType = ref.read(currentToolProvider);

    // If text editing is active and tap is outside, finish editing
    final textToolState = ref.read(textToolProvider);
    if (textToolState.isEditing && toolType != ToolType.text) {
      finishTextEditing();
      return;
    }

    // Dismiss paste menu if showing
    final pasteMenu = ref.read(pasteMenuProvider);
    if (pasteMenu != null) {
      ref.read(pasteMenuProvider.notifier).state = null;
      return;
    }

    // Close selection context menu if showing
    final selUi = ref.read(selectionUiProvider);
    final isSelectionTool = ref.read(isSelectionToolProvider);
    if (selUi.showMenu) {
      ref.read(selectionUiProvider.notifier).hideContextMenu();
      if (isSelectionTool) {
        // If tap is inside existing selection, just hide menu and let
        // SelectionHandles handle the interaction (move/resize/rotate).
        final selection = ref.read(selectionProvider);
        if (selection != null) {
          final transform = ref.read(canvasTransformProvider);
          final canvasPoint =
              (event.localPosition - transform.offset) / transform.zoom;
          if (isPointInSelection(canvasPoint, selection)) {
            return;
          }
        }
        // Tap is outside — clear and start new selection
        ref.read(selectionProvider.notifier).clearSelection();
        ref.read(selectionUiProvider.notifier).reset();
        handleSelectionDown(event);
        return;
      }
      return;
    }

    // Close sticky note context menu if showing
    final stickyNoteState = ref.read(stickyNotePlacementProvider);
    if (stickyNoteState.showMenu) {
      ref.read(stickyNotePlacementProvider.notifier).hideContextMenu();
      return;
    }

    // If a sticky note is selected and we're not on stickyNote tool,
    // minimize and deselect if tapping OUTSIDE the note (allow drawing inside).
    final selectedNote = ref.read(selectedStickyNoteProvider);
    if (selectedNote != null && toolType != ToolType.stickyNote) {
      final transform = ref.read(canvasTransformProvider);
      final cp = transform.screenToCanvas(event.localPosition);
      if (!selectedNote.containsPoint(cp.dx, cp.dy, 0)) {
        _minimizeAndDeselectNote(selectedNote);
      }
    }

    // Close text context menu/style popup if showing
    if (textToolState.showMenu) {
      ref.read(textToolProvider.notifier).hideContextMenu();
      return;
    }
    if (textToolState.showStylePopup) {
      ref.read(textToolProvider.notifier).hideStylePopup();
      return;
    }

    // Check if selection tool is active
    if (isSelectionTool) {
      _handleSelectionToolDown(event);
      return;
    }

    // Check if there's an existing selection and tap is outside
    final selection = ref.read(selectionProvider);
    if (selection != null) {
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint =
          (event.localPosition - transform.offset) / transform.zoom;

      if (!isPointInSelection(canvasPoint, selection)) {
        ref.read(selectionProvider.notifier).clearSelection();
        ref.read(selectionUiProvider.notifier).reset();
      }
    }

    // Check if sticker placement mode is active
    final stickerState = ref.read(stickerPlacementProvider);
    if (stickerState.isPlacing) {
      _handleStickerPlacement(event);
      return;
    }

    // Check if image placement mode is active
    final imageState = ref.read(imagePlacementProvider);
    if (imageState.isPlacing) {
      _handleImagePlacement(event);
      return;
    }

    // Sticky note tool — tap on existing note selects it
    if (toolType == ToolType.stickyNote) {
      _handleStickyNoteToolDown(event);
      return;
    }

    // Image tool selected (no placement) — tap on existing image selects it
    // via the main selection system (SelectionHandles + SelectionToolbar)
    if (toolType == ToolType.image) {
      _handleImageToolDown(event);
      return;
    }

    // Sticker tool selected (no placement) — tap on existing text selects it
    if (toolType == ToolType.sticker) {
      _trySelectTextAt(event);
      return; // Sticker tool does nothing on empty area without placement
    }

    // Laser pointer tool
    if (toolType == ToolType.laserPointer) {
      handleLaserDown(event);
      return;
    }

    // Check if eraser is active
    final isEraser = ref.read(isEraserToolProvider);
    if (isEraser) {
      handleEraserDown(event);
      return;
    }

    // Check if shape tool is active
    final isShapeTool = ref.read(isShapeToolProvider);
    if (isShapeTool) {
      handleShapeDown(event);
      return;
    }

    // Check if text tool is active
    if (toolType == ToolType.text) {
      handleTextDown(event);
      return;
    }

    // Check if highlighter straight line mode is active
    if ((toolType == ToolType.highlighter ||
            toolType == ToolType.neonHighlighter) &&
        ref.read(highlighterSettingsProvider).straightLineMode) {
      handleStraightLineDown(event);
      return;
    }

    // Ruler pen always draws straight lines
    if (toolType == ToolType.rulerPen) {
      handleStraightLineDown(event);
      return;
    }

    // Check if tap is on an existing text/sticker — select it
    if (_trySelectTextAt(event)) return;

    _startFreehandStroke(event, toolType);
  }

  /// Starts a freehand stroke for the current pen/highlighter tool.
  void _startFreehandStroke(PointerDownEvent event, ToolType toolType) {
    // Block drawing when pointer is on the ruler body
    if (_isPointOnRuler(event.localPosition)) return;

    // Drawing mode — detect sticky note constraint
    _detectDrawingInsideNote(event);
    var point = _clampToNote(createDrawingPoint(event));
    point = _snapToRuler(point);
    final style = getCurrentStyle();

    // Get stabilization setting (only for pen tools, not highlighters)
    double stabilization = 0.0;
    if (toolType.isPenTool &&
        toolType != ToolType.highlighter &&
        toolType != ToolType.neonHighlighter) {
      final penSettings = ref.read(penSettingsProvider(toolType));
      stabilization = penSettings.stabilization;
    }

    drawingController.startStroke(
      point,
      style,
      stabilization: stabilization,
      straightLine: false,
    );

    lastPoint = event.localPosition;
  }
}
