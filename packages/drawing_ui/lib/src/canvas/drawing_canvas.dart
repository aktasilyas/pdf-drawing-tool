import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/canvas/selection_painter.dart';
import 'package:drawing_ui/src/canvas/shape_painter.dart';
import 'package:drawing_ui/src/canvas/text_painter.dart';
import 'package:drawing_ui/src/canvas/pixel_eraser_preview_painter.dart';
import 'package:drawing_ui/src/canvas/page_background_painter.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas_helpers.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/eraser_provider.dart';
import 'package:drawing_ui/src/providers/tool_style_provider.dart';
import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';
import 'package:drawing_ui/src/providers/selection_provider.dart';
import 'package:drawing_ui/src/providers/shape_provider.dart';
import 'package:drawing_ui/src/providers/text_provider.dart';
import 'package:drawing_ui/src/providers/page_provider.dart';
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
  final double height;

  /// Canvas mode configuration (determines behavior)
  final core.CanvasMode? canvasMode;

  const DrawingCanvas({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.canvasMode,
  });

  @override
  ConsumerState<DrawingCanvas> createState() => DrawingCanvasState();
}

/// State for [DrawingCanvas].
///
/// Exposed as public for testing purposes.
/// Uses mixins for gesture handling and helpers to keep file size manageable.
class DrawingCanvasState extends ConsumerState<DrawingCanvas>
    with DrawingCanvasHelpers, DrawingCanvasGestureHandlers {
  /// Canvas mode configuration (for gesture handlers)
  @override
  core.CanvasMode? get canvasMode => widget.canvasMode;

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

  // ─────────────────────────────────────────────────────────────────────────
  // PIXEL ERASER TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Accumulated segment hits for pixel eraser during a gesture.
  final Map<String, List<int>> _pixelEraseHits = {};

  /// Original strokes affected by pixel eraser (for undo).
  final List<core.Stroke> _pixelEraseOriginalStrokes = [];

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALIZATION TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  /// Whether canvas has been initialized for limited mode.
  bool _hasInitialized = false;

  /// Last viewport size for detecting orientation changes.
  Size? _lastViewportSize;

  // ─────────────────────────────────────────────────────────────────────────
  // Public Getters/Setters (for mixins and testing)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  @visibleForTesting
  DrawingController get drawingController => _drawingController;

  /// Exposes committed strokes from provider for testing.
  @visibleForTesting
  List<core.Stroke> get committedStrokes =>
      ref.read(activeLayerStrokesProvider);

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

  /// Initialize canvas transform for limited mode (page centering).
  void _initializeCanvasForLimitedMode(
      Size viewportSize, core.Page currentPage) {
    final canvasMode =
        widget.canvasMode ?? const core.CanvasMode(isInfinite: true);
    if (canvasMode.isInfinite) {
      _hasInitialized = true;
      _lastViewportSize = viewportSize;
      return;
    }

    // Check if viewport size changed significantly (orientation change)
    final needsReInit = !_hasInitialized || _isOrientationChanged(viewportSize);
    if (!needsReInit) return;

    // Mark as initialized immediately to prevent multiple calls
    _hasInitialized = true;
    _lastViewportSize = viewportSize;

    // Use post-frame callback to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(canvasTransformProvider.notifier).initializeForPage(
            viewportSize: viewportSize,
            pageSize: Size(currentPage.size.width, currentPage.size.height),
          );
    });
  }

  /// Check if orientation changed (width/height swapped).
  bool _isOrientationChanged(Size newSize) {
    if (_lastViewportSize == null) return false;

    final wasPortrait = _lastViewportSize!.height > _lastViewportSize!.width;
    final isPortrait = newSize.height > newSize.width;

    return wasPortrait != isPortrait;
  }

  @override
  int get pointerCount => _pointerCount;
  @override
  set pointerCount(int value) => _pointerCount = value;

  @override
  Offset? get lastPoint => _lastPoint;
  @override
  set lastPoint(Offset? value) => _lastPoint = value;

  @override
  bool get isSelecting => _isSelecting;
  @override
  set isSelecting(bool value) => _isSelecting = value;

  @override
  bool get isDrawingShape => _isDrawingShape;
  @override
  set isDrawingShape(bool value) => _isDrawingShape = value;

  @override
  core.ShapeTool? get activeShapeTool => _activeShapeTool;
  @override
  set activeShapeTool(core.ShapeTool? value) => _activeShapeTool = value;

  @override
  bool get isStraightLineDrawing => _isStraightLineDrawing;
  @override
  set isStraightLineDrawing(bool value) => _isStraightLineDrawing = value;

  @override
  core.DrawingPoint? get straightLineStart => _straightLineStart;
  @override
  set straightLineStart(core.DrawingPoint? value) => _straightLineStart = value;

  @override
  core.DrawingPoint? get straightLineEnd => _straightLineEnd;
  @override
  set straightLineEnd(core.DrawingPoint? value) => _straightLineEnd = value;

  @override
  core.StrokeStyle? get straightLineStyle => _straightLineStyle;
  @override
  set straightLineStyle(core.StrokeStyle? value) => _straightLineStyle = value;

  @override
  Set<String> get erasedShapeIds => _erasedShapeIds;

  @override
  Set<String> get erasedTextIds => _erasedTextIds;

  @override
  Map<String, List<int>> get pixelEraseHits => _pixelEraseHits;

  @override
  List<core.Stroke> get pixelEraseOriginalStrokes => _pixelEraseOriginalStrokes;

  @override
  Offset? get lastFocalPoint => _lastFocalPoint;
  @override
  set lastFocalPoint(Offset? value) => _lastFocalPoint = value;

  @override
  double? get lastScale => _lastScale;
  @override
  set lastScale(double? value) => _lastScale = value;

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

    // Canvas mode configuration
    final canvasMode =
        widget.canvasMode ?? const core.CanvasMode(isInfinite: true);

    // Current page (LIMITED mod için)
    final currentPage = ref.watch(currentPageProvider);

    // Eraser cursor state
    final eraserCursorPosition = ref.watch(eraserCursorPositionProvider);
    final lassoEraserPoints = ref.watch(lassoEraserPointsProvider);
    final isEraserTool = ref.watch(isEraserToolProvider);
    final pixelEraserPreview = ref.watch(pixelEraserPreviewProvider);

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
    if (_isStraightLineDrawing &&
        _straightLineStart != null &&
        _straightLineEnd != null) {
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

        // Initialize canvas for limited mode (centers page on first render)
        if (!canvasMode.isInfinite) {
          _initializeCanvasForLimitedMode(size, currentPage);
        }

        // Wrap everything in a Stack to put menu/overlay OUTSIDE gesture handlers
        return Stack(
          children: [
            // ═══════════════════════════════════════════════════════════════════
            // LAYER -1: Surrounding Area Background (OUTSIDE Transform)
            // ═══════════════════════════════════════════════════════════════════
            // This fills the entire viewport with surrounding color.
            // Being OUTSIDE Transform means it doesn't move with zoom/pan.
            if (!canvasMode.isInfinite)
              Positioned.fill(
                child: ColoredBox(
                  color: Color(canvasMode.surroundingAreaColor),
                ),
              ),

            // Canvas with gesture handlers
            Listener(
              onPointerDown: enablePointerEvents ? handlePointerDown : null,
              onPointerMove: enablePointerEvents ? handlePointerMove : null,
              onPointerUp: enablePointerEvents ? handlePointerUp : null,
              onPointerCancel: enablePointerEvents ? handlePointerCancel : null,
              behavior: HitTestBehavior.translucent,
              child: GestureDetector(
                onScaleStart: handleScaleStart,
                onScaleUpdate: handleScaleUpdate,
                onScaleEnd: handleScaleEnd,
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
                        clipBehavior: Clip.none, // Allow content outside bounds
                        children: [
                          // ═══════════════════════════════════════════════════════════
                          // LAYER 0: Page Container (LIMITED mod için)
                          // ═══════════════════════════════════════════════════════════
                          if (!canvasMode.isInfinite) ...[
                            // Sayfa gölgesi
                            if (canvasMode.showPageShadow)
                              Positioned(
                                left: 0,
                                top: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    width: currentPage.size.width,
                                    height: currentPage.size.height,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Sayfa arka planı + pattern
                            Positioned(
                              left: 0,
                              top: 0,
                              child: IgnorePointer(
                                child: Container(
                                  width: currentPage.size.width,
                                  height: currentPage.size.height,
                                  decoration: BoxDecoration(
                                    color: Color(currentPage.background.color),
                                    border: canvasMode.pageBorderWidth > 0
                                        ? Border.all(
                                            color: Color(
                                                canvasMode.pageBorderColor),
                                            width: canvasMode.pageBorderWidth,
                                          )
                                        : null,
                                  ),
                                  child: CustomPaint(
                                    painter: PageBackgroundPatternPainter(
                                      background: currentPage.background,
                                    ),
                                    size: Size(currentPage.size.width,
                                        currentPage.size.height),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // ─────────────────────────────────────────────────────────
                          // LAYER 1: Committed Strokes (from DocumentProvider)
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
                          // LAYER 2: Committed Shapes + Preview Shape
                          // ─────────────────────────────────────────────────────────
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
                          // LAYER 3: Committed Texts + Active Text
                          // ─────────────────────────────────────────────────────────
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
                          // LAYER 4: Active Stroke (Live Drawing)
                          // ─────────────────────────────────────────────────────────
                          // Uses ListenableBuilder to listen to DrawingController
                          // for optimal performance during drawing
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
                          // LAYER 5: Straight Line Preview (for highlighter)
                          // ─────────────────────────────────────────────────────────
                          if (straightLinePreviewPoints != null &&
                              straightLinePreviewStyle != null)
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
                          // Selection path and bounding box
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
                          // LAYER 7: Pixel Eraser Preview
                          // ─────────────────────────────────────────────────────────
                          if (pixelEraserPreview.isNotEmpty)
                            RepaintBoundary(
                              child: CustomPaint(
                                size: size,
                                painter: PixelEraserPreviewPainter(
                                  strokes: strokes,
                                  affectedSegments: pixelEraserPreview,
                                ),
                                isComplex: false,
                                willChange: true,
                              ),
                            ),

                          // ─────────────────────────────────────────────────────────
                          // LAYER 8: Selection Handles (for drag interactions)
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

            // ───────────────────────────────────────────────────────────────────
            // Text Context Menu (must be outside gesture handlers, uses screen coordinates)
            // ───────────────────────────────────────────────────────────────────
            if (textToolState.showMenu && textToolState.menuText != null)
              TextContextMenu(
                textElement: textToolState.menuText!,
                zoom: transform.zoom,
                canvasOffset: transform.offset,
                onEdit: handleTextEdit,
                onDelete: handleTextDelete,
                onStyle: handleTextStyle,
                onDuplicate: handleTextDuplicate,
                onMove: handleTextMove,
              ),

            // ───────────────────────────────────────────────────────────────────
            // Text Input Overlay (must be outside gesture handlers)
            // ───────────────────────────────────────────────────────────────────
            if (textToolState.isEditing && textToolState.activeText != null)
              TextInputOverlay(
                textElement: textToolState.activeText!,
                zoom: transform.zoom,
                canvasOffset: transform.offset,
                onTextChanged: (updatedText) {
                  ref.read(textToolProvider.notifier).updateText(updatedText);
                },
                onEditingComplete: () => finishTextEditing(),
                onCancel: () => cancelTextEditing(),
              ),

            // ───────────────────────────────────────────────────────────────────
            // Text Style Popup (must be outside gesture handlers)
            // ───────────────────────────────────────────────────────────────────
            if (textToolState.showStylePopup && textToolState.styleText != null)
              TextStylePopup(
                textElement: textToolState.styleText!,
                zoom: transform.zoom,
                canvasOffset: transform.offset,
                onStyleChanged: handleTextStyleChanged,
                onClose: () =>
                    ref.read(textToolProvider.notifier).hideStylePopup(),
              ),

            // ───────────────────────────────────────────────────────────────────
            // Text Move Mode Indicator
            // ───────────────────────────────────────────────────────────────────
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
                          color: Colors.black.withOpacity(0.2),
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
                              color: Colors.white.withOpacity(0.2),
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

            // ───────────────────────────────────────────────────────────────────
            // Eraser Cursor Overlay (using screen coordinates)
            // ───────────────────────────────────────────────────────────────────
            if (isEraserTool)
              EraserCursorWidget(
                cursorPosition: eraserCursorPosition ?? Offset.zero,
                isVisible: eraserCursorPosition != null,
                lassoPoints: lassoEraserPoints,
              ),
          ],
        );
      },
    );
  }
}
