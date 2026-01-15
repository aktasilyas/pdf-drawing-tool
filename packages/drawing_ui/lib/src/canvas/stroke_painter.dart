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
    // Quick check: different stroke count means definitely repaint
    if (oldDelegate._strokeCount != _strokeCount) return true;

    // Quick check: different total point count means definitely repaint
    if (oldDelegate._totalPointCount != _totalPointCount) return true;

    // If counts are same, check if stroke objects actually changed
    // This handles move/transform operations where coordinates change
    // but counts stay the same
    if (!identical(oldDelegate.strokes, strokes)) {
      // Check if any stroke is different (using Equatable comparison)
      for (int i = 0; i < strokes.length; i++) {
        if (oldDelegate.strokes[i] != strokes[i]) {
          return true;
        }
      }
    }

    return false;
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
  final List<DrawingPoint> _rawPoints = []; // Raw points for smoothing
  StrokeStyle _activeStyle = StrokeStyle.pen();
  bool _isDrawing = false;
  double _stabilization = 0.0; // 0.0 = no smoothing, 1.0 = maximum smoothing
  bool _straightLineMode = false; // For highlighter straight line
  DrawingPoint? _firstPoint; // For straight line

  /// Unmodifiable view of current active points.
  List<DrawingPoint> get activePoints => List.unmodifiable(_activePoints);

  /// Current stroke style.
  StrokeStyle get activeStyle => _activeStyle;

  /// Whether a stroke is currently being drawn.
  bool get isDrawing => _isDrawing;

  /// Number of points in the current stroke.
  int get pointCount => _activePoints.length;

  /// Sets stabilization level (0.0 to 1.0).
  void setStabilization(double value) {
    _stabilization = value.clamp(0.0, 1.0);
  }

  /// Sets straight line mode for highlighter.
  void setStraightLineMode(bool enabled) {
    _straightLineMode = enabled;
  }

  /// Starts a new stroke at the given point with the given style.
  ///
  /// Clears any existing active points and begins a new stroke.
  void startStroke(DrawingPoint point, StrokeStyle style, {double stabilization = 0.0, bool straightLine = false}) {
    _activePoints.clear();
    _rawPoints.clear();
    _activePoints.add(point);
    _rawPoints.add(point);
    _firstPoint = point;
    _activeStyle = style;
    _isDrawing = true;
    _stabilization = stabilization;
    _straightLineMode = straightLine;
    notifyListeners();
  }

  /// Adds a point to the current stroke.
  ///
  /// Does nothing if no stroke is currently being drawn.
  /// This is called on every pointer move event.
  void addPoint(DrawingPoint point) {
    if (!_isDrawing) return;
    
    _rawPoints.add(point);

    if (_straightLineMode) {
      // Straight line mode: only use first and last point
      _activePoints.clear();
      _activePoints.add(_firstPoint!);
      _activePoints.add(point);
    } else if (_stabilization > 0.0) {
      // Apply smoothing
      final smoothedPoints = _applySmoothing(_rawPoints, _stabilization);
      _activePoints.clear();
      _activePoints.addAll(smoothedPoints);
    } else {
      // No processing
      _activePoints.add(point);
    }
    
    notifyListeners(); // Only ActiveStrokePainter will repaint
  }

  /// Applies Catmull-Rom smoothing to points.
  List<DrawingPoint> _applySmoothing(List<DrawingPoint> points, double factor) {
    if (points.length < 3) return List.from(points);

    final smoothed = <DrawingPoint>[];
    final windowSize = (3 + (factor * 5).round()).clamp(3, 8);
    
    for (int i = 0; i < points.length; i++) {
      if (i == 0 || i == points.length - 1) {
        // Keep first and last points unchanged
        smoothed.add(points[i]);
      } else {
        // Average with neighboring points
        final start = (i - windowSize ~/ 2).clamp(0, points.length - 1);
        final end = (i + windowSize ~/ 2 + 1).clamp(0, points.length);
        final window = points.sublist(start, end);
        
        double avgX = 0, avgY = 0, avgPressure = 0;
        for (final p in window) {
          avgX += p.x;
          avgY += p.y;
          avgPressure += p.pressure;
        }
        avgX /= window.length;
        avgY /= window.length;
        avgPressure /= window.length;
        
        // Blend with original based on factor
        final blendFactor = factor;
        smoothed.add(DrawingPoint(
          x: points[i].x * (1 - blendFactor) + avgX * blendFactor,
          y: points[i].y * (1 - blendFactor) + avgY * blendFactor,
          pressure: points[i].pressure * (1 - blendFactor) + avgPressure * blendFactor,
        ));
      }
    }
    
    return smoothed;
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
