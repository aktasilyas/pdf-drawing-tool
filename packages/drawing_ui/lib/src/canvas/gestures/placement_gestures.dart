part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Sticker and image placement, and image-tool taps.
mixin _PlacementGestures<T extends ConsumerStatefulWidget>
    on
        ConsumerState<T>,
        DrawingCanvasHelpers<T>,
        _GestureState<T>,
        _TextGestures<T> {
  // ─────────────────────────────────────────────────────────────────────────
  // STICKER PLACEMENT
  // ─────────────────────────────────────────────────────────────────────────

  void _handleStickerPlacement(PointerDownEvent event) {
    final stickerState = ref.read(stickerPlacementProvider);
    final emoji = stickerState.selectedEmoji;
    if (emoji == null) return;

    final textToolState = ref.read(textToolProvider);

    // If context menu is showing, close it
    if (textToolState.showMenu) {
      ref.read(textToolProvider.notifier).hideContextMenu();
      return;
    }

    // If style popup is showing, close it
    if (textToolState.showStylePopup) {
      ref.read(textToolProvider.notifier).hideStylePopup();
      return;
    }

    final transform = ref.read(canvasTransformProvider);
    final canvasPoint =
        (event.localPosition - transform.offset) / transform.zoom;

    // Check if tap is on an existing text/sticker — select it
    final texts = ref.read(activeLayerTextsProvider);
    for (final text in texts.reversed) {
      if (text.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
        _selectText(text);
        return;
      }
    }

    // Empty area — place new sticker
    // Measure actual emoji size for accurate selection bounds
    const stickerFontSize = 48.0;
    final paragraph = (ui.ParagraphBuilder(ui.ParagraphStyle())
          ..pushStyle(ui.TextStyle(fontSize: stickerFontSize))
          ..addText(emoji))
        .build();
    paragraph.layout(const ui.ParagraphConstraints(width: 1000.0));
    final measuredW = paragraph.maxIntrinsicWidth;
    final measuredH = paragraph.height;

    final textElement = core.TextElement.create(
      text: emoji,
      x: canvasPoint.dx - measuredW / 2,
      y: canvasPoint.dy - measuredH / 2,
      fontSize: stickerFontSize,
      width: measuredW,
      height: measuredH,
    );

    final document = ref.read(documentProvider);
    final command = core.AddTextCommand(
      layerIndex: document.activeLayerIndex,
      textElement: textElement,
    );
    ref.read(historyManagerProvider.notifier).execute(command);

    // Exit sticker placement and auto-select into selection system
    ref.read(stickerPlacementProvider.notifier).placed();
    _selectText(textElement);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE PLACEMENT
  // ─────────────────────────────────────────────────────────────────────────

  void _handleImagePlacement(PointerDownEvent event) {
    final imageState = ref.read(imagePlacementProvider);
    final imagePath = imageState.selectedImagePath;
    if (imagePath == null) return;

    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    // Default image size on canvas
    const defaultWidth = 200.0;
    const defaultHeight = 200.0;

    double imgX = canvasPoint.dx - defaultWidth / 2;
    double imgY = canvasPoint.dy - defaultHeight / 2;

    // Clamp position to page bounds (skip in infinite mode)
    if (!ref.read(isInfiniteCanvasProvider)) {
      final page = ref.read(currentPageProvider);
      final maxX = (page.size.width - defaultWidth).clamp(0.0, page.size.width);
      final maxY =
          (page.size.height - defaultHeight).clamp(0.0, page.size.height);
      imgX = imgX.clamp(0.0, maxX);
      imgY = imgY.clamp(0.0, maxY);
    }

    final imageElement = core.ImageElement.create(
      filePath: imagePath,
      x: imgX,
      y: imgY,
      width: defaultWidth,
      height: defaultHeight,
    );

    final document = ref.read(documentProvider);
    final command = core.AddImageCommand(
      layerIndex: document.activeLayerIndex,
      imageElement: imageElement,
    );
    ref.read(historyManagerProvider.notifier).execute(command);

    // Exit placement mode
    ref.read(imagePlacementProvider.notifier).placed();

    // Auto-select image into the main selection system
    final selection = core.Selection.create(
      type: core.SelectionType.rectangle,
      selectedStrokeIds: const [],
      selectedShapeIds: const [],
      selectedImageIds: [imageElement.id],
      bounds: imageElement.bounds,
    );
    ref.read(selectionProvider.notifier).setSelection(selection);
    ref.read(selectionUiProvider.notifier).showContextMenu();

    // Switch to selection tool so handles are interactive
    ref.read(currentToolProvider.notifier).selectTool(ToolType.selection);
  }

  /// Image tool selected (no placement) — tap on existing image selects it
  /// via the main selection system (SelectionHandles + SelectionToolbar).
  void _handleImageToolDown(PointerDownEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint =
        (event.localPosition - transform.offset) / transform.zoom;

    final images = ref.read(activeLayerImagesProvider);
    for (final image in images.reversed) {
      if (image.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
        final selection = core.Selection.create(
          type: core.SelectionType.rectangle,
          selectedStrokeIds: const [],
          selectedShapeIds: const [],
          selectedImageIds: [image.id],
          bounds: image.bounds,
        );
        ref.read(selectionProvider.notifier).setSelection(selection);
        ref.read(selectionUiProvider.notifier).showContextMenu();
        ref.read(currentToolProvider.notifier).selectTool(ToolType.selection);
        return;
      }
    }
  }
}
