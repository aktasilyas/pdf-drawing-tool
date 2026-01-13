import '../models/drawing_point.dart';
import '../models/stroke.dart';
import 'tool_type.dart';
import 'tool_settings.dart';

/// Callback for when a stroke is completed.
typedef StrokeCompletedCallback = void Function(Stroke stroke);

/// Callback for when the active stroke is updated.
typedef StrokeUpdatedCallback = void Function(Stroke stroke);

/// Callback for when strokes should be removed.
typedef StrokesRemovedCallback = void Function(List<String> strokeIds);

/// Abstract interface for all drawing tools.
///
/// Implement this interface to create custom drawing tools.
/// The tool receives pointer events and produces strokes or other
/// drawing operations.
///
/// ## Lifecycle
///
/// 1. [onActivated] - Called when tool becomes active
/// 2. [onPointerDown] - Called when touch/stylus starts
/// 3. [onPointerMove] - Called as touch/stylus moves
/// 4. [onPointerUp] - Called when touch/stylus ends
/// 5. [onPointerCancel] - Called if pointer is cancelled
/// 6. [onDeactivated] - Called when switching to another tool
///
/// ## Example Implementation
///
/// ```dart
/// class MyPenTool extends DrawingTool {
///   @override
///   ToolType get type => ToolType.ballpointPen;
///
///   @override
///   void onPointerDown(DrawingPoint point) {
///     _startNewStroke(point);
///   }
///
///   @override
///   void onPointerMove(DrawingPoint point) {
///     _addPointToStroke(point);
///     onStrokeUpdated?.call(_currentStroke);
///   }
///
///   @override
///   void onPointerUp() {
///     onStrokeCompleted?.call(_currentStroke);
///   }
/// }
/// ```
abstract class DrawingTool {
  /// The type of this tool.
  ToolType get type;

  /// The current settings for this tool.
  ToolSettings get settings;

  /// Updates the settings for this tool.
  set settings(ToolSettings value);

  /// Callback invoked when a stroke is completed.
  StrokeCompletedCallback? onStrokeCompleted;

  /// Callback invoked when the current stroke is updated.
  StrokeUpdatedCallback? onStrokeUpdated;

  /// Callback invoked when strokes should be removed (erasers).
  StrokesRemovedCallback? onStrokesRemoved;

  /// Called when this tool becomes the active tool.
  void onActivated() {}

  /// Called when this tool is no longer the active tool.
  void onDeactivated() {}

  /// Called when a pointer (touch/stylus) starts.
  ///
  /// This is the beginning of a potential stroke.
  void onPointerDown(DrawingPoint point);

  /// Called as the pointer moves.
  ///
  /// Add points to the current stroke here.
  void onPointerMove(DrawingPoint point);

  /// Called when the pointer is lifted.
  ///
  /// Finalize and commit the stroke here.
  void onPointerUp();

  /// Called if the pointer event is cancelled.
  ///
  /// Clean up any incomplete strokes here.
  void onPointerCancel() {
    // Default: treat as pointer up
    onPointerUp();
  }

  /// Returns the current in-progress stroke, if any.
  ///
  /// Used by the canvas to render the stroke being drawn.
  Stroke? get currentStroke;

  /// Resets the tool to its initial state.
  ///
  /// Called when starting a new document or clearing the canvas.
  void reset();

  /// Disposes of any resources held by this tool.
  void dispose() {}
}

/// Mixin that provides common stroke-building functionality.
///
/// Use this mixin to simplify implementing drawing tools that
/// create strokes from pointer input.
mixin StrokeBuilder on DrawingTool {
  /// The points collected for the current stroke.
  final List<DrawingPoint> _points = [];

  /// Whether we are currently building a stroke.
  bool get isDrawing => _points.isNotEmpty;

  /// Starts a new stroke with the given point.
  void startStroke(DrawingPoint point) {
    _points.clear();
    _points.add(point);
  }

  /// Adds a point to the current stroke.
  void addPoint(DrawingPoint point) {
    _points.add(point);
  }

  /// Clears the current stroke points.
  void clearPoints() {
    _points.clear();
  }

  /// Returns an unmodifiable view of the current points.
  List<DrawingPoint> get points => List.unmodifiable(_points);
}
