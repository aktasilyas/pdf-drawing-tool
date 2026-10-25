part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// Reads providers and State into a [_CanvasFrame].
mixin _CanvasFrameReader
    on DrawingCanvasGestureHandlers<DrawingCanvas>, _CanvasFields {
  _CanvasFrame _readFrame() {
    // Watch providers
    final allLayers = ref.watch(allLayersProvider);
    final activeLayerIndex = ref.watch(activeLayerIndexProvider);
    final activeLayerValid =
        activeLayerIndex >= 0 && activeLayerIndex < allLayers.length;
    final activeLayerVisible =
        activeLayerValid && allLayers[activeLayerIndex].isVisible;
    final activeLayerOpacity =
        activeLayerValid ? allLayers[activeLayerIndex].opacity : 1.0;
    final strokes = ref.watch(activeLayerStrokesProvider);
    final shapes = ref.watch(activeLayerShapesProvider);
    final texts = ref.watch(activeLayerTextsProvider);
    final isDrawingTool = ref.watch(isDrawingToolProvider);
    final isSelectionTool = ref.watch(isSelectionToolProvider);
    final isShapeTool = ref.watch(isShapeToolProvider);
    final currentTool = ref.watch(currentToolProvider);
    final transform = ref.watch(canvasTransformProvider);
    final selection = ref.watch(selectionProvider);
    final selectionUi = ref.watch(selectionUiProvider);
    final textToolState = ref.watch(textToolProvider);

    // Canvas mode configuration
    final canvasMode =
        widget.canvasMode ?? const core.CanvasMode(isInfinite: true);

    // Current page (LIMITED mod için)
    final currentPage = ref.watch(currentPageProvider);
    final colorScheme = ref.watch(canvasColorSchemeProvider);
    // Eraser cursor state
    final eraserCursorPosition = ref.watch(eraserCursorPositionProvider);
    final lassoEraserPoints = ref.watch(lassoEraserPointsProvider);
    final isEraserTool = ref.watch(isEraserToolProvider);
    final pixelEraserPreview = ref.watch(pixelEraserPreviewProvider);
    final strokeEraserPreview = ref.watch(strokeEraserPreviewProvider);

    // Selection tool preview path
    List<core.DrawingPoint>? selectionPreviewPath;
    if (isSelectionTool && _isSelecting) {
      selectionPreviewPath = ref.read(activeSelectionToolProvider).currentPath;
    }

    // Watch images and elementOrder for active layer
    final images = ref.watch(activeLayerImagesProvider);
    final elementOrder = activeLayerValid
        ? allLayers[activeLayerIndex].elementOrder
        : const <String>[];

    // Compute excluded IDs + selected elements for live transform
    final hasLiveTransform = selectionUi.hasTransform;
    Set<String> excludedStrokeIds = const {};
    Set<String> excludedShapeIds = const {};
    Set<String> excludedImageIds = const {};
    Set<String> excludedTextIds = const {};
    List<core.Stroke> selectedStrokes = const [];
    List<core.Shape> selectedShapes = const [];
    List<core.ImageElement> selectedImages = const [];
    List<core.TextElement> selectedTexts = const [];

    if (selection != null && hasLiveTransform) {
      excludedStrokeIds = selection.selectedStrokeIds.toSet();
      excludedShapeIds = selection.selectedShapeIds.toSet();
      excludedImageIds = selection.selectedImageIds.toSet();
      excludedTextIds = selection.selectedTextIds.toSet();

      selectedStrokes =
          strokes.where((s) => excludedStrokeIds.contains(s.id)).toList();
      selectedShapes =
          shapes.where((s) => excludedShapeIds.contains(s.id)).toList();
      selectedImages =
          images.where((i) => excludedImageIds.contains(i.id)).toList();
      selectedTexts =
          texts.where((t) => excludedTextIds.contains(t.id)).toList();
    }

    // Shape preview
    core.Shape? previewShape;
    if (_isDrawingShape && _activeShapeTool != null) {
      previewShape = _activeShapeTool!.previewShape;
    }

    // Straight line preview (for highlighter)
    List<core.DrawingPoint>? straightLinePreviewPoints;
    core.StrokeStyle? straightLinePreviewStyle;
    final start = _straightLineStart;
    final end = _straightLineEnd;
    if (_isStraightLineDrawing && start != null && end != null) {
      straightLinePreviewPoints = [start, end];
      straightLinePreviewStyle = _straightLineStyle;
    }

    // Watch sticky notes for active layer
    final stickyNotes = ref.watch(activeLayerStickyNotesProvider);

    // Enable pointer events for drawing tools, selection tool, shape tool, text tool,
    // sticker placement mode, image tool, and image placement mode.
    // In read-only mode, all drawing pointer events are disabled (pan/zoom still works)
    final isTextTool = currentTool == ToolType.text;
    final isStickerTool = currentTool == ToolType.sticker;
    final isImageTool = currentTool == ToolType.image;
    final isStickerPlacing = ref.watch(stickerPlacementProvider).isPlacing;
    final isImagePlacing = ref.watch(imagePlacementProvider).isPlacing;
    final isLaserTool = currentTool == ToolType.laserPointer;
    final isStickyNoteTool = currentTool == ToolType.stickyNote;
    final enablePointerEvents = !widget.isReadOnly &&
        (isDrawingTool ||
            isSelectionTool ||
            isShapeTool ||
            isTextTool ||
            isStickerTool ||
            isStickerPlacing ||
            isImageTool ||
            isImagePlacing ||
            isLaserTool ||
            isStickyNoteTool);

    return _CanvasFrame(
      allLayers: allLayers,
      activeLayerIndex: activeLayerIndex,
      activeLayerVisible: activeLayerVisible,
      activeLayerOpacity: activeLayerOpacity,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: images,
      elementOrder: elementOrder,
      transform: transform,
      selection: selection,
      selectionUi: selectionUi,
      textToolState: textToolState,
      canvasMode: canvasMode,
      currentPage: currentPage,
      colorScheme: colorScheme,
      eraserCursorPosition: eraserCursorPosition,
      lassoEraserPoints: lassoEraserPoints,
      isEraserTool: isEraserTool,
      pixelEraserPreview: pixelEraserPreview,
      strokeEraserPreview: strokeEraserPreview,
      selectionPreviewPath: selectionPreviewPath,
      hasLiveTransform: hasLiveTransform,
      excludedStrokeIds: excludedStrokeIds,
      excludedShapeIds: excludedShapeIds,
      excludedImageIds: excludedImageIds,
      excludedTextIds: excludedTextIds,
      selectedStrokes: selectedStrokes,
      selectedShapes: selectedShapes,
      selectedImages: selectedImages,
      selectedTexts: selectedTexts,
      previewShape: previewShape,
      straightLinePreviewPoints: straightLinePreviewPoints,
      straightLinePreviewStyle: straightLinePreviewStyle,
      stickyNotes: stickyNotes,
      isTextTool: isTextTool,
      isStickyNoteTool: isStickyNoteTool,
      enablePointerEvents: enablePointerEvents,
    );
  }
}
