import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';

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

  /// Committed strokes list.
  /// Will be connected to DocumentProvider in Step 7.
  final List<Stroke> _committedStrokes = [];

  /// Exposes the drawing controller for testing.
  @visibleForTesting
  DrawingController get drawingController => _drawingController;

  /// Exposes committed strokes for testing.
  @visibleForTesting
  List<Stroke> get committedStrokes => _committedStrokes;

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          widget.width == double.infinity ? constraints.maxWidth : widget.width,
          widget.height == double.infinity
              ? constraints.maxHeight
              : widget.height,
        );

        return ClipRect(
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
              // LAYER 2: Committed Strokes
              // ─────────────────────────────────────────────────────────────
              // Only repaints when stroke count changes
              RepaintBoundary(
                child: ListenableBuilder(
                  listenable: _drawingController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: size,
                      painter: CommittedStrokesPainter(
                        strokes: _committedStrokes,
                        renderer: _renderer,
                      ),
                      isComplex: true,
                      willChange: false,
                    );
                  },
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
