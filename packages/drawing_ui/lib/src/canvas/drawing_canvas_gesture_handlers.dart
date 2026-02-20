import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_core/drawing_core.dart' show BackgroundType;
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/canvas/laser_controller.dart';
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
  Set<String> get erasedImageIds;
  Map<String, List<int>> get pixelEraseHits;
  List<core.Stroke> get pixelEraseOriginalStrokes;
  /// Note ID -> set of internal stroke IDs erased in current gesture.
  Map<String, Set<String>> get erasedNoteStrokeIds;
  /// Note ID -> set of internal shape IDs erased in current gesture.
  Map<String, Set<String>> get erasedNoteShapeIds;
  /// Note ID -> (stroke ID -> segment indices) for pixel erasure inside notes.
  Map<String, Map<String, List<int>>> get pixelEraseNoteHits;
  /// Note ID -> original strokes for pixel erasure inside notes.
  Map<String, List<core.Stroke>> get pixelEraseNoteOriginalStrokes;
  Offset? get lastFocalPoint;
  set lastFocalPoint(Offset? value);
  double? get lastScale;
  set lastScale(double? value);
  LaserController get laserController;
  bool get isLaserDrawing;
  set isLaserDrawing(bool value);
  core.StickyNote? get drawingInsideNote;
  set drawingInsideNote(core.StickyNote? value);
  Offset? get scaleStartFocalPoint;
  set scaleStartFocalPoint(Offset? value);
  ValueChanged<int>? get onPageSwipe;
  bool get scaleGestureIsZoom;
  set scaleGestureIsZoom(bool value);

  /// Minimum distance between points to avoid excessive point creation.
  static const double minPointDistance = 1.0;

  /// Detects if the pointer starts inside a (non-minimized) sticky note
  /// and stores it for point clamping during the stroke.
  void _detectDrawingInsideNote(PointerEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final cp = transform.screenToCanvas(event.localPosition);
    final notes = ref.read(activeLayerStickyNotesProvider);
    drawingInsideNote = null;
    for (final note in notes.reversed) {
      if (!note.minimized &&
          note.containsPoint(cp.dx, cp.dy, 0)) {
        drawingInsideNote = note;
        return;
      }
    }
  }

  /// Clamps a drawing point to the sticky note bounds when drawing inside one.
  core.DrawingPoint _clampToNote(core.DrawingPoint point) {
    final note = drawingInsideNote;
    if (note == null) return point;
    return core.DrawingPoint(
      x: point.x.clamp(note.x, note.x + note.width),
      y: point.y.clamp(note.y, note.y + note.height),
      pressure: point.pressure,
      tilt: point.tilt,
      timestamp: point.timestamp,
    );
  }

  /// Converts a stroke to relative coordinates and adds it to the sticky note.
  void _addStrokeToStickyNote(core.Stroke stroke, core.StickyNote note) {
    final relPoints = stroke.points
        .map((p) => core.DrawingPoint(
              x: p.x - note.x,
              y: p.y - note.y,
              pressure: p.pressure,
              tilt: p.tilt,
              timestamp: p.timestamp,
            ))
        .toList();
    final relStroke = stroke.copyWith(points: relPoints);

    // Get the current note from the document (may have changed)
    final document = ref.read(documentProvider);
    final layer = document.layers[document.activeLayerIndex];
    final currentNote = layer.getStickyNoteById(note.id);
    if (currentNote == null) return;

    final updated =
        currentNote.copyWith(strokes: [...currentNote.strokes, relStroke]);
    final command = core.UpdateStickyNoteCommand(
      layerIndex: document.activeLayerIndex,
      newNote: updated,
    );
    ref.read(historyManagerProvider.notifier).execute(command);

    // Sync the selected note so overrideNote renders the updated version
    final placement = ref.read(stickyNotePlacementProvider);
    if (placement.selectedNote?.id == note.id) {
      ref
          .read(stickyNotePlacementProvider.notifier)
          .updateSelectedNote(updated);
    }
  }

  /// Converts a shape to relative coordinates and adds it to the sticky note.
  void _addShapeToStickyNote(core.Shape shape, core.StickyNote note) {
    final relShape = shape.copyWith(
      startPoint: core.DrawingPoint(
        x: shape.startPoint.x - note.x,
        y: shape.startPoint.y - note.y,
        pressure: shape.startPoint.pressure,
        tilt: shape.startPoint.tilt,
        timestamp: shape.startPoint.timestamp,
      ),
      endPoint: core.DrawingPoint(
        x: shape.endPoint.x - note.x,
        y: shape.endPoint.y - note.y,
        pressure: shape.endPoint.pressure,
        tilt: shape.endPoint.tilt,
        timestamp: shape.endPoint.timestamp,
      ),
    );

    final document = ref.read(documentProvider);
    final layer = document.layers[document.activeLayerIndex];
    final currentNote = layer.getStickyNoteById(note.id);
    if (currentNote == null) return;

    final updated =
        currentNote.copyWith(shapes: [...currentNote.shapes, relShape]);
    final command = core.UpdateStickyNoteCommand(
      layerIndex: document.activeLayerIndex,
      newNote: updated,
    );
    ref.read(historyManagerProvider.notifier).execute(command);

    // Sync the selected note so overrideNote renders the updated version
    final placement = ref.read(stickyNotePlacementProvider);
    if (placement.selectedNote?.id == note.id) {
      ref
          .read(stickyNotePlacementProvider.notifier)
          .updateSelectedNote(updated);
    }
  }

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

    // Handle image move mode regardless of current tool
    final imgState = ref.read(imagePlacementProvider);
    if (imgState.isMoving) {
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint =
          (event.localPosition - transform.offset) / transform.zoom;
      _moveImageTo(canvasPoint.dx, canvasPoint.dy);
      return;
    }

    // Close selection context menu if showing
    final selUi = ref.read(selectionUiProvider);
    if (selUi.showMenu) {
      ref.read(selectionUiProvider.notifier).hideContextMenu();
      return;
    }

    // Close image context menu if showing (keep selection for resize handles)
    if (imgState.showMenu) {
      ref.read(imagePlacementProvider.notifier).hideContextMenu();
      return;
    }

    // Close sticky note context menu if showing
    final stickyNoteState = ref.read(stickyNotePlacementProvider);
    if (stickyNoteState.showMenu) {
      ref.read(stickyNotePlacementProvider.notifier).hideContextMenu();
      return;
    }

    // If an image is selected (resize handles visible) and we're not on image tool,
    // deselect the image
    if (imgState.selectedImage != null && toolType != ToolType.image) {
      ref.read(imagePlacementProvider.notifier).deselectImage();
    }

    // If a sticky note is selected and we're not on stickyNote tool,
    // minimize and deselect if tapping OUTSIDE the note (allow drawing inside).
    if (stickyNoteState.selectedNote != null &&
        toolType != ToolType.stickyNote) {
      final transform = ref.read(canvasTransformProvider);
      final cp = transform.screenToCanvas(event.localPosition);
      if (!stickyNoteState.selectedNote!
          .containsPoint(cp.dx, cp.dy, 0)) {
        _minimizeAndDeselectNote(stickyNoteState.selectedNote!);
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
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint =
          (event.localPosition - transform.offset) / transform.zoom;
      final currentNoteState = ref.read(stickyNotePlacementProvider);

      // If a selected (non-minimized) note is showing resize handles,
      // check if tap is inside the note → let handles handle it.
      // If outside → minimize and deselect, then check other notes.
      if (currentNoteState.selectedNote != null &&
          !currentNoteState.showMenu &&
          !currentNoteState.selectedNote!.minimized) {
        if (currentNoteState.selectedNote!
            .containsPoint(canvasPoint.dx, canvasPoint.dy, 0)) {
          return; // Inside note → resize handles handle it
        }
        // Outside note → minimize and deselect
        _minimizeAndDeselectNote(currentNoteState.selectedNote!);
      }

      final notes = ref.read(activeLayerStickyNotesProvider);
      for (final note in notes.reversed) {
        if (note.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
          if (note.minimized) {
            // Maximize the note
            final maximized = note.copyWith(minimized: false);
            final document = ref.read(documentProvider);
            final command = core.UpdateStickyNoteCommand(
              layerIndex: document.activeLayerIndex,
              newNote: maximized,
            );
            ref.read(historyManagerProvider.notifier).execute(command);
            ref.read(stickyNotePlacementProvider.notifier).selectNote(maximized);
            return;
          }
          ref.read(stickyNotePlacementProvider.notifier).selectNote(note);
          return;
        }
      }
      // Tap on empty area → deselect
      ref.read(stickyNotePlacementProvider.notifier).deselectNote();
      return;
    }

    // Image tool selected (no placement) — tap on existing image selects it
    if (toolType == ToolType.image) {
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint =
          (event.localPosition - transform.offset) / transform.zoom;
      final currentImgState = ref.read(imagePlacementProvider);

      // If a selected image is showing resize handles, let the handles widget
      // handle pan/tap events (it runs as GestureDetector inside Transform).
      if (currentImgState.selectedImage != null && !currentImgState.showMenu) {
        return;
      }

      final images = ref.read(activeLayerImagesProvider);
      for (final image in images.reversed) {
        if (image.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
          ref.read(imagePlacementProvider.notifier).selectImage(image);
          return;
        }
      }
      // Tap on empty area → deselect
      ref.read(imagePlacementProvider.notifier).deselectImage();
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

    // Drawing mode — detect sticky note constraint
    _detectDrawingInsideNote(event);
    final point = _clampToNote(createDrawingPoint(event));
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
      if (distance < minPointDistance) return;
    }

    final point = _clampToNote(createDrawingPoint(event));
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

    // Laser pointer mode
    if (isLaserDrawing) {
      laserController.cancelStroke();
      isLaserDrawing = false;
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
    drawingInsideNote = null;
    lastPoint = null;
  }

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
    _detectDrawingInsideNote(event);
    final point = _clampToNote(createDrawingPoint(event));
    final style = getCurrentStyle();

    straightLineStart = point;
    straightLineEnd = point;
    straightLineStyle = style;
    isStraightLineDrawing = true;

    setState(() {});
  }

  void handleStraightLineMove(PointerMoveEvent event) {
    if (!isStraightLineDrawing || straightLineStart == null) return;

    final point = _clampToNote(createDrawingPoint(event));
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

      if (drawingInsideNote != null) {
        _addStrokeToStickyNote(stroke, drawingInsideNote!);
      } else {
        ref.read(historyManagerProvider.notifier).addStroke(stroke);
      }
    }

    // Reset state
    straightLineStart = null;
    straightLineEnd = null;
    straightLineStyle = null;
    isStraightLineDrawing = false;
    drawingInsideNote = null;

    setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LASER POINTER EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleLaserDown(PointerDownEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);
    final settings = ref.read(laserSettingsProvider);

    laserController.startStroke(
      canvasPoint,
      color: settings.color,
      thickness: settings.thickness,
      mode: settings.mode,
      lineStyle: settings.lineStyle,
    );
    isLaserDrawing = true;
    lastPoint = event.localPosition;
  }

  void handleLaserMove(PointerMoveEvent event) {
    // Distance filter to avoid excessive points
    final lastPointValue = lastPoint;
    if (lastPointValue != null) {
      final distance = (event.localPosition - lastPointValue).distance;
      if (distance < minPointDistance) return;
    }

    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);
    laserController.addPoint(canvasPoint);
    lastPoint = event.localPosition;
  }

  void handleLaserUp(PointerUpEvent event) {
    final settings = ref.read(laserSettingsProvider);
    final fadeDuration = Duration(
      milliseconds: (settings.duration * 1000).round(),
    );
    laserController.endStroke(fadeDuration);
    isLaserDrawing = false;
    lastPoint = null;
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
        erasedNoteStrokeIds.clear();
        erasedNoteShapeIds.clear();
        pixelEraseNoteHits.clear();
        pixelEraseNoteOriginalStrokes.clear();
        ref.read(pixelEraserPreviewProvider.notifier).state = {};
        handlePixelEraseAt(canvasPoint);
        break;

      case EraserMode.stroke:
        // Existing stroke eraser logic
        final eraserTool = ref.read(eraserToolProvider);
        eraserTool.startErasing();
        erasedShapeIds.clear();
        erasedTextIds.clear();
        erasedImageIds.clear();
        erasedNoteStrokeIds.clear();
        erasedNoteShapeIds.clear();
        pixelEraseNoteHits.clear();
        pixelEraseNoteOriginalStrokes.clear();
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

        // Commit erased images
        for (final imageId in erasedImageIds) {
          final command = core.RemoveImageCommand(
            layerIndex: layerIndex,
            imageId: imageId,
          );
          ref.read(historyManagerProvider.notifier).execute(command);
        }
        erasedImageIds.clear();

        // Commit erased note internal strokes/shapes
        _commitNoteErasures(layerIndex);
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
    final images = ref.read(activeLayerImagesProvider);
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

    // Check images
    for (final image in images) {
      if (!erasedImageIds.contains(image.id)) {
        if (image.containsPoint(
          canvasPoint.dx,
          canvasPoint.dy,
          settings.size / 2,
        )) {
          erasedImageIds.add(image.id);
        }
      }
    }

    // Erase inside sticky notes (pixel mode: segment-level tracking)
    _eraseInsideStickyNotes(canvasPoint, settings.size / 2, isPixelMode: true);

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

    // Commit images
    for (final imageId in erasedImageIds) {
      final command = core.RemoveImageCommand(
        layerIndex: layerIndex,
        imageId: imageId,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }

    // Commit note internal erasures
    _commitNoteErasures(layerIndex);

    // Clear tracking
    pixelEraseHits.clear();
    pixelEraseOriginalStrokes.clear();
    erasedShapeIds.clear();
    erasedTextIds.clear();
    erasedImageIds.clear();
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
    final images = ref.read(activeLayerImagesProvider);
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

    // Find images to erase
    for (final image in images) {
      if (!erasedImageIds.contains(image.id)) {
        if (image.containsPoint(
          canvasPoint.dx,
          canvasPoint.dy,
          eraserTool.tolerance,
        )) {
          erasedImageIds.add(image.id);
        }
      }
    }

    // Erase inside sticky notes (relative coordinate check)
    _eraseInsideStickyNotes(canvasPoint, eraserTool.tolerance);
  }

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
        final noteShapeIds =
            erasedNoteShapeIds.putIfAbsent(note.id, () => {});
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
      final noteHits =
          pixelEraseNoteHits.putIfAbsent(note.id, () => {});
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
      final noteStrokeIds =
          erasedNoteStrokeIds.putIfAbsent(note.id, () => {});
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
      if (!noteStrokeIds.contains(stroke.id) &&
          stroke.points.isNotEmpty) {
        final p = stroke.points.last;
        final dist = _pointDist(relX, relY, p.x, p.y);
        if (dist <= tolerance + stroke.style.thickness / 2) {
          noteStrokeIds.add(stroke.id);
        }
      }
    }
  }

  /// Commits all erased note strokes/shapes via UpdateStickyNoteCommand.
  /// Minimizes (if not already) and deselects a sticky note.
  void _minimizeAndDeselectNote(core.StickyNote note) {
    if (!note.minimized) {
      final document = ref.read(documentProvider);
      final updated = note.copyWith(minimized: true);
      final command = core.UpdateStickyNoteCommand(
        layerIndex: document.activeLayerIndex,
        newNote: updated,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }
    ref.read(stickyNotePlacementProvider.notifier).deselectNote();
  }

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

  // ─────────────────────────────────────────────────────────────────────────
  // SHAPE EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleShapeDown(PointerDownEvent event) {
    _detectDrawingInsideNote(event);

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

    final clampedPoint = _clampToNote(core.DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: 1.0,
    ));

    activeShapeTool!.startShape(clampedPoint);

    isDrawingShape = true;
    setState(() {});
  }

  void handleShapeMove(PointerMoveEvent event) {
    final tool = activeShapeTool;
    if (tool == null) return;

    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    final clampedPoint = _clampToNote(core.DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: 1.0,
    ));

    tool.updateShape(clampedPoint);

    setState(() {});
  }

  void handleShapeUp(PointerUpEvent event) {
    final tool = activeShapeTool;
    if (tool == null) return;

    isDrawingShape = false;

    final shape = tool.endShape();

    if (shape != null) {
      if (drawingInsideNote != null) {
        _addShapeToStickyNote(shape, drawingInsideNote!);
      } else {
        final document = ref.read(documentProvider);
        final command = core.AddShapeCommand(
          layerIndex: document.activeLayerIndex,
          shape: shape,
        );
        ref.read(historyManagerProvider.notifier).execute(command);
      }
    }

    activeShapeTool = null;
    drawingInsideNote = null;
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
  // IMAGE PLACEMENT
  // ─────────────────────────────────────────────────────────────────────────

  void _handleImagePlacement(PointerDownEvent event) {
    final imageState = ref.read(imagePlacementProvider);
    final imagePath = imageState.selectedImagePath;
    if (imagePath == null) return;

    final transform = ref.read(canvasTransformProvider);
    final canvasPoint =
        (event.localPosition - transform.offset) / transform.zoom;

    // Default image size on canvas
    const defaultWidth = 200.0;
    const defaultHeight = 200.0;

    // Clamp position to page bounds
    final page = ref.read(currentPageProvider);
    final maxX = (page.size.width - defaultWidth).clamp(0.0, page.size.width);
    final maxY =
        (page.size.height - defaultHeight).clamp(0.0, page.size.height);
    final clampedX = (canvasPoint.dx - defaultWidth / 2).clamp(0.0, maxX);
    final clampedY = (canvasPoint.dy - defaultHeight / 2).clamp(0.0, maxY);

    final imageElement = core.ImageElement.create(
      filePath: imagePath,
      x: clampedX,
      y: clampedY,
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
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE CONTEXT MENU HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleImageDelete() {
    final imgState = ref.read(imagePlacementProvider);
    final image = imgState.selectedImage;
    if (image != null) {
      final document = ref.read(documentProvider);
      final command = core.RemoveImageCommand(
        layerIndex: document.activeLayerIndex,
        imageId: image.id,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
      ref.read(imagePlacementProvider.notifier).deselectImage();
    }
  }

  void handleImageDuplicate() {
    final imgState = ref.read(imagePlacementProvider);
    final image = imgState.selectedImage;
    if (image != null) {
      final duplicate = core.ImageElement.create(
        filePath: image.filePath,
        x: image.x + 40,
        y: image.y + 40,
        width: image.width,
        height: image.height,
        rotation: image.rotation,
      );
      final document = ref.read(documentProvider);
      final command = core.AddImageCommand(
        layerIndex: document.activeLayerIndex,
        imageElement: duplicate,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
      ref.read(imagePlacementProvider.notifier).deselectImage();
    }
  }

  void handleImageMove() {
    final imgState = ref.read(imagePlacementProvider);
    final image = imgState.selectedImage;
    if (image != null) {
      ref.read(imagePlacementProvider.notifier).startMoving(image);
    }
  }

  void _moveImageTo(double x, double y) {
    final imgState = ref.read(imagePlacementProvider);
    final movingImage = imgState.movingImage;
    if (movingImage != null) {
      final movedImage = movingImage.copyWith(x: x, y: y);
      final document = ref.read(documentProvider);
      final command = core.UpdateImageCommand(
        layerIndex: document.activeLayerIndex,
        newImage: movedImage,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
      ref.read(imagePlacementProvider.notifier).cancelMoving();
    }
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
    if (isLaserDrawing) {
      laserController.cancelStroke();
      isLaserDrawing = false;
    }
    if (isSelecting) {
      ref.read(activeSelectionToolProvider).cancelSelection();
      isSelecting = false;
    }
    // Reset selection UI state (hide menu, cancel live transform)
    ref.read(selectionUiProvider.notifier).reset();
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

    lastFocalPoint = details.localFocalPoint;
    lastScale = 1.0;
    scaleStartFocalPoint = details.localFocalPoint;
    scaleGestureIsZoom = false;
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

    // Gesture classification: zoom vs swipe.
    // Zoom: fingers move apart/together but focal point stays ~stationary.
    // Swipe: fingers move together, focal point travels far.
    // Use both scale change AND displacement to decide.
    if (!scaleGestureIsZoom && !mode.isInfinite && onPageSwipe != null) {
      final scaleChange = (details.scale - 1.0).abs();
      final displacement = scaleStartFocalPoint != null
          ? (details.localFocalPoint - scaleStartFocalPoint!).distance
          : 0.0;
      if (scaleChange > 0.30) {
        // Very large scale change = definitely zoom regardless of movement
        scaleGestureIsZoom = true;
      } else if (scaleChange > 0.12 && displacement < 30) {
        // Moderate scale change + barely moved = intentional zoom
        scaleGestureIsZoom = true;
      }
    }

    // Apply zoom (pinch gesture) — skip if zoom is locked or gesture is swipe
    final isZoomLocked = ref.read(zoomLockedProvider);
    final suppressZoom = !mode.isInfinite &&
        onPageSwipe != null &&
        !scaleGestureIsZoom;
    if (!isZoomLocked && !suppressZoom && lastScale != null && details.scale != 1.0) {
      final scaleDelta = details.scale / lastScale!;
      if ((scaleDelta - 1.0).abs() > 0.001) {
        if (mode.isInfinite) {
          // Unlimited zoom for whiteboard - use mode's zoom limits
          transformNotifier.applyZoomDelta(
            scaleDelta,
            details.localFocalPoint,
            minZoom: mode.minZoom,
            maxZoom: mode.maxZoom,
          );
        } else {
          // Clamped zoom for notebook/limited modes
          transformNotifier.applyZoomDeltaClamped(
            scaleDelta,
            details.localFocalPoint,
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
      final panDelta = details.localFocalPoint - lastFocalPoint!;
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

    lastFocalPoint = details.localFocalPoint;
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

    // Detect two-finger swipe for page navigation (limited canvas only)
    // Only attempt if gesture was NOT classified as zoom
    final mode = canvasMode ?? const core.CanvasMode(isInfinite: true);
    if (!mode.isInfinite && onPageSwipe != null && !scaleGestureIsZoom) {
      final swipeDir = _detectPageSwipe(details.velocity);
      if (swipeDir != 0) {
        onPageSwipe!(swipeDir);
        lastFocalPoint = null;
        lastScale = null;
        scaleStartFocalPoint = null;
        return;
      }
    }

    // Snap back for limited canvas mode
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
    scaleStartFocalPoint = null;
  }

  /// Detects a two-finger horizontal/vertical swipe gesture.
  /// Called only when gesture was NOT classified as zoom (scaleGestureIsZoom == false).
  /// Returns +1 (next page), -1 (previous page), or 0 (no swipe).
  int _detectPageSwipe(Velocity velocity) {
    final startPoint = scaleStartFocalPoint;
    final endPoint = lastFocalPoint;

    // Need valid tracking data
    if (startPoint == null || endPoint == null) return 0;

    final scrollDir = ref.read(scrollDirectionProvider);
    final isHorizontal = scrollDir == Axis.horizontal;

    // Check displacement from start
    final displacement = endPoint - startPoint;
    final primaryDisplacement =
        isHorizontal ? displacement.dx : displacement.dy;
    final crossDisplacement =
        isHorizontal ? displacement.dy : displacement.dx;

    // Minimum displacement along primary axis
    if (primaryDisplacement.abs() < 30) return 0;

    // Primary axis must dominate cross axis (loose ratio for natural swipes)
    if (crossDisplacement.abs() > 0 &&
        primaryDisplacement.abs() < crossDisplacement.abs() * 1.2) {
      return 0;
    }

    // Negative displacement = swiped toward next page
    return primaryDisplacement < 0 ? 1 : -1;
  }
}
