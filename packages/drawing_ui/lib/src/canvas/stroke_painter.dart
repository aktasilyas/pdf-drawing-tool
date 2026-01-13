import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';

// =============================================================================
// COMMITTED STROKES PAINTER
// =============================================================================

/// Renders committed (finished) strokes to the canvas.
///
/// This painter is optimized for performance:
/// - Only repaints when the stroke list actually changes
/// - Uses pre-computed stroke count and point count for fast comparison
/// - Shares a single [FlutterStrokeRenderer] instance
///
/// Use this for the "background" layer of completed strokes.
class CommittedStrokesPainter extends CustomPainter {
  /// The list of completed strokes to render.
  final List<Stroke> strokes;

  final FlutterStrokeRenderer _renderer;
  final int _strokeCount;
  final int _totalPointCount;

  /// Creates a painter for committed strokes.
  ///
  /// [strokes] - The list of completed strokes to render.
  /// [renderer] - Optional renderer instance for reuse.
  CommittedStrokesPainter({
    required this.strokes,
    FlutterStrokeRenderer? renderer,
  })  : _renderer = renderer ?? FlutterStrokeRenderer(),
        _strokeCount = strokes.length,
        _totalPointCount = strokes.fold(0, (sum, s) => sum + s.pointCount);

  @override
  void paint(Canvas canvas, Size size) {
    // Early exit for empty strokes - avoid unnecessary work
    if (strokes.isEmpty) return;

    _renderer.renderStrokes(canvas, strokes);
  }

  @override
  bool shouldRepaint(covariant CommittedStrokesPainter oldDelegate) {
    // Only repaint if stroke count or total point count changed
    // This is much faster than deep comparing stroke objects
    return oldDelegate._strokeCount != _strokeCount ||
        oldDelegate._totalPointCount != _totalPointCount;
  }
}

// =============================================================================
// ACTIVE STROKE PAINTER
// =============================================================================

/// Renders the currently active (being drawn) stroke.
///
/// This painter is called on every pointer move event, so it MUST be fast:
/// - No allocations in paint()
/// - Minimal shouldRepaint logic
/// - Uses cached point count for comparison
///
/// Use this for the "foreground" layer showing live drawing.
class ActiveStrokePainter extends CustomPainter {
  /// The points of the stroke being drawn.
  final List<DrawingPoint> points;

  /// The style to use for rendering.
  final StrokeStyle style;

  final FlutterStrokeRenderer _renderer;
  final int _pointCount;

  /// Creates a painter for the active stroke.
  ///
  /// [points] - Current points in the active stroke.
  /// [style] - The stroke style to render with.
  /// [renderer] - Optional renderer instance for reuse.
  ActiveStrokePainter({
    required this.points,
    required this.style,
    FlutterStrokeRenderer? renderer,
  })  : _renderer = renderer ?? FlutterStrokeRenderer(),
        _pointCount = points.length;

  @override
  void paint(Canvas canvas, Size size) {
    // Early exit - avoid any work for empty strokes
    if (points.isEmpty) return;

    _renderer.renderActiveStroke(canvas, points, style);
  }

  @override
  bool shouldRepaint(covariant ActiveStrokePainter oldDelegate) {
    // Repaint when:
    // 1. Point count changed (new point added)
    // 2. Style changed (user changed tool settings)
    return oldDelegate._pointCount != _pointCount ||
        oldDelegate.style != style;
  }
}

// =============================================================================
// DRAWING CONTROLLER
// =============================================================================

/// Controller for managing drawing state without using setState.
///
/// This controller uses [ChangeNotifier] to notify listeners of changes,
/// allowing [CustomPainter]s to repaint without rebuilding the widget tree.
///
/// ## Usage
/// ```dart
/// final controller = DrawingController();
///
/// // In gesture handler:
/// controller.startStroke(point, style);
/// controller.addPoint(point);
/// final stroke = controller.endStroke();
///
/// // In widget:
/// ListenableBuilder(
///   listenable: controller,
///   builder: (context, child) {
///     return CustomPaint(
///       painter: ActiveStrokePainter(
///         points: controller.activePoints,
///         style: controller.activeStyle,
///       ),
///     );
///   },
/// )
/// ```
class DrawingController extends ChangeNotifier {
  final List<DrawingPoint> _activePoints = [];
  StrokeStyle _activeStyle = StrokeStyle.pen();
  bool _isDrawing = false;

  /// Unmodifiable view of current active points.
  List<DrawingPoint> get activePoints => List.unmodifiable(_activePoints);

  /// Current stroke style.
  StrokeStyle get activeStyle => _activeStyle;

  /// Whether a stroke is currently being drawn.
  bool get isDrawing => _isDrawing;

  /// Number of points in the current stroke.
  int get pointCount => _activePoints.length;

  /// Starts a new stroke at the given point with the given style.
  ///
  /// Clears any existing active points and begins a new stroke.
  void startStroke(DrawingPoint point, StrokeStyle style) {
    _activePoints.clear();
    _activePoints.add(point);
    _activeStyle = style;
    _isDrawing = true;
    notifyListeners();
  }

  /// Adds a point to the current stroke.
  ///
  /// Does nothing if no stroke is currently being drawn.
  /// This is called on every pointer move event.
  void addPoint(DrawingPoint point) {
    if (!_isDrawing) return;
    _activePoints.add(point);
    notifyListeners(); // Only ActiveStrokePainter will repaint
  }

  /// Ends the current stroke and returns the completed [Stroke].
  ///
  /// Returns null if no stroke is being drawn or if there are no points.
  /// Clears the active points after creating the stroke.
  Stroke? endStroke() {
    if (!_isDrawing || _activePoints.isEmpty) {
      _isDrawing = false;
      return null;
    }

    final stroke = Stroke.create(
      points: List.from(_activePoints),
      style: _activeStyle,
    );

    _activePoints.clear();
    _isDrawing = false;
    notifyListeners();

    return stroke;
  }

  /// Cancels the current stroke without creating a [Stroke].
  ///
  /// Clears all active points and resets drawing state.
  void cancelStroke() {
    _activePoints.clear();
    _isDrawing = false;
    notifyListeners();
  }

  /// Updates the active stroke style.
  ///
  /// This affects the current stroke being drawn.
  void updateStyle(StrokeStyle style) {
    _activeStyle = style;
    notifyListeners();
  }

  /// Clears all state and resets the controller.
  void reset() {
    _activePoints.clear();
    _activeStyle = StrokeStyle.pen();
    _isDrawing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _activePoints.clear();
    super.dispose();
  }
}
