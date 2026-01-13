import 'package:drawing_core/drawing_core.dart';

/// Abstract interface for selection tools.
///
/// Selection tools allow users to select strokes on the canvas
/// using different selection modes (lasso, rectangle).
///
/// Implementations:
/// - [LassoSelectionTool] - Free-form selection
/// - [RectangleSelectionTool] - Box selection (future)
abstract class SelectionTool {
  /// Starts a new selection at the given point.
  ///
  /// This should be called on pointer down.
  void startSelection(DrawingPoint point);

  /// Updates the selection with a new point.
  ///
  /// This should be called on pointer move.
  void updateSelection(DrawingPoint point);

  /// Completes the selection and returns the result.
  ///
  /// [strokes] - The list of strokes to check for selection.
  ///
  /// Returns a [Selection] containing the selected strokes,
  /// or null if the selection is invalid or empty.
  Selection? endSelection(List<Stroke> strokes);

  /// Cancels the current selection.
  ///
  /// This clears any temporary selection state.
  void cancelSelection();

  /// Whether a selection is currently in progress.
  bool get isSelecting;

  /// The current selection path points (for preview rendering).
  ///
  /// This is used to draw the selection outline while the user
  /// is creating the selection.
  List<DrawingPoint> get currentPath;

  /// The type of selection this tool creates.
  SelectionType get selectionType;
}
