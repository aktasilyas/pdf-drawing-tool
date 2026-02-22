import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';

/// In-memory clipboard data for selection copy/cut operations.
class SelectionClipboardData {
  /// Copied strokes.
  final List<Stroke> strokes;

  /// Copied shapes.
  final List<Shape> shapes;

  /// Original bounding box of the copied selection.
  final BoundingBox originalBounds;

  const SelectionClipboardData({
    required this.strokes,
    required this.shapes,
    required this.originalBounds,
  });
}

/// Provider for in-memory selection clipboard.
final selectionClipboardProvider = StateProvider<SelectionClipboardData?>((ref) {
  return null;
});
