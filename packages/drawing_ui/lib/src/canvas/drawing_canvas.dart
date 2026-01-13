import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/eraser_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/tool_style_provider.dart';
import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';

// =============================================================================
// DRAWING CANVAS WIDGET
// =============================================================================

/// The main drawing canvas widget that handles stroke rendering.
///
/// This widget uses a multi-layer architecture for optimal performance:
/// - Layer 1: Background grid (never repaints)
/// - Layer 2: Committed strokes (repaints only when strokes are added/removed)
/// - Layer 3: Active stroke (repaints on every pointer move)
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

  /// Creates a drawing canvas widget.
  const DrawingCanvas({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
  });

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

  /// Exposes the drawing controller for testing.
  @visibleForTesting
  DrawingController get drawingController => _drawingController;

  /// Exposes committed strokes from provider for testing.
  @visibleForTesting
  List<Stroke> get committedStrokes => ref.read(activeLayerStrokesProvider);

  /// Exposes last point for testing distance filtering.
  @visibleForTesting
  Offset? get lastPoint => _lastPoint;

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

  /// Handles pointer down - starts a new stroke or eraser action if single finger.
  void _handlePointerDown(PointerDownEvent event) {
    _pointerCount++;

    // Only handle with single finger
    if (_pointerCount != 1) return;

    // Check if eraser is active
    final isEraser = ref.read(isEraserToolProvider);
    if (isEraser) {
      _handleEraserDown(event);
      return;
    }

    // Drawing mode
    final point = _createDrawingPoint(event);
    final style = _getCurrentStyle();
    _drawingController.startStroke(point, style);
    _lastPoint = event.localPosition;
  }

  /// Handles pointer move - adds points to active stroke or erases if single finger.
  void _handlePointerMove(PointerMoveEvent event) {
    // Only handle with single finger
    if (_pointerCount != 1) return;

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

  /// Handles pointer up - finishes stroke or eraser action and commits it.
  void _handlePointerUp(PointerUpEvent event) {
    _pointerCount = (_pointerCount - 1).clamp(0, 10);

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

  /// Handles pointer cancel - cancels the current stroke or eraser action.
  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerCount = (_pointerCount - 1).clamp(0, 10);

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
  // ERASER EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────
  // Eraser uses command batching: single gesture = single undo command

  /// Handles eraser pointer down - starts eraser session.
  void _handleEraserDown(PointerDownEvent event) {
    final eraserTool = ref.read(eraserToolProvider);
    eraserTool.startErasing();
    _eraseAtPoint(event.localPosition);
  }

  /// Handles eraser pointer move - erases strokes along the path.
  void _handleEraserMove(PointerMoveEvent event) {
    _eraseAtPoint(event.localPosition);
  }

  /// Handles eraser pointer up - commits all erased strokes as single command.
  void _handleEraserUp(PointerUpEvent event) {
    final eraserTool = ref.read(eraserToolProvider);
    final erasedIds = eraserTool.endErasing();

    if (erasedIds.isNotEmpty) {
      // Single command for all erased strokes (batching)
      final document = ref.read(documentProvider);
      final command = EraseStrokesCommand(
        layerIndex: document.activeLayerIndex,
        strokeIds: erasedIds.toList(),
      );
      ref.read(historyManagerProvider.notifier).execute(command);
    }
  }

  /// Erases strokes at the given screen point.
  /// Transforms screen coordinates to canvas coordinates.
  void _eraseAtPoint(Offset point) {
    // Transform screen coordinates to canvas coordinates (zoom/pan)
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(point);

    final strokes = ref.read(activeLayerStrokesProvider);
    final eraserTool = ref.read(eraserToolProvider);

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
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCALE GESTURE HANDLERS (Two Finger Zoom/Pan)
  // ─────────────────────────────────────────────────────────────────────────

  /// Handles scale start - initializes zoom/pan gesture.
  void _handleScaleStart(ScaleStartDetails details) {
    // Only handle zoom/pan with 2+ fingers
    if (details.pointerCount < 2) return;
    
    // Cancel any ongoing drawing when zoom/pan starts
    if (_drawingController.isDrawing) {
      _drawingController.cancelStroke();
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
  DrawingPoint _createDrawingPoint(PointerEvent event) {
    final transform = ref.read(canvasTransformProvider);

    // Convert screen coordinates to canvas coordinates
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    return DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: event.pressure.clamp(0.0, 1.0),
      tilt: 0.0,
      timestamp: event.timeStamp.inMilliseconds,
    );
  }

  /// Gets the current stroke style.
  /// Will be connected to provider in Step 9.
  /// Gets the current stroke style from provider.
  StrokeStyle _getCurrentStyle() {
    // Get style from active tool provider
    return ref.read(activeStrokeStyleProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider for committed strokes
    final strokes = ref.watch(activeLayerStrokesProvider);
    // Check if current tool is a drawing tool
    final isDrawingTool = ref.watch(isDrawingToolProvider);
    // Watch canvas transform for zoom/pan
    final transform = ref.watch(canvasTransformProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          widget.width == double.infinity ? constraints.maxWidth : widget.width,
          widget.height == double.infinity
              ? constraints.maxHeight
              : widget.height,
        );

        // Listener first for raw pointer events (drawing)
        // GestureDetector inside for scale gesture (zoom/pan)
        return Listener(
          onPointerDown: isDrawingTool ? _handlePointerDown : null,
          onPointerMove: isDrawingTool ? _handlePointerMove : null,
          onPointerUp: isDrawingTool ? _handlePointerUp : null,
          onPointerCancel: isDrawingTool ? _handlePointerCancel : null,
          behavior: HitTestBehavior.translucent,
          child: GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            behavior: HitTestBehavior.opaque,
            child: ClipRect(
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
                    // LAYER 3: Active Stroke (Live Drawing)
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
                    // LAYER 4: Selection Overlay (Phase 4)
                    // ─────────────────────────────────────────────────────────
                    // Placeholder for future selection features
                    // RepaintBoundary(
                    //   child: CustomPaint(
                    //     size: size,
                    //     painter: SelectionOverlayPainter(),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
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
