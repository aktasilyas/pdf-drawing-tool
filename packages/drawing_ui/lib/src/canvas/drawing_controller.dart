import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter/foundation.dart';

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
  /// Creates a controller.
  ///
  /// [inputFilter] tunes the One Euro + resampling input stage applied to
  /// every stroke; pass null to disable it (raw points, legacy smoothing).
  DrawingController({this.inputFilter = const StrokeInputFilterConfig()});

  /// Input filter tuning, or null when filtering is disabled.
  final StrokeInputFilterConfig? inputFilter;

  StrokeInputFilter? _filter;

  /// Incrementally maintained geometry of the live stroke; drawn by
  /// `LiveStrokePainter`.
  final ActiveStrokeGeometry geometry = ActiveStrokeGeometry();
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
  void startStroke(DrawingPoint point, StrokeStyle style,
      {double stabilization = 0.0, bool straightLine = false}) {
    _activePoints.clear();
    _rawPoints.clear();
    _firstPoint = point;
    _activeStyle = style;
    _isDrawing = true;
    _stabilization = stabilization;
    _straightLineMode = straightLine;
    final config = inputFilter;
    if (config != null && !straightLine) {
      // Stabilization lowers the cutoff instead of stacking a second smoother.
      _filter = StrokeInputFilter(StrokeInputFilterConfig(
        minCutoff: config.minCutoff / (1 + 4 * stabilization.clamp(0.0, 1.0)),
        beta: config.beta,
        spacing: config.spacing,
        pressureCutoff: config.pressureCutoff,
        fallbackDt: config.fallbackDt,
      ));
      _activePoints.add(_filter!.begin(point));
    } else {
      _filter = null;
      _activePoints.add(point);
    }
    _rawPoints.add(point);
    geometry.begin(style, incremental: _filter != null);
    geometry.sync(_activePoints);
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
    } else if (_filter != null) {
      _activePoints.addAll(_filter!.add(point));
    } else if (_stabilization > 0.0) {
      // Apply smoothing
      final smoothedPoints = _applySmoothing(_rawPoints, _stabilization);
      _activePoints.clear();
      _activePoints.addAll(smoothedPoints);
    } else {
      // No processing
      _activePoints.add(point);
    }

    geometry.sync(_activePoints);
    notifyListeners(); // Only the live stroke painter will repaint
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
          pressure: points[i].pressure * (1 - blendFactor) +
              avgPressure * blendFactor,
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

    final tail = _filter?.end();
    if (tail != null) _activePoints.add(tail);
    _filter = null;

    final stroke = Stroke.create(
      points: List.from(_activePoints),
      style: _activeStyle,
    );

    _activePoints.clear();
    _isDrawing = false;
    geometry.clear();
    notifyListeners();

    return stroke;
  }

  /// Cancels the current stroke without creating a [Stroke].
  ///
  /// Clears all active points and resets drawing state.
  void cancelStroke() {
    _filter = null;
    _activePoints.clear();
    _isDrawing = false;
    geometry.clear();
    notifyListeners();
  }

  /// Updates the active stroke style.
  ///
  /// This affects the current stroke being drawn.
  void updateStyle(StrokeStyle style) {
    _activeStyle = style;
    if (_isDrawing) {
      geometry.begin(style, incremental: _filter != null);
      geometry.sync(_activePoints);
    }
    notifyListeners();
  }

  /// Clears all state and resets the controller.
  void reset() {
    _filter = null;
    _rawPoints.clear();
    _activePoints.clear();
    _activeStyle = StrokeStyle.pen();
    _isDrawing = false;
    geometry.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _activePoints.clear();
    geometry.dispose();
    super.dispose();
  }
}
