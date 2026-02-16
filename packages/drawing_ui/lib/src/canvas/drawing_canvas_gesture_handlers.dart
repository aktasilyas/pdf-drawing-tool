import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_core/drawing_core.dart' show BackgroundType;
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas_helpers.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart';
import 'package:drawing_ui/src/models/tool_type.dart';

/// Gesture handling methods for DrawingCanvas.
/// Extracted for better maintainability (file size reduction).
mixin DrawingCanvasGestureHandlers<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, DrawingCanvasHelpers<T> {
  // Required fields from DrawingCanvasState
  core.CanvasMode? get canvasMode; // Canvas mode configuration
  DrawingController get drawingController;
  int get pointerCount;
  set pointerCount(int value);
  Offset? get lastPoint;
  set lastPoint(Offset? value);
  bool get isSelecting;
  set isSelecting(bool value);
  bool get isDrawingShape;
  set isDrawingShape(bool value);
  core.ShapeTool? get activeShapeTool;
  set activeShapeTool(core.ShapeTool? value);
  bool get isStraightLineDrawing;
  set isStraightLineDrawing(bool value);
  core.DrawingPoint? get straightLineStart;
  set straightLineStart(core.DrawingPoint? value);
  core.DrawingPoint? get straightLineEnd;
  set straightLineEnd(core.DrawingPoint? value);
  core.StrokeStyle? get straightLineStyle;
  set straightLineStyle(core.StrokeStyle? value);
  Set<String> get erasedShapeIds;
  Set<String> get erasedTextIds;
  Map<String, List<int>> get pixelEraseHits;
  List<core.Stroke> get pixelEraseOriginalStrokes;
  Offset? get lastFocalPoint;
  set lastFocalPoint(Offset? value);
  double? get lastScale;
  set lastScale(double? value);

  /// Minimum distance between points to avoid excessive point creation.
  static const double minPointDistance = 1.0;

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

    // Handle text move mode regardless of current tool
    if (textToolState.isMoving) {
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint =
          (event.localPosition - transform.offset) / transform.zoom;
      moveTextTo(canvasPoint.dx, canvasPoint.dy);
      return;
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
    final isSelectionTool = ref.read(isSelectionToolProvider);
    if (isSelectionTool) {
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
      // Start new selection (outside existing or no selection)
      handleSelectionDown(event);
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
      }
    }

    // Check if sticker placement mode is active
    final stickerState = ref.read(stickerPlacementProvider);
    if (stickerState.isPlacing) {
      _handleStickerPlacement(event);
      return;
    }

    // Sticker tool selected (no placement) — tap on existing text shows menu
    if (toolType == ToolType.sticker) {
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint =
          (event.localPosition - transform.offset) / transform.zoom;
      final texts = ref.read(activeLayerTextsProvider);
      for (final text in texts.reversed) {
        if (text.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
          ref.read(textToolProvider.notifier).showContextMenu(text);
          return;
        }
      }
      return; // Sticker tool does nothing on empty area without placement
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

    // Check if tap is on an existing text/sticker — show context menu
    {
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint =
          (event.localPosition - transform.offset) / transform.zoom;
      final texts = ref.read(activeLayerTextsProvider);
      for (final text in texts.reversed) {
        if (text.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
          ref.read(textToolProvider.notifier).showContextMenu(text);
          return;
        }
      }
    }

    // Drawing mode
    final point = createDrawingPoint(event);
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
      if (distance < minPointDistance) return;
    }

    final point = createDrawingPoint(event);
    drawingController.addPoint(point);
    lastPoint = event.localPosition;
  }

  /// Handles pointer up - finishes stroke, eraser, selection, or shape.
  void handlePointerUp(PointerUpEvent event) {
    pointerCount = (pointerCount - 1).clamp(0, 10);

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
        // Add stroke via history provider (enables undo/redo)
        ref.read(historyManagerProvider.notifier).addStroke(stroke);
      }
    }
    lastPoint = null;
  }

  /// Handles pointer cancel - cancels the current operation.
  void handlePointerCancel(PointerCancelEvent event) {
    pointerCount = (pointerCount - 1).clamp(0, 10);

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

    // Check if eraser is active
    final isEraser = ref.read(isEraserToolProvider);
    if (isEraser) {
      // Cancel eraser session
      ref.read(eraserToolProvider).endErasing();
    } else {
      drawingController.cancelStroke();
    }
    lastPoint = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SELECTION EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleSelectionDown(PointerDownEvent event) {
    // Clear any existing selection first
    ref.read(selectionProvider.notifier).clearSelection();

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
    final strokes = ref.read(activeLayerStrokesProvider);
    final shapes = ref.read(activeLayerShapesProvider);

    final selection = tool.endSelection(strokes, shapes);

    if (selection != null) {
      ref.read(selectionProvider.notifier).setSelection(selection);
    }

    setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STRAIGHT LINE EVENT HANDLERS (for highlighter)
  // ─────────────────────────────────────────────────────────────────────────

  void handleStraightLineDown(PointerDownEvent event) {
    final point = createDrawingPoint(event);
    final style = getCurrentStyle();

    straightLineStart = point;
    straightLineEnd = point;
    straightLineStyle = style;
    isStraightLineDrawing = true;

    setState(() {});
  }

  void handleStraightLineMove(PointerMoveEvent event) {
    if (!isStraightLineDrawing || straightLineStart == null) return;

    final point = createDrawingPoint(event);
    straightLineEnd = point;

    setState(() {}); // Triggers rebuild for real-time preview
  }

  void handleStraightLineUp(PointerUpEvent event) {
    if (!isStraightLineDrawing) return;

    final start = straightLineStart;
    final end = straightLineEnd;
    final style = straightLineStyle;

    if (start != null && end != null && style != null) {
      // Create stroke with just two points (start and end)
      final stroke = core.Stroke.create(
        points: [start, end],
        style: style,
      );

      // Add stroke via history provider (enables undo/redo)
      ref.read(historyManagerProvider.notifier).addStroke(stroke);
    }

    // Reset state
    straightLineStart = null;
    straightLineEnd = null;
    straightLineStyle = null;
    isStraightLineDrawing = false;

    setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ERASER EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleEraserDown(PointerDownEvent event) {
    final settings = ref.read(eraserSettingsProvider);
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    // Update cursor position
    ref.read(eraserCursorPositionProvider.notifier).state = event.localPosition;

    switch (settings.mode) {
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
        ref.read(pixelEraserPreviewProvider.notifier).state = {};
        handlePixelEraseAt(canvasPoint);
        break;

      case EraserMode.stroke:
        // Existing stroke eraser logic
        final eraserTool = ref.read(eraserToolProvider);
        eraserTool.startErasing();
        erasedShapeIds.clear();
        erasedTextIds.clear();
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
    final settings = ref.read(eraserSettingsProvider);
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    // Update cursor position
    ref.read(eraserCursorPositionProvider.notifier).state = event.localPosition;

    switch (settings.mode) {
      case EraserMode.pixel:
        final pixelTool = ref.read(pixelEraserToolProvider);
        pixelTool.onPointerMove(
          canvasPoint.dx,
          canvasPoint.dy,
          event.pressure.clamp(0.0, 1.0),
        );
        handlePixelEraseAt(canvasPoint);
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

    // Clear cursor position
    ref.read(eraserCursorPositionProvider.notifier).state = null;

    switch (settings.mode) {
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

        // Commit erased texts
        for (final textId in erasedTextIds) {
          final command = core.RemoveTextCommand(
            layerIndex: layerIndex,
            textId: textId,
          );
          ref.read(historyManagerProvider.notifier).execute(command);
        }
        erasedTextIds.clear();
        break;

      case EraserMode.lasso:
        commitLassoErase(layerIndex);
        ref.read(lassoEraserPointsProvider.notifier).state = [];
        break;
    }
  }

  void handlePixelEraseAt(Offset canvasPoint) {
    final strokes = ref.read(activeLayerStrokesProvider);
    final shapes = ref.read(activeLayerShapesProvider);
    final texts = ref.read(activeLayerTextsProvider);
    final settings = ref.read(eraserSettingsProvider);
    final pixelTool = ref.read(pixelEraserToolProvider);

    // Apply eraser filters first
    final filteredStrokes = applyEraserFilters(strokes, settings);

    final hits = pixelTool.findSegmentsAt(
      filteredStrokes,
      canvasPoint.dx,
      canvasPoint.dy,
      settings.size,
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
    for (final shape in shapes) {
      if (!erasedShapeIds.contains(shape.id)) {
        if (shape.containsPoint(
          canvasPoint.dx,
          canvasPoint.dy,
          settings.size / 2, // Use radius as tolerance
        )) {
          erasedShapeIds.add(shape.id);
        }
      }
    }

    // Check texts
    for (final text in texts) {
      if (!erasedTextIds.contains(text.id)) {
        if (text.containsPoint(
          canvasPoint.dx,
          canvasPoint.dy,
          settings.size / 2, // Use radius as tolerance
        )) {
          erasedTextIds.add(text.id);
        }
      }
    }

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

    // Commit texts
    for (final textId in erasedTextIds) {
      final command = core.RemoveTextCommand(
        layerIndex: layerIndex,
        textId: textId,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }

    // Clear tracking
    pixelEraseHits.clear();
    pixelEraseOriginalStrokes.clear();
    erasedShapeIds.clear();
    erasedTextIds.clear();
    ref.read(pixelEraserPreviewProvider.notifier).state = {};
  }

  void commitLassoErase(int layerIndex) {
    final strokes = ref.read(activeLayerStrokesProvider);
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
    final texts = ref.read(activeLayerTextsProvider);
    final eraserTool = ref.read(eraserToolProvider);
    final eraserSettings = ref.read(eraserSettingsProvider);

    // Find strokes to erase
    var toErase = eraserTool.findStrokesToErase(
      strokes,
      canvasPoint.dx,
      canvasPoint.dy,
    );

    // Apply eraser filters
    toErase = applyEraserFilters(toErase, eraserSettings);

    for (final stroke in toErase) {
      if (!eraserTool.isAlreadyErased(stroke.id)) {
        eraserTool.markAsErased(stroke.id);
      }
    }

    // Find shapes to erase (no filters for shapes)
    for (final shape in shapes) {
      if (!erasedShapeIds.contains(shape.id)) {
        if (shape.containsPoint(
          canvasPoint.dx,
          canvasPoint.dy,
          eraserTool.tolerance,
        )) {
          erasedShapeIds.add(shape.id);
        }
      }
    }

    // Find texts to erase (no filters for texts)
    for (final text in texts) {
      if (!erasedTextIds.contains(text.id)) {
        if (text.containsPoint(
          canvasPoint.dx,
          canvasPoint.dy,
          eraserTool.tolerance,
        )) {
          erasedTextIds.add(text.id);
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHAPE EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleShapeDown(PointerDownEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    final coreShapeType = ref.read(activeCoreShapeTypeProvider);
    final isFilled = ref.read(shapeFilledProvider);
    final fillColor = ref.read(shapeFillColorProvider);
    final style = ref.read(shapeStrokeStyleProvider);

    // Create shape tool based on type
    switch (coreShapeType) {
      case core.ShapeType.line:
        activeShapeTool = core.LineTool(style: style);
        break;
      case core.ShapeType.arrow:
        activeShapeTool = core.ArrowTool(style: style);
        break;
      case core.ShapeType.rectangle:
        activeShapeTool = core.RectangleTool(
          style: style,
          filled: isFilled,
          fillColor: fillColor,
        );
        break;
      case core.ShapeType.ellipse:
        activeShapeTool = core.EllipseTool(
          style: style,
          filled: isFilled,
          fillColor: fillColor,
        );
        break;
      case core.ShapeType.triangle:
      case core.ShapeType.diamond:
      case core.ShapeType.star:
      case core.ShapeType.pentagon:
      case core.ShapeType.hexagon:
      case core.ShapeType.plus:
        activeShapeTool = core.GenericShapeTool(
          style: style,
          shapeType: coreShapeType,
          filled: isFilled,
          fillColor: fillColor,
        );
        break;
    }

    activeShapeTool!.startShape(core.DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: 1.0,
    ));

    isDrawingShape = true;
    setState(() {});
  }

  void handleShapeMove(PointerMoveEvent event) {
    final tool = activeShapeTool;
    if (tool == null) return;

    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    tool.updateShape(core.DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: 1.0,
    ));

    setState(() {});
  }

  void handleShapeUp(PointerUpEvent event) {
    final tool = activeShapeTool;
    if (tool == null) return;

    isDrawingShape = false;

    final shape = tool.endShape();

    if (shape != null) {
      final document = ref.read(documentProvider);
      final command = core.AddShapeCommand(
        layerIndex: document.activeLayerIndex,
        shape: shape,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }

    activeShapeTool = null;
    setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleTextDown(PointerDownEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint =
        (event.localPosition - transform.offset) / transform.zoom;

    // Check if there's already active text editing
    final textToolState = ref.read(textToolProvider);

    // Handle move mode - move text to tapped location
    if (textToolState.isMoving) {
      moveTextTo(canvasPoint.dx, canvasPoint.dy);
      return;
    }

    if (textToolState.isEditing) {
      // Check if tapped on the same text element - if not, finish current and STOP
      final activeText = textToolState.activeText;
      if (activeText != null) {
        // Check if tapped on current active text
        if (activeText.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
          // Same text clicked - do nothing, let TextField handle it
          return;
        }
        // Tapped somewhere else - finish current editing and STOP
        // User needs to tap again to create new text (this closes keyboard)
        finishTextEditing();
        return; // IMPORTANT: Don't create new text on same tap
      }
    }

    // If menu is showing, close it first
    if (textToolState.showMenu) {
      ref.read(textToolProvider.notifier).hideContextMenu();
      return;
    }

    // If style popup is showing, close it first
    if (textToolState.showStylePopup) {
      ref.read(textToolProvider.notifier).hideStylePopup();
      return;
    }

    // Check if tapped on existing text - show context menu
    final texts = ref.read(activeLayerTextsProvider);

    for (final text in texts.reversed) {
      if (text.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
        // Show context menu for existing text
        ref.read(textToolProvider.notifier).showContextMenu(text);
        return;
      }
    }

    // Create new text at tap location using text settings
    final textSettings = ref.read(textSettingsProvider);
    ref.read(textToolProvider.notifier).startNewText(
          canvasPoint.dx,
          canvasPoint.dy,
          fontSize: textSettings.fontSize,
          color: textSettings.color,
          isBold: textSettings.isBold,
          isItalic: textSettings.isItalic,
          isUnderline: textSettings.isUnderline,
        );
  }

  void finishTextEditing() {
    final textToolState = ref.read(textToolProvider);

    // IMPORTANT: Get the current text state BEFORE calling finishEditing
    // because finishEditing clears the state
    final currentText = textToolState.activeText;

    if (currentText == null || currentText.text.trim().isEmpty) {
      ref.read(textToolProvider.notifier).cancelEditing();
      return;
    }

    // Now finish editing (this clears the state)
    ref.read(textToolProvider.notifier).finishEditing();

    final document = ref.read(documentProvider);

    if (textToolState.isNewText) {
      // Add new text
      final command = core.AddTextCommand(
        layerIndex: document.activeLayerIndex,
        textElement: currentText,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    } else {
      // Update existing text
      final command = core.UpdateTextCommand(
        layerIndex: document.activeLayerIndex,
        newText: currentText,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }
  }

  void cancelTextEditing() {
    ref.read(textToolProvider.notifier).cancelEditing();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT CONTEXT MENU HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleTextEdit() {
    final textToolState = ref.read(textToolProvider);
    final menuText = textToolState.menuText;
    if (menuText != null) {
      ref
          .read(textToolProvider.notifier)
          .editExistingText(menuText);
    }
  }

  void handleTextDelete() {
    final textToolState = ref.read(textToolProvider);
    final menuText = textToolState.menuText;
    if (menuText != null) {
      final document = ref.read(documentProvider);
      final command = core.RemoveTextCommand(
        layerIndex: document.activeLayerIndex,
        textId: menuText.id,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
      ref.read(textToolProvider.notifier).hideContextMenu();
    }
  }

  void handleTextStyle() {
    final textToolState = ref.read(textToolProvider);
    final menuText = textToolState.menuText;
    if (menuText != null) {
      ref
          .read(textToolProvider.notifier)
          .showStylePopup(menuText);
    }
  }

  void handleTextStyleChanged(core.TextElement updatedText) {
    final document = ref.read(documentProvider);
    final command = core.UpdateTextCommand(
      layerIndex: document.activeLayerIndex,
      newText: updatedText,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
  }

  void handleTextDuplicate() {
    final textToolState = ref.read(textToolProvider);
    final menuText = textToolState.menuText;
    if (menuText != null) {
      final originalText = menuText;
      // Create duplicate with visible offset (40px diagonal)
      final duplicateText = core.TextElement.create(
        text: originalText.text,
        x: originalText.x + 40, // Offset by 40 pixels
        y: originalText.y + 40,
        fontSize: originalText.fontSize,
        color: originalText.color,
        fontFamily: originalText.fontFamily,
        isBold: originalText.isBold,
        isItalic: originalText.isItalic,
        isUnderline: originalText.isUnderline,
        alignment: originalText.alignment,
      );

      final document = ref.read(documentProvider);
      final command = core.AddTextCommand(
        layerIndex: document.activeLayerIndex,
        textElement: duplicateText,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
      ref.read(textToolProvider.notifier).hideContextMenu();
    }
  }

  void handleTextMove() {
    final textToolState = ref.read(textToolProvider);
    final menuText = textToolState.menuText;
    if (menuText != null) {
      ref.read(textToolProvider.notifier).startMoving(menuText);
    }
  }

  void moveTextTo(double x, double y) {
    final textToolState = ref.read(textToolProvider);
    final movingText = textToolState.movingText;
    if (movingText != null) {
      final movedText = movingText.copyWith(x: x, y: y);
      final document = ref.read(documentProvider);
      final command = core.UpdateTextCommand(
        layerIndex: document.activeLayerIndex,
        newText: movedText,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
      ref.read(textToolProvider.notifier).cancelMoving();
    }
  }

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

    // If text move mode is active, move the element
    if (textToolState.isMoving) {
      moveTextTo(canvasPoint.dx, canvasPoint.dy);
      return;
    }

    // Check if tap is on an existing text/sticker — show context menu
    final texts = ref.read(activeLayerTextsProvider);
    for (final text in texts.reversed) {
      if (text.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
        ref.read(textToolProvider.notifier).showContextMenu(text);
        return;
      }
    }

    // Empty area — place new sticker
    final textElement = core.TextElement.create(
      text: emoji,
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      fontSize: 48,
    );

    final document = ref.read(documentProvider);
    final command = core.AddTextCommand(
      layerIndex: document.activeLayerIndex,
      textElement: textElement,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCALE GESTURE HANDLERS (Two Finger Zoom/Pan)
  // ─────────────────────────────────────────────────────────────────────────

  void handleScaleStart(ScaleStartDetails details) {
    // Only handle zoom/pan with 2+ fingers
    if (details.pointerCount < 2) return;

    // Show zoom indicator
    ref.read(isZoomingProvider.notifier).state = true;

    // Cancel any ongoing operations when zoom/pan starts
    if (drawingController.isDrawing) {
      drawingController.cancelStroke();
    }
    if (isSelecting) {
      ref.read(activeSelectionToolProvider).cancelSelection();
      isSelecting = false;
    }
    if (isDrawingShape) {
      activeShapeTool?.cancelShape();
      activeShapeTool = null;
      isDrawingShape = false;
    }

    // Finish text editing if active (save the text)
    final textToolState = ref.read(textToolProvider);
    if (textToolState.isEditing) {
      finishTextEditing();
    }

    lastFocalPoint = details.focalPoint;
    lastScale = 1.0;
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    // Only handle zoom/pan with 2+ fingers
    if (details.pointerCount < 2) return;

    final transformNotifier = ref.read(canvasTransformProvider.notifier);
    final mode = canvasMode ?? const core.CanvasMode(isInfinite: true);
    final currentPage = ref.read(currentPageProvider);

    // Get viewport size from context
    final renderBox = context.findRenderObject() as RenderBox?;
    final viewportSize = renderBox?.size ?? const Size(800, 600);

    // Apply zoom (pinch gesture)
    if (lastScale != null && details.scale != 1.0) {
      final scaleDelta = details.scale / lastScale!;
      if ((scaleDelta - 1.0).abs() > 0.001) {
        if (mode.isInfinite) {
          // Unlimited zoom for whiteboard - use mode's zoom limits
          transformNotifier.applyZoomDelta(
            scaleDelta, 
            details.focalPoint,
            minZoom: mode.minZoom,
            maxZoom: mode.maxZoom,
          );
        } else {
          // Clamped zoom for notebook/limited modes
          transformNotifier.applyZoomDeltaClamped(
            scaleDelta,
            details.focalPoint,
            minZoom: mode.minZoom,
            maxZoom: mode.maxZoom,
            viewportSize: viewportSize,
            pageSize: Size(currentPage.size.width, currentPage.size.height),
            unlimitedPan: mode.unlimitedPan,
          );
        }
      }
    }

    // Apply pan (two finger drag)
    if (lastFocalPoint != null) {
      final panDelta = details.focalPoint - lastFocalPoint!;
      if (panDelta.distance > 0.5) {
        if (mode.isInfinite || mode.unlimitedPan) {
          // Unlimited pan for whiteboard
          transformNotifier.applyPanDelta(panDelta);
        } else {
          // Clamped pan for notebook/limited modes
          transformNotifier.applyPanDeltaClamped(
            panDelta,
            viewportSize: viewportSize,
            pageSize: Size(currentPage.size.width, currentPage.size.height),
            unlimitedPan: mode.unlimitedPan,
          );
        }
      }
    }

    lastFocalPoint = details.focalPoint;
    lastScale = details.scale;
  }

  void handleScaleEnd(ScaleEndDetails details) {
    // Hide zoom indicator
    ref.read(isZoomingProvider.notifier).state = false;

    // Zoom değişimini provider'a bildir (for adaptive PDF quality)
    final currentTransform = ref.read(canvasTransformProvider);
    final currentZoom = currentTransform.zoom;
    final page = ref.read(currentPageProvider);

    if (page.background.type == BackgroundType.pdf &&
        page.background.pdfFilePath != null &&
        page.background.pdfPageIndex != null) {
      final cacheKey = '${page.background.pdfFilePath}|${page.background.pdfPageIndex}';
      ref.read(zoomBasedRenderProvider.notifier).onZoomChanged(currentZoom, cacheKey);
    }

    // Snap back for limited canvas mode
    final mode = canvasMode ?? const core.CanvasMode(isInfinite: true);
    if (!mode.isInfinite && !mode.unlimitedPan) {
      final currentPage = ref.read(currentPageProvider);
      final renderBox = context.findRenderObject() as RenderBox?;
      final viewportSize = renderBox?.size ?? const Size(800, 600);

      ref.read(canvasTransformProvider.notifier).snapBackForPage(
            viewportSize: viewportSize,
            pageSize: Size(currentPage.size.width, currentPage.size.height),
          );
    }

    lastFocalPoint = null;
    lastScale = null;
  }
}
