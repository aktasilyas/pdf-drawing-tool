import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';

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
  // POINTER EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────
  // NO setState here! Only DrawingController.notifyListeners() triggers repaint.

  /// Handles pointer down - starts a new stroke.
  void _handlePointerDown(PointerDownEvent event) {
    final point = _createDrawingPoint(event);
    final style = _getCurrentStyle();
    _drawingController.startStroke(point, style);
    _lastPoint = event.localPosition;
  }

  /// Handles pointer move - adds points to active stroke.
  void _handlePointerMove(PointerMoveEvent event) {
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

  /// Handles pointer up - finishes stroke and commits it.
  void _handlePointerUp(PointerUpEvent event) {
    final stroke = _drawingController.endStroke();
    if (stroke != null) {
      // Add stroke to document via provider
      ref.read(documentProvider.notifier).addStroke(stroke);
    }
    _lastPoint = null;
  }

  /// Handles pointer cancel - cancels the current stroke.
  void _handlePointerCancel(PointerCancelEvent event) {
    _drawingController.cancelStroke();
    _lastPoint = null;
  }

  /// Creates a DrawingPoint from a pointer event.
  DrawingPoint _createDrawingPoint(PointerEvent event) {
    return DrawingPoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      pressure: event.pressure.clamp(0.0, 1.0),
      tilt: 0.0,
      timestamp: event.timeStamp.inMilliseconds,
    );
  }

  /// Gets the current stroke style.
  /// Will be connected to provider in Step 9.
  StrokeStyle _getCurrentStyle() {
    // Default pen style - will be replaced with provider in Step 9
    return StrokeStyle.pen(
      color: 0xFF000000,
      thickness: 3.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider for committed strokes
    final strokes = ref.watch(activeLayerStrokesProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          widget.width == double.infinity ? constraints.maxWidth : widget.width,
          widget.height == double.infinity
              ? constraints.maxHeight
              : widget.height,
        );

        // Listener for raw pointer events (NOT GestureDetector)
        // This gives us direct access to pointer data for smooth drawing
        return Listener(
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          behavior: HitTestBehavior.opaque,
          child: ClipRect(
            child: Stack(
              children: [
                // ─────────────────────────────────────────────────────────────
                // LAYER 1: Background Grid
                // ─────────────────────────────────────────────────────────────
                // Never repaints - shouldRepaint always returns false
                RepaintBoundary(
                  child: CustomPaint(
                    size: size,
                    painter: const GridPainter(),
                    isComplex: false,
                    willChange: false,
                  ),
                ),

                // ─────────────────────────────────────────────────────────────
                // LAYER 2: Committed Strokes (from DocumentProvider)
                // ─────────────────────────────────────────────────────────────
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

                // ─────────────────────────────────────────────────────────────
                // LAYER 3: Active Stroke (Live Drawing)
                // ─────────────────────────────────────────────────────────────
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

                // ─────────────────────────────────────────────────────────────
                // LAYER 4: Selection Overlay (Phase 4)
                // ─────────────────────────────────────────────────────────────
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
