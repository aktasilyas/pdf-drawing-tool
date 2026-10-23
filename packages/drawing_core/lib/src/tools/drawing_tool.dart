import 'package:drawing_core/src/internal.dart';

/// Abstract base class for all drawing tools.
///
/// A [DrawingTool] handles pointer events and creates [Stroke]s.
/// The tool maintains internal state for the current drawing operation.
///
/// Subclasses can override [createStroke] to customize stroke creation.
abstract class DrawingTool {
  /// The current style for strokes created by this tool.
  StrokeStyle _style;

  /// The points collected during the current drawing operation.
  final List<DrawingPoint> _currentPoints = [];

  /// Whether a drawing operation is currently in progress.
  bool _isDrawing = false;

  /// Optional input stabilization (One Euro filter + resampling).
  /// Null disables it and raw points are recorded.
  final StrokeInputFilter? _inputFilter;

  /// Creates a new [DrawingTool] with the given style.
  ///
  /// Pass [inputFilter] to stabilize and resample incoming points.
  DrawingTool(StrokeStyle style, {StrokeInputFilterConfig? inputFilter})
      : _style = style,
        _inputFilter =
            inputFilter == null ? null : StrokeInputFilter(inputFilter);

  /// Whether a drawing operation is currently in progress.
  bool get isDrawing => _isDrawing;

  /// The current style for strokes created by this tool.
  StrokeStyle get style => _style;

  /// The points collected during the current drawing operation.
  ///
  /// Returns an unmodifiable copy to prevent external modification.
  List<DrawingPoint> get currentPoints => List.unmodifiable(_currentPoints);

  /// The number of points in the current drawing operation.
  int get currentPointCount => _currentPoints.length;

  /// Called when the pointer goes down (touch start / mouse down).
  ///
  /// Starts a new drawing operation and records the first point.
  void onPointerDown(DrawingPoint point) {
    _isDrawing = true;
    _currentPoints.clear();
    _currentPoints.add(_inputFilter?.begin(point) ?? point);
  }

  /// Called when the pointer moves (touch move / mouse move).
  ///
  /// Records additional points if a drawing operation is in progress.
  void onPointerMove(DrawingPoint point) {
    if (_isDrawing) {
      final filter = _inputFilter;
      if (filter == null) {
        _currentPoints.add(point);
      } else {
        _currentPoints.addAll(filter.add(point));
      }
    }
  }

  /// Called when the pointer goes up (touch end / mouse up).
  ///
  /// Finishes the current drawing operation and returns the completed stroke.
  /// Returns null if no drawing operation was in progress or if there are
  /// insufficient points.
  Stroke? onPointerUp() {
    if (!_isDrawing) {
      return null;
    }

    _isDrawing = false;

    final tail = _inputFilter?.end();
    if (tail != null) _currentPoints.add(tail);

    if (_currentPoints.isEmpty) {
      return null;
    }

    // Create a copy of points for the stroke
    final points = List<DrawingPoint>.from(_currentPoints);
    _currentPoints.clear();

    return createStroke(points, _style);
  }

  /// Updates the style for future strokes.
  ///
  /// This does not affect any stroke currently being drawn.
  void updateStyle(StrokeStyle newStyle) {
    _style = newStyle;
  }

  /// Cancels the current drawing operation.
  ///
  /// Clears all collected points and resets the drawing state.
  void cancel() {
    _currentPoints.clear();
    _isDrawing = false;
  }

  /// Creates a stroke from the given points and style.
  ///
  /// Subclasses can override this method to customize stroke creation,
  /// such as applying smoothing or pressure processing.
  Stroke createStroke(List<DrawingPoint> points, StrokeStyle style);
}
