import 'dart:async' show Timer;
import 'dart:math' as math;
import 'dart:ui' as ui;

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

part 'gestures/ruler_snapping.dart';
part 'gestures/sticky_note_gestures.dart';
part 'gestures/text_gestures.dart';
part 'gestures/placement_gestures.dart';
part 'gestures/selection_gestures.dart';
part 'gestures/shape_gestures.dart';
part 'gestures/straight_line_gestures.dart';
part 'gestures/laser_gestures.dart';
part 'gestures/note_eraser_gestures.dart';
part 'gestures/pixel_eraser_gestures.dart';
part 'gestures/eraser_gestures.dart';
part 'gestures/scale_gestures.dart';

/// Shared state contract for the gesture mixins of [DrawingCanvasState].
///
/// Abstract accessors are implemented by `DrawingCanvasState`; the private
/// fields are shared between the gesture mixins in this library.
mixin _GestureState<T extends ConsumerStatefulWidget>
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
  VoidCallback? get onPageSwipeDragBegin;
  ValueChanged<double>? get onPageSwipeDragUpdate;
  ValueChanged<double>? get onPageSwipeDragEnd;
  bool get scaleGestureIsZoom;
  set scaleGestureIsZoom(bool value);
  bool _swipeDragActive = false;

  // ── Long press paste menu ──
  Timer? _longPressTimer;
  Offset? _longPressScreenPos;
}

/// Gesture handling methods for DrawingCanvas.
/// Composes the private gesture mixins of this library.
abstract class DrawingCanvasGestureHandlers<T extends ConsumerStatefulWidget>
    extends ConsumerState<T>
    with
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
        _ScaleGestures<T>,
        _PointerDownGestures<T> {
  /// Minimum distance between points to avoid excessive point creation.
  static const double minPointDistance = 1.0;
}

/// Temporary remainder holding the not yet extracted handlers.
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
    if (stickyNoteState.selectedNote != null &&
        toolType != ToolType.stickyNote) {
      final transform = ref.read(canvasTransformProvider);
      final cp = transform.screenToCanvas(event.localPosition);
      if (!stickyNoteState.selectedNote!.containsPoint(cp.dx, cp.dy, 0)) {
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
            ref
                .read(stickyNotePlacementProvider.notifier)
                .selectNote(maximized);
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
      // Cancel eraser session
      ref.read(eraserToolProvider).endErasing();
    } else {
      drawingController.cancelStroke();
    }
    drawingInsideNote = null;
    lastPoint = null;
  }
}
