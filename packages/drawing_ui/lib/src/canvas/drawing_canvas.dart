import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/canvas/selection_painter.dart';
import 'package:drawing_ui/src/canvas/shape_painter.dart';
import 'package:drawing_ui/src/canvas/text_painter.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/eraser_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/tool_style_provider.dart';
import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';
import 'package:drawing_ui/src/providers/selection_provider.dart';
import 'package:drawing_ui/src/providers/shape_provider.dart';
import 'package:drawing_ui/src/providers/text_provider.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/widgets/widgets.dart';

// =============================================================================
// DRAWING CANVAS WIDGET
// =============================================================================

/// The main drawing canvas widget that handles stroke rendering.
///
/// This widget uses a multi-layer architecture for optimal performance:
/// - Layer 1: Background grid (never repaints)
/// - Layer 2: Committed strokes (repaints only when strokes are added/removed)
/// - Layer 3: Committed shapes + preview (repaints when shapes change or during preview)
/// - Layer 4: Active stroke (repaints on every pointer move)
/// - Layer 5: Selection overlay (selection bounds, handles, preview)
/// - Layer 6: Selection handles (for drag interactions)
///
/// ## Performance Rules Applied:
/// - NO setState for drawing updates
/// - RepaintBoundary isolates each layer
/// - Cached renderer instance
/// - Optimized shouldRepaint in all painters
///
/// ## Usage
/// ```dart
/// DrawingCanvas(
///   width: 800,
///   height: 600,
/// )
/// ```
class DrawingCanvas extends ConsumerStatefulWidget {
  /// Width of the canvas. Defaults to fill available space.
  final double width;

  /// Height of the canvas. Defaults to fill available space.

