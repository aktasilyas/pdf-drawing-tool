part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Selection tool handlers: lasso/rectangle select and tap-to-select.
mixin _SelectionGestures<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, DrawingCanvasHelpers<T>, _GestureState<T> {
  // ─────────────────────────────────────────────────────────────────────────
  // SELECTION EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleSelectionDown(PointerDownEvent event) {
    // Clear any existing selection first
    ref.read(selectionProvider.notifier).clearSelection();
    ref.read(selectionUiProvider.notifier).reset();

    final transform = ref.read(canvasTransformProvider);
    final canvasPoint =
        (event.localPosition - transform.offset) / transform.zoom;

    final tool = ref.read(activeSelectionToolProvider);
    tool.startSelection(core.DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: 1.0,
    ));

    isSelecting = true;
    setState(() {});
  }

  void handleSelectionMove(PointerMoveEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint =
        (event.localPosition - transform.offset) / transform.zoom;

    final tool = ref.read(activeSelectionToolProvider);
    tool.updateSelection(core.DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: 1.0,
    ));

    // Trigger rebuild for preview
    setState(() {});
  }

  void handleSelectionUp(PointerUpEvent event) {
    isSelecting = false;

    final tool = ref.read(activeSelectionToolProvider);
    final allStrokes = ref.read(activeLayerStrokesProvider);
    final allShapes = ref.read(activeLayerShapesProvider);
    final allImages = ref.read(activeLayerImagesProvider);
    final allTexts = ref.read(activeLayerTextsProvider);
    final lassoSettings = ref.read(lassoSettingsProvider);

    // Filter by selectable type settings
    final strokes = filterStrokesBySelectableType(
      allStrokes,
      lassoSettings.selectableTypes,
    );
    final allowShapes =
        lassoSettings.selectableTypes[SelectableType.shape] ?? true;
    final shapes = allowShapes ? allShapes : <core.Shape>[];
    final allowImages =
        lassoSettings.selectableTypes[SelectableType.imageSticker] ?? true;
    final images = allowImages ? allImages : <core.ImageElement>[];
    // Text/stickers use the same filter as imageSticker
    final texts = allowImages ? allTexts : <core.TextElement>[];

    var selection = tool.endSelection(strokes, shapes, images, texts);

    // Tap-to-select: when the rectangle is too small (tap), hit test the
    // tap point against individual element bounds (topmost first).
    if (selection == null) {
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint =
          (event.localPosition - transform.offset) / transform.zoom;
      selection = _hitTestElementsAtPoint(
        canvasPoint,
        strokes,
        shapes,
        images,
        texts,
      );
    }

    if (selection != null) {
      ref.read(selectionProvider.notifier).setSelection(selection);
      ref.read(selectionUiProvider.notifier).showContextMenu();
    }

    setState(() {});
  }

  /// Hit-tests a single point against elements and returns a selection
  /// containing the topmost hit element, or null if nothing was hit.
  core.Selection? _hitTestElementsAtPoint(
    Offset point,
    List<core.Stroke> strokes,
    List<core.Shape> shapes,
    List<core.ImageElement> images,
    List<core.TextElement> texts,
  ) {
    const tolerance = 10.0;
    final px = point.dx, py = point.dy;

    // Check elements in reverse (topmost first) using element order
    final doc = ref.read(documentProvider);
    final layer = doc.layers[doc.activeLayerIndex];
    final order = layer.elementOrder;

    for (int i = order.length - 1; i >= 0; i--) {
      final id = order[i];

      // Check texts
      final text = texts.where((t) => t.id == id).firstOrNull;
      if (text != null && text.containsPoint(px, py, tolerance)) {
        return core.Selection.create(
          type: core.SelectionType.rectangle,
          selectedStrokeIds: const [],
          selectedTextIds: [id],
          bounds: text.bounds,
        );
      }

      // Check images
      final image = images.where((img) => img.id == id).firstOrNull;
      if (image != null && image.containsPoint(px, py, tolerance)) {
        return core.Selection.create(
          type: core.SelectionType.rectangle,
          selectedStrokeIds: const [],
          selectedImageIds: [id],
          bounds: image.bounds,
        );
      }

      // Check shapes
      final shape = shapes.where((s) => s.id == id).firstOrNull;
      if (shape != null) {
        final b = shape.bounds;
        if (px >= b.left - tolerance &&
            px <= b.right + tolerance &&
            py >= b.top - tolerance &&
            py <= b.bottom + tolerance) {
          return core.Selection.create(
            type: core.SelectionType.rectangle,
            selectedStrokeIds: const [],
            selectedShapeIds: [id],
            bounds: b,
          );
        }
      }

      // Check strokes
      final stroke = strokes.where((s) => s.id == id).firstOrNull;
      if (stroke != null) {
        final b = stroke.bounds;
        if (b != null &&
            px >= b.left - tolerance &&
            px <= b.right + tolerance &&
            py >= b.top - tolerance &&
            py <= b.bottom + tolerance) {
          return core.Selection.create(
            type: core.SelectionType.rectangle,
            selectedStrokeIds: [id],
            bounds: b,
          );
        }
      }
    }

    return null;
  }

  /// Selection tool pointer down: ignores taps inside an existing selection,
  /// arms the paste-menu long press timer and starts a new selection.
  void _handleSelectionToolDown(PointerDownEvent event) {
    // Check if there's an existing selection
    final selection = ref.read(selectionProvider);
    if (selection != null) {
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint =
          (event.localPosition - transform.offset) / transform.zoom;

      // If tap is inside selection, let SelectionHandles handle the drag
      if (isPointInSelection(canvasPoint, selection)) {
        // Don't start new selection - SelectionHandles will handle this
        return;
      }
    }

    // Start long press timer for paste menu (only if clipboard has data)
    final clipboard = ref.read(selectionClipboardProvider);
    if (clipboard != null) {
      _longPressScreenPos = event.localPosition;
      _longPressTimer?.cancel();
      _longPressTimer = Timer(const Duration(milliseconds: 500), () {
        _longPressTimer = null;
        isSelecting = false;
        ref.read(activeSelectionToolProvider).cancelSelection();
        final transform = ref.read(canvasTransformProvider);
        final canvasPos = transform.screenToCanvas(_longPressScreenPos!);
        ref.read(pasteMenuProvider.notifier).state = PasteMenuState(
          screenPos: _longPressScreenPos!,
          canvasPos: canvasPos,
        );
        setState(() {});
      });
    }

    // Start new selection (outside existing or no selection)
    handleSelectionDown(event);
  }
}
