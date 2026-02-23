import 'dart:async' show Timer;
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
import 'package:drawing_ui/src/widgets/ruler_overlay.dart'
    show rulerStripLength, rulerStripHeight;

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

  // ── Long press paste menu ──
  Timer? _longPressTimer;
  Offset? _longPressScreenPos;

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

  /// Snap threshold in screen pixels.
  static const double _rulerSnapThreshold = 30.0;

  /// Returns true if [screenPoint] falls inside the rotated ruler strip.
  ///
  /// [rulerPositionProvider] stores the centre of the ruler.
  /// Un-rotates the point around that centre and checks against the
  /// axis-aligned bounds [-length/2, length/2] x [-height/2, height/2].
  bool _isPointOnRuler(Offset screenPoint) {
    if (!ref.read(rulerVisibleProvider)) return false;

    final center = ref.read(rulerPositionProvider);
    final angle = ref.read(rulerAngleProvider);

    final cosA = math.cos(-angle);
    final sinA = math.sin(-angle);
    final d = screenPoint - center;
    final localX = d.dx * cosA - d.dy * sinA;
    final localY = d.dx * sinA + d.dy * cosA;

    return localX.abs() <= rulerStripLength / 2 &&
        localY.abs() <= rulerStripHeight / 2;
  }

  /// Snaps [point] to the nearest ruler edge (top or bottom).
  ///
  /// If the point is ON the ruler body it is always projected to the nearest
  /// edge so the pen draws parallel to the ruler (physical ruler behaviour).
  /// If the point is outside but within [_rulerSnapThreshold] it is snapped.
  core.DrawingPoint _snapToRuler(core.DrawingPoint point) {
    if (!ref.read(rulerVisibleProvider)) return point;

    final transform = ref.read(canvasTransformProvider);
    final center = ref.read(rulerPositionProvider);
    final angle = ref.read(rulerAngleProvider);

    // Perpendicular direction (un-rotated +Y → points "down" from ruler).
    final perpX = -math.sin(angle);
    final perpY = math.cos(angle);
    final halfH = rulerStripHeight / 2;

    // Bottom edge origin in screen space.
    final bottomScreen = center + Offset(perpX * halfH, perpY * halfH);
    // Top edge origin in screen space.
    final topScreen = center + Offset(-perpX * halfH, -perpY * halfH);

    final pointScreen =
        transform.canvasToScreen(Offset(point.x, point.y));
    final dirX = math.cos(angle);
    final dirY = math.sin(angle);

    // Project onto bottom edge.
    final vB = pointScreen - bottomScreen;
    final tB = vB.dx * dirX + vB.dy * dirY;
    final projB = bottomScreen + Offset(dirX * tB, dirY * tB);
    final distB = (pointScreen - projB).distance;

    // Project onto top edge.
    final vT = pointScreen - topScreen;
    final tT = vT.dx * dirX + vT.dy * dirY;
    final projT = topScreen + Offset(dirX * tT, dirY * tT);
    final distT = (pointScreen - projT).distance;

    // If the point is on the ruler body, always project to nearest edge.
    // If outside but near an edge, snap within threshold.
    final onRuler = _isPointOnRuler(pointScreen);
    final dist = math.min(distB, distT);
    if (!onRuler && dist >= _rulerSnapThreshold) return point;

    final projected = distB <= distT ? projB : projT;
    final canvasProj = transform.screenToCanvas(projected);

    return core.DrawingPoint(
      x: canvasProj.dx,
      y: canvasProj.dy,
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

    // Block drawing on locked or hidden active layer
    final activeLayer = ref.read(documentProvider).activeLayer;
    if (activeLayer != null && (activeLayer.isLocked || !activeLayer.isVisible)) {
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
    if (selUi.showMenu) {
      ref.read(selectionUiProvider.notifier).hideContextMenu();
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
    // via the main selection system (SelectionHandles + SelectionToolbar)
    if (toolType == ToolType.image) {
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
          ref.read(currentToolProvider.notifier).state = ToolType.selection;
          return;
        }
      }
      return;
    }

    // Sticker tool selected (no placement) — tap on existing text selects it
    if (toolType == ToolType.sticker) {
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint =
          (event.localPosition - transform.offset) / transform.zoom;
      final texts = ref.read(activeLayerTextsProvider);
      for (final text in texts.reversed) {
        if (text.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
          _selectText(text);
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

    // Check if tap is on an existing text/sticker — select it
    {
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint =
          (event.localPosition - transform.offset) / transform.zoom;
      final texts = ref.read(activeLayerTextsProvider);
      for (final text in texts.reversed) {
        if (text.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
          _selectText(text);
          return;
        }
      }
    }

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
      if (distance < minPointDistance) return;
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

    final selection = tool.endSelection(strokes, shapes, images, texts);

    if (selection != null) {
      ref.read(selectionProvider.notifier).setSelection(selection);
      ref.read(selectionUiProvider.notifier).showContextMenu();
    }

    setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STRAIGHT LINE EVENT HANDLERS (for highlighter)
  // ─────────────────────────────────────────────────────────────────────────

  void handleStraightLineDown(PointerDownEvent event) {
    if (_isPointOnRuler(event.localPosition)) return;

    _detectDrawingInsideNote(event);
    var point = _clampToNote(createDrawingPoint(event));
    point = _snapToRuler(point);
    final style = getCurrentStyle();

    straightLineStart = point;
    straightLineEnd = point;
    straightLineStyle = style;
    isStraightLineDrawing = true;

    setState(() {});
  }

  void handleStraightLineMove(PointerMoveEvent event) {
    if (!isStraightLineDrawing || straightLineStart == null) return;

    var point = _clampToNote(createDrawingPoint(event));
    point = _snapToRuler(point);
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

    // AutoLift: switch back to previous tool after erasing
    if (settings.autoLift) {
      final prevTool = ref.read(previousToolProvider);
      if (prevTool != null) {
        ref.read(currentToolProvider.notifier).state = prevTool;
        ref.read(previousToolProvider.notifier).state = null;
      }
    }
  }

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

    // Check if tapped on existing text - enter editing directly (text tool)
    final texts = ref.read(activeLayerTextsProvider);

    for (final text in texts.reversed) {
      if (text.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
        ref.read(textToolProvider.notifier).editExistingText(text);
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

      // Auto-select into selection system
      _selectText(currentText);
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
  // TEXT HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Selects a text element into the main selection system.
  void _selectText(core.TextElement text) {
    final selection = core.Selection.create(
      type: core.SelectionType.rectangle,
      selectedStrokeIds: const [],
      selectedShapeIds: const [],
      selectedImageIds: const [],
      selectedTextIds: [text.id],
      bounds: text.bounds,
    );
    ref.read(selectionProvider.notifier).setSelection(selection);
    ref.read(selectionUiProvider.notifier).showContextMenu();
    ref.read(currentToolProvider.notifier).state = ToolType.selection;
  }

  void handleTextStyleChanged(core.TextElement updatedText) {
    final document = ref.read(documentProvider);
    final command = core.UpdateTextCommand(
      layerIndex: document.activeLayerIndex,
      newText: updatedText,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
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

    // Check if tap is on an existing text/sticker — select it
    final texts = ref.read(activeLayerTextsProvider);
    for (final text in texts.reversed) {
      if (text.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
        _selectText(text);
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
    ref.read(currentToolProvider.notifier).state = ToolType.selection;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE CONTEXT MENU HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

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