  const DrawingCanvas({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  final double height;

  @override
  ConsumerState<DrawingCanvas> createState() => DrawingCanvasState();
}

/// State for [DrawingCanvas].
///
/// Exposed as public for testing purposes.
class DrawingCanvasState extends ConsumerState<DrawingCanvas> {
  /// Controller for managing active stroke state.
  /// Uses ChangeNotifier instead of setState for performance.
  late final DrawingController _drawingController;

  /// Cached renderer instance - shared across all painters.
  final FlutterStrokeRenderer _renderer = FlutterStrokeRenderer();

  // ─────────────────────────────────────────────────────────────────────────
  // GESTURE HANDLING - Performance optimizations
  // ─────────────────────────────────────────────────────────────────────────

  /// Minimum distance between points to avoid excessive point creation.
  /// Points closer than this are skipped for performance.
  static const double _minPointDistance = 1.0;

  /// Last recorded point position for distance filtering.
  Offset? _lastPoint;

  // ─────────────────────────────────────────────────────────────────────────
  // ZOOM/PAN GESTURE TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Number of active pointers (fingers) on the canvas.
  /// Used to distinguish between drawing (1 finger) and zoom/pan (2 fingers).
  int _pointerCount = 0;

  /// Last focal point for scale gesture (zoom/pan center point).
  Offset? _lastFocalPoint;

  /// Last scale value for calculating zoom delta.
  double? _lastScale;

  // ─────────────────────────────────────────────────────────────────────────
  // SELECTION TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether a selection operation is in progress.
  bool _isSelecting = false;

  // ─────────────────────────────────────────────────────────────────────────
  // SHAPE TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether a shape drawing operation is in progress.
  bool _isDrawingShape = false;

  /// Active shape tool instance.
  core.ShapeTool? _activeShapeTool;

  // ─────────────────────────────────────────────────────────────────────────
  // STRAIGHT LINE MODE TRACKING (for highlighters)
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether straight line drawing is in progress.
  bool _isStraightLineDrawing = false;

  /// Start point for straight line.
  core.DrawingPoint? _straightLineStart;

  /// Current end point for straight line (for preview).
  core.DrawingPoint? _straightLineEnd;

  /// Style for straight line.
  core.StrokeStyle? _straightLineStyle;

  // ─────────────────────────────────────────────────────────────────────────
  // ERASER SHAPE TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Shape IDs erased in current gesture session.
  final Set<String> _erasedShapeIds = {};

  /// Text IDs erased in current gesture session.
  final Set<String> _erasedTextIds = {};

  /// Exposes the drawing controller for testing.
  @visibleForTesting
  DrawingController get drawingController => _drawingController;

  /// Exposes committed strokes from provider for testing.
  @visibleForTesting
  List<core.Stroke> get committedStrokes =>
      ref.read(activeLayerStrokesProvider);

  /// Exposes last point for testing distance filtering.
  @visibleForTesting
  Offset? get lastPoint => _lastPoint;

  /// Exposes isSelecting for testing.
  @visibleForTesting
  bool get isSelecting => _isSelecting;

  /// Exposes isDrawingShape for testing.
  @visibleForTesting
  bool get isDrawingShape => _isDrawingShape;

  @override
  void initState() {
    super.initState();
    _drawingController = DrawingController();
  }

  @override
  void dispose() {
    _drawingController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POINTER EVENT HANDLERS (Single Finger Drawing)
  // ─────────────────────────────────────────────────────────────────────────
  // NO setState here! Only DrawingController.notifyListeners() triggers repaint.

  /// Handles pointer down - starts a new stroke, eraser, selection, shape, or text.
  void _handlePointerDown(PointerDownEvent event) {
    _pointerCount++;

    // Only handle with single finger
    if (_pointerCount != 1) return;

    // Get current tool type
    final toolType = ref.read(currentToolProvider);

    // If text editing is active and tap is outside, finish editing
    final textToolState = ref.read(textToolProvider);
    if (textToolState.isEditing && toolType != ToolType.text) {
      _finishTextEditing();
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
        if (_isPointInSelection(canvasPoint, selection)) {
          // Don't start new selection - SelectionHandles will handle this
          return;
        }
      }
      // Start new selection (outside existing or no selection)
      _handleSelectionDown(event);
      return;
    }

    // Check if there's an existing selection and tap is outside
    final selection = ref.read(selectionProvider);
    if (selection != null) {
      final transform = ref.read(canvasTransformProvider);
      final canvasPoint =
          (event.localPosition - transform.offset) / transform.zoom;

      if (!_isPointInSelection(canvasPoint, selection)) {
        ref.read(selectionProvider.notifier).clearSelection();
      }
    }

    // Check if eraser is active
    final isEraser = ref.read(isEraserToolProvider);
    if (isEraser) {
      _handleEraserDown(event);
      return;
    }

    // Check if shape tool is active
    final isShapeTool = ref.read(isShapeToolProvider);
    if (isShapeTool) {
      _handleShapeDown(event);
      return;
    }

    // Check if text tool is active
    if (toolType == ToolType.text) {
      _handleTextDown(event);
      return;
    }

    // Check if highlighter straight line mode is active
    if ((toolType == ToolType.highlighter || toolType == ToolType.neonHighlighter) &&
        ref.read(highlighterSettingsProvider).straightLineMode) {
      _handleStraightLineDown(event);
      return;
    }

    // Ruler pen always draws straight lines
    if (toolType == ToolType.rulerPen) {
      _handleStraightLineDown(event);
      return;
    }

    // Drawing mode
    final point = _createDrawingPoint(event);
    final style = _getCurrentStyle();
    
    // Get stabilization setting (only for pen tools, not highlighters)
    double stabilization = 0.0;
    if (toolType.isPenTool && toolType != ToolType.highlighter && toolType != ToolType.neonHighlighter) {
      final penSettings = ref.read(penSettingsProvider(toolType));
      stabilization = penSettings.stabilization;
    }
    
    _drawingController.startStroke(
      point,
      style,
      stabilization: stabilization,
      straightLine: false,
    );
    _lastPoint = event.localPosition;
  }

  /// Handles pointer move - adds points to active stroke, erases, updates selection, or shape.
  void _handlePointerMove(PointerMoveEvent event) {
    // Only handle with single finger
    if (_pointerCount != 1) return;

    // Selection mode
    if (_isSelecting) {
      _handleSelectionMove(event);
      return;
    }

    // Shape mode
    if (_isDrawingShape) {
      _handleShapeMove(event);
      return;
    }

    // Straight line mode (highlighter)
    if (_isStraightLineDrawing) {
      _handleStraightLineMove(event);
      return;
    }

    // Check if eraser is active
    final isEraser = ref.read(isEraserToolProvider);
    if (isEraser) {
      _handleEraserMove(event);
      return;
    }

    // Drawing mode
    if (!_drawingController.isDrawing) return;

    // Performance: Skip points that are too close together
    if (_lastPoint != null) {
      final distance = (event.localPosition - _lastPoint!).distance;
      if (distance < _minPointDistance) return;
    }

    final point = _createDrawingPoint(event);
    _drawingController.addPoint(point);
    _lastPoint = event.localPosition;
  }

  /// Handles pointer up - finishes stroke, eraser, selection, or shape.
  void _handlePointerUp(PointerUpEvent event) {
    _pointerCount = (_pointerCount - 1).clamp(0, 10);

    // Selection mode
    if (_isSelecting) {
      _handleSelectionUp(event);
      return;
    }

    // Shape mode
    if (_isDrawingShape) {
      _handleShapeUp(event);
      return;
    }

    // Straight line mode
    if (_isStraightLineDrawing) {
      _handleStraightLineUp(event);
      return;
    }

    // Check if eraser is active
    final isEraser = ref.read(isEraserToolProvider);
    if (isEraser) {
      _handleEraserUp(event);
      return;
    }

    // Drawing mode - commit if we were drawing with single finger
    if (_pointerCount == 0 && _drawingController.isDrawing) {
      final stroke = _drawingController.endStroke();
      if (stroke != null) {
        // Add stroke via history provider (enables undo/redo)
        ref.read(historyManagerProvider.notifier).addStroke(stroke);
      }
    }
    _lastPoint = null;
  }

  /// Handles pointer cancel - cancels the current operation.
  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerCount = (_pointerCount - 1).clamp(0, 10);

    // Selection mode
    if (_isSelecting) {
      ref.read(activeSelectionToolProvider).cancelSelection();
      _isSelecting = false;
      setState(() {});
      return;
    }

    // Shape mode
    if (_isDrawingShape) {
      _activeShapeTool?.cancelShape();
      _activeShapeTool = null;
      _isDrawingShape = false;
      setState(() {});
      return;
    }

    // Straight line mode
    if (_isStraightLineDrawing) {
      _straightLineStart = null;
      _straightLineEnd = null;
      _straightLineStyle = null;
      _isStraightLineDrawing = false;
      setState(() {});
      return;
    }

    // Check if eraser is active
    final isEraser = ref.read(isEraserToolProvider);
    if (isEraser) {
      // Cancel eraser session
      ref.read(eraserToolProvider).endErasing();
    } else {
      _drawingController.cancelStroke();
    }
    _lastPoint = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SELECTION EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Handles selection pointer down - starts selection operation.
  void _handleSelectionDown(PointerDownEvent event) {
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

    _isSelecting = true;
    setState(() {});
  }

  /// Handles selection pointer move - updates selection path.
  void _handleSelectionMove(PointerMoveEvent event) {
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

  /// Handles selection pointer up - finalizes selection.
  void _handleSelectionUp(PointerUpEvent event) {
    _isSelecting = false;

    final tool = ref.read(activeSelectionToolProvider);
    final strokes = ref.read(activeLayerStrokesProvider);
    final shapes = ref.read(activeLayerShapesProvider);

    final selection = tool.endSelection(strokes, shapes);

    if (selection != null) {
      ref.read(selectionProvider.notifier).setSelection(selection);
    }

    setState(() {});
  }

  /// Checks if a point is inside the selection bounds.
  bool _isPointInSelection(Offset point, core.Selection selection) {
    final bounds = selection.bounds;
    return point.dx >= bounds.left &&
        point.dx <= bounds.right &&
        point.dy >= bounds.top &&
        point.dy <= bounds.bottom;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STRAIGHT LINE EVENT HANDLERS (for highlighter)
  // ─────────────────────────────────────────────────────────────────────────
  // Real-time preview like shape tools - setState triggers rebuild

  /// Handles straight line pointer down - starts straight line drawing.
  void _handleStraightLineDown(PointerDownEvent event) {
    final point = _createDrawingPoint(event);
    final style = _getCurrentStyle();

    _straightLineStart = point;
    _straightLineEnd = point;
    _straightLineStyle = style;
    _isStraightLineDrawing = true;

    setState(() {});
  }

  /// Handles straight line pointer move - updates end point for preview.
  void _handleStraightLineMove(PointerMoveEvent event) {
    if (!_isStraightLineDrawing || _straightLineStart == null) return;

    final point = _createDrawingPoint(event);
    _straightLineEnd = point;

    setState(() {}); // Triggers rebuild for real-time preview
  }

  /// Handles straight line pointer up - commits the straight line stroke.
  void _handleStraightLineUp(PointerUpEvent event) {
    if (!_isStraightLineDrawing) return;

    final start = _straightLineStart;
    final end = _straightLineEnd;
    final style = _straightLineStyle;

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
    _straightLineStart = null;
    _straightLineEnd = null;
    _straightLineStyle = null;
    _isStraightLineDrawing = false;

    setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ERASER EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────
  // Eraser uses command batching: single gesture = single undo command

  /// Handles eraser pointer down - starts eraser session.
  void _handleEraserDown(PointerDownEvent event) {
    final eraserTool = ref.read(eraserToolProvider);
    eraserTool.startErasing();
    _erasedShapeIds.clear();
    _erasedTextIds.clear();
    _eraseAtPoint(event.localPosition);
  }

  /// Handles eraser pointer move - erases strokes along the path.
  void _handleEraserMove(PointerMoveEvent event) {
    _eraseAtPoint(event.localPosition);
  }

  /// Handles eraser pointer up - commits all erased strokes, shapes, and texts as commands.
  void _handleEraserUp(PointerUpEvent event) {
    final eraserTool = ref.read(eraserToolProvider);
    final erasedStrokeIds = eraserTool.endErasing();
    final document = ref.read(documentProvider);
    final layerIndex = document.activeLayerIndex;

    // Commit erased strokes
    if (erasedStrokeIds.isNotEmpty) {
      final command = core.EraseStrokesCommand(
        layerIndex: layerIndex,
        strokeIds: erasedStrokeIds.toList(),
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }

    // Commit erased shapes (each shape as separate command for undo granularity)
    for (final shapeId in _erasedShapeIds) {
      final command = core.RemoveShapeCommand(
        layerIndex: layerIndex,
        shapeId: shapeId,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }
    _erasedShapeIds.clear();

    // Commit erased texts (each text as separate command for undo granularity)
    for (final textId in _erasedTextIds) {
      final command = core.RemoveTextCommand(
        layerIndex: layerIndex,
        textId: textId,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }
    _erasedTextIds.clear();
  }

  /// Erases strokes, shapes, and texts at the given screen point.
  /// Transforms screen coordinates to canvas coordinates.
  void _eraseAtPoint(Offset point) {
    // Transform screen coordinates to canvas coordinates (zoom/pan)
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(point);

    final strokes = ref.read(activeLayerStrokesProvider);
    final shapes = ref.read(activeLayerShapesProvider);
    final texts = ref.read(activeLayerTextsProvider);
    final eraserTool = ref.read(eraserToolProvider);

    // Find strokes to erase
    final toErase = eraserTool.findStrokesToErase(
      strokes,
      canvasPoint.dx,
      canvasPoint.dy,
    );

    for (final stroke in toErase) {
      if (!eraserTool.isAlreadyErased(stroke.id)) {
        eraserTool.markAsErased(stroke.id);
      }
    }

    // Find shapes to erase
    for (final shape in shapes) {
      if (!_erasedShapeIds.contains(shape.id)) {
        if (shape.containsPoint(
          canvasPoint.dx,
          canvasPoint.dy,
          eraserTool.tolerance,
        )) {
          _erasedShapeIds.add(shape.id);
        }
      }
    }

    // Find texts to erase
    for (final text in texts) {
      if (!_erasedTextIds.contains(text.id)) {
        if (text.containsPoint(
          canvasPoint.dx,
          canvasPoint.dy,
          eraserTool.tolerance,
        )) {
          _erasedTextIds.add(text.id);
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHAPE EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Handles shape pointer down - starts shape drawing.
  void _handleShapeDown(PointerDownEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    final coreShapeType = ref.read(activeCoreShapeTypeProvider);
    final isFilled = ref.read(shapeFilledProvider);
    final fillColor = ref.read(shapeFillColorProvider);
    final style = ref.read(shapeStrokeStyleProvider);

    // Create shape tool based on type
    switch (coreShapeType) {
      case core.ShapeType.line:
        _activeShapeTool = core.LineTool(style: style);
        break;
      case core.ShapeType.arrow:
        _activeShapeTool = core.ArrowTool(style: style);
        break;
      case core.ShapeType.rectangle:
        _activeShapeTool = core.RectangleTool(
          style: style,
          filled: isFilled,
          fillColor: fillColor,
        );
        break;
      case core.ShapeType.ellipse:
        _activeShapeTool = core.EllipseTool(
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
        _activeShapeTool = core.GenericShapeTool(
          style: style,
          shapeType: coreShapeType,
          filled: isFilled,
          fillColor: fillColor,
        );
        break;
    }

    _activeShapeTool!.startShape(core.DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: 1.0,
    ));

    _isDrawingShape = true;
    setState(() {});
  }

  /// Handles shape pointer move - updates shape preview.
  void _handleShapeMove(PointerMoveEvent event) {
    if (_activeShapeTool == null) return;

    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    _activeShapeTool!.updateShape(core.DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: 1.0,
    ));

    setState(() {});
  }

  /// Handles shape pointer up - commits shape to document.
  void _handleShapeUp(PointerUpEvent event) {
    if (_activeShapeTool == null) return;

    _isDrawingShape = false;

    final shape = _activeShapeTool!.endShape();

    if (shape != null) {
      final document = ref.read(documentProvider);
      final command = core.AddShapeCommand(
        layerIndex: document.activeLayerIndex,
        shape: shape,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }

    _activeShapeTool = null;
    setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Handles text pointer down - shows context menu or starts text editing.
  void _handleTextDown(PointerDownEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint =
        (event.localPosition - transform.offset) / transform.zoom;

    // Check if there's already active text editing
    final textToolState = ref.read(textToolProvider);

    // Handle move mode - move text to tapped location
    if (textToolState.isMoving) {
      _moveTextTo(canvasPoint.dx, canvasPoint.dy);
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
        _finishTextEditing();
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

    // Create new text at tap location (only if no text was being edited)
    final style = ref.read(activeStrokeStyleProvider);
    ref.read(textToolProvider.notifier).startNewText(
          canvasPoint.dx,
          canvasPoint.dy,
          fontSize: style.thickness * 4, // Font size based on stroke thickness
          color: style.color,
        );
  }

  /// Finishes text editing and saves the text.
  void _finishTextEditing() {
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

  /// Cancels text editing without saving.
  void _cancelTextEditing() {
    ref.read(textToolProvider.notifier).cancelEditing();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT CONTEXT MENU HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Handles edit action from context menu - opens TextField for editing.
  void _handleTextEdit() {
    final textToolState = ref.read(textToolProvider);
    if (textToolState.menuText != null) {
      ref
          .read(textToolProvider.notifier)
          .editExistingText(textToolState.menuText!);
    }
  }

  /// Handles delete action from context menu - removes text.
  void _handleTextDelete() {
    final textToolState = ref.read(textToolProvider);
    if (textToolState.menuText != null) {
      final document = ref.read(documentProvider);
      final command = core.RemoveTextCommand(
        layerIndex: document.activeLayerIndex,
        textId: textToolState.menuText!.id,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
      ref.read(textToolProvider.notifier).hideContextMenu();
    }
  }

  /// Handles style action from context menu - opens style popup.
  void _handleTextStyle() {
    final textToolState = ref.read(textToolProvider);
    if (textToolState.menuText != null) {
      ref
          .read(textToolProvider.notifier)
          .showStylePopup(textToolState.menuText!);
    }
  }

  /// Handles style change from popup - updates text style.
  void _handleTextStyleChanged(core.TextElement updatedText) {
    final document = ref.read(documentProvider);
    final command = core.UpdateTextCommand(
      layerIndex: document.activeLayerIndex,
      newText: updatedText,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
  }

  /// Handles duplicate action from context menu - copies text.
  void _handleTextDuplicate() {
    final textToolState = ref.read(textToolProvider);
    if (textToolState.menuText != null) {
      final originalText = textToolState.menuText!;
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

  /// Handles move action from context menu - starts move mode.
  void _handleTextMove() {
    final textToolState = ref.read(textToolProvider);
    if (textToolState.menuText != null) {
      ref.read(textToolProvider.notifier).startMoving(textToolState.menuText!);
    }
  }

  /// Handles text move to new location.
  void _moveTextTo(double x, double y) {
    final textToolState = ref.read(textToolProvider);
    if (textToolState.movingText != null) {
      final movedText = textToolState.movingText!.copyWith(x: x, y: y);
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
  // SCALE GESTURE HANDLERS (Two Finger Zoom/Pan)
  // ─────────────────────────────────────────────────────────────────────────

  /// Handles scale start - initializes zoom/pan gesture.
  void _handleScaleStart(ScaleStartDetails details) {
    // Only handle zoom/pan with 2+ fingers
    if (details.pointerCount < 2) return;

    // Cancel any ongoing operations when zoom/pan starts
    if (_drawingController.isDrawing) {
      _drawingController.cancelStroke();
    }
    if (_isSelecting) {
      ref.read(activeSelectionToolProvider).cancelSelection();
      _isSelecting = false;
    }
    if (_isDrawingShape) {
      _activeShapeTool?.cancelShape();
      _activeShapeTool = null;
      _isDrawingShape = false;
    }

    // Finish text editing if active (save the text)
    final textToolState = ref.read(textToolProvider);
    if (textToolState.isEditing) {
      _finishTextEditing();
    }

    _lastFocalPoint = details.focalPoint;
    _lastScale = 1.0;
  }

  /// Handles scale update - applies zoom and pan.
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Only handle zoom/pan with 2+ fingers
    if (details.pointerCount < 2) return;

    final transformNotifier = ref.read(canvasTransformProvider.notifier);

    // Apply zoom (pinch gesture)
    if (_lastScale != null && details.scale != 1.0) {
      final scaleDelta = details.scale / _lastScale!;
      if ((scaleDelta - 1.0).abs() > 0.001) {
        transformNotifier.applyZoomDelta(scaleDelta, details.focalPoint);
      }
    }

    // Apply pan (two finger drag)
    if (_lastFocalPoint != null) {
      final panDelta = details.focalPoint - _lastFocalPoint!;
      if (panDelta.distance > 0.5) {
        transformNotifier.applyPanDelta(panDelta);
      }
    }

    _lastFocalPoint = details.focalPoint;
    _lastScale = details.scale;
  }

  /// Handles scale end - finalizes zoom/pan gesture.
  void _handleScaleEnd(ScaleEndDetails details) {
    _lastFocalPoint = null;
    _lastScale = null;
  }

  /// Creates a DrawingPoint from a pointer event.
  /// Transforms screen coordinates to canvas coordinates based on zoom/pan.
  core.DrawingPoint _createDrawingPoint(PointerEvent event) {
    final transform = ref.read(canvasTransformProvider);

    // Convert screen coordinates to canvas coordinates
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    return core.DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: event.pressure.clamp(0.0, 1.0),
      tilt: 0.0,
      timestamp: event.timeStamp.inMilliseconds,
    );
  }

  /// Gets the current stroke style from provider.
  core.StrokeStyle _getCurrentStyle() {
    return ref.read(activeStrokeStyleProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final strokes = ref.watch(activeLayerStrokesProvider);
    final shapes = ref.watch(activeLayerShapesProvider);
    final texts = ref.watch(activeLayerTextsProvider);
    final isDrawingTool = ref.watch(isDrawingToolProvider);
    final isSelectionTool = ref.watch(isSelectionToolProvider);
    final isShapeTool = ref.watch(isShapeToolProvider);
    final currentTool = ref.watch(currentToolProvider);
    final transform = ref.watch(canvasTransformProvider);
    final selection = ref.watch(selectionProvider);
    final textToolState = ref.watch(textToolProvider);

    // Selection tool preview path
    List<core.DrawingPoint>? selectionPreviewPath;
    if (isSelectionTool && _isSelecting) {
      selectionPreviewPath = ref.read(activeSelectionToolProvider).currentPath;
    }

    // Shape preview
    core.Shape? previewShape;
    if (_isDrawingShape && _activeShapeTool != null) {
      previewShape = _activeShapeTool!.previewShape;
    }

    // Straight line preview (for highlighter)
    List<core.DrawingPoint>? straightLinePreviewPoints;
    core.StrokeStyle? straightLinePreviewStyle;
    if (_isStraightLineDrawing && _straightLineStart != null && _straightLineEnd != null) {
      straightLinePreviewPoints = [_straightLineStart!, _straightLineEnd!];
      straightLinePreviewStyle = _straightLineStyle;
    }

    // Enable pointer events for drawing tools, selection tool, shape tool, and text tool
    final isTextTool = currentTool == ToolType.text;
    final enablePointerEvents =
        isDrawingTool || isSelectionTool || isShapeTool || isTextTool;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          widget.width == double.infinity ? constraints.maxWidth : widget.width,
          widget.height == double.infinity
              ? constraints.maxHeight
              : widget.height,
        );

        // Wrap everything in a Stack to put menu/overlay OUTSIDE gesture handlers
        return Stack(
          children: [
            // Canvas with gesture handlers
            Listener(
              onPointerDown: enablePointerEvents ? _handlePointerDown : null,
              onPointerMove: enablePointerEvents ? _handlePointerMove : null,
              onPointerUp: enablePointerEvents ? _handlePointerUp : null,
              onPointerCancel:
                  enablePointerEvents ? _handlePointerCancel : null,
              behavior: HitTestBehavior.translucent,
              child: GestureDetector(
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                onScaleEnd: _handleScaleEnd,
                behavior: HitTestBehavior.opaque,
                child: ClipRect(
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Transform(
                      // Apply zoom and pan transformation
                      transform: transform.matrix,
                      alignment: Alignment.topLeft,
                      child: Stack(
                        children: [
                          // ─────────────────────────────────────────────────────────
                          // LAYER 1: Background Grid
                          // ─────────────────────────────────────────────────────────
                          // Never repaints - shouldRepaint always returns false
                          RepaintBoundary(
                            child: CustomPaint(
                              size: size,
                              painter: const GridPainter(),
                              isComplex: false,
                              willChange: false,
                            ),
                          ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 2: Committed Strokes (from DocumentProvider)
                          // ─────────────────────────────────────────────────────────
                          // Repaints when strokes are added/removed via provider
                          RepaintBoundary(
                            child: CustomPaint(
                              size: size,
                              painter: CommittedStrokesPainter(
                                strokes: strokes,
                                renderer: _renderer,
                              ),
                              isComplex: true,
                              willChange: false,
                            ),
                          ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 3: Committed Shapes + Preview Shape
                          // ─────────────────────────────────────────────────────────
                          // Repaints when shapes are added/removed or during shape preview
                          RepaintBoundary(
                            child: CustomPaint(
                              size: size,
                              painter: ShapePainter(
                                shapes: shapes,
                                activeShape: previewShape,
                              ),
                              isComplex: true,
                              willChange: previewShape != null,
                            ),
                          ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 4: Committed Texts + Active Text
                          // ─────────────────────────────────────────────────────────
                          // Repaints when texts are added/removed or during editing
                          RepaintBoundary(
                            child: CustomPaint(
                              size: size,
                              painter: TextElementPainter(
                                texts: texts,
                                activeText: textToolState.isEditing
                                    ? textToolState.activeText
                                    : null,
                              ),
                              isComplex: true,
                              willChange: textToolState.isEditing,
                            ),
                          ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 5: Active Stroke (Live Drawing)
                          // ─────────────────────────────────────────────────────────
                          // Repaints on every pointer move - must be fast!
                          RepaintBoundary(
                            child: ListenableBuilder(
                              listenable: _drawingController,
                              builder: (context, _) {
                                return CustomPaint(
                                  size: size,
                                  painter: ActiveStrokePainter(
                                    points: _drawingController.activePoints,
                                    style: _drawingController.activeStyle,
                                    renderer: _renderer,
                                  ),
                                  isComplex: false,
                                  willChange: true,
                                );
                              },
                            ),
                          ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 5.5: Straight Line Preview (for highlighter)
                          // ─────────────────────────────────────────────────────────
                          // Real-time preview when drawing straight line
                          if (straightLinePreviewPoints != null && straightLinePreviewStyle != null)
                            RepaintBoundary(
                              child: CustomPaint(
                                size: size,
                                painter: ActiveStrokePainter(
                                  points: straightLinePreviewPoints,
                                  style: straightLinePreviewStyle,
                                  renderer: _renderer,
                                ),
                                isComplex: false,
                                willChange: true,
                              ),
                            ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 6: Selection Overlay
                          // ─────────────────────────────────────────────────────────
                          // Selection bounds, lasso path, and preview
                          RepaintBoundary(
                            child: CustomPaint(
                              size: size,
                              painter: SelectionPainter(
                                selection: selection,
                                previewPath: selectionPreviewPath,
                                zoom: transform.zoom,
                              ),
                              isComplex: false,
                              willChange: true,
                            ),
                          ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 7: Selection Handles (for drag interactions)
                          // ─────────────────────────────────────────────────────────
                          if (selection != null)
                            SelectionHandles(
                              selection: selection,
                              onSelectionChanged: () => setState(() {}),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ───────────────────────────────────────────────────────────
            // Text Context Menu (OUTSIDE gesture handlers - screen coordinates)
            // ───────────────────────────────────────────────────────────
            if (textToolState.showMenu && textToolState.menuText != null)
              TextContextMenu(
                textElement: textToolState.menuText!,
                zoom: transform.zoom,
                canvasOffset: transform.offset,
                onEdit: _handleTextEdit,
                onDelete: _handleTextDelete,
                onStyle: _handleTextStyle,
                onDuplicate: _handleTextDuplicate,
                onMove: _handleTextMove,
              ),

            // ───────────────────────────────────────────────────────────
            // Text Input Overlay (OUTSIDE gesture handlers - screen coordinates)
            // ───────────────────────────────────────────────────────────
            if (textToolState.isEditing && textToolState.activeText != null)
              TextInputOverlay(
                textElement: textToolState.activeText!,
                zoom: transform.zoom,
                canvasOffset: transform.offset,
                onTextChanged: (updatedText) {
                  ref.read(textToolProvider.notifier).updateText(updatedText);
                },
                onEditingComplete: () => _finishTextEditing(),
                onCancel: () => _cancelTextEditing(),
              ),

            // ───────────────────────────────────────────────────────────
            // Text Style Popup (OUTSIDE gesture handlers - screen coordinates)
            // ───────────────────────────────────────────────────────────
            if (textToolState.showStylePopup && textToolState.styleText != null)
              TextStylePopup(
                textElement: textToolState.styleText!,
                zoom: transform.zoom,
                canvasOffset: transform.offset,
                onStyleChanged: _handleTextStyleChanged,
                onClose: () =>
                    ref.read(textToolProvider.notifier).hideStylePopup(),
              ),

            // ───────────────────────────────────────────────────────────
            // Text Move Mode Indicator
            // ───────────────────────────────────────────────────────────
            if (textToolState.isMoving)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Taşımak için bir yere dokunun',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => ref
                              .read(textToolProvider.notifier)
                              .cancelMoving(),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// GRID PAINTER
// =============================================================================

/// Paints a grid background for the canvas.
///
/// This painter is optimized to never repaint:
/// - Paint object is static and cached
/// - shouldRepaint always returns false
/// - Grid size is constant
class GridPainter extends CustomPainter {
  /// Grid spacing in logical pixels.
  static const double gridSize = 25.0;

  // CACHED Paint object - NO allocation in paint()!
  static final Paint _gridPaint = Paint()
    ..color = const Color(0xFFE0E0E0)
    ..strokeWidth = 0.5
    ..isAntiAlias = true;

  /// Creates a grid painter.
  const GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        _gridPaint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        _gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    // Grid never changes - NEVER repaint
    return false;
  }
}
