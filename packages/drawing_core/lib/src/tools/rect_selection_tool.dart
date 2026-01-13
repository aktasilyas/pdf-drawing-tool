import 'dart:math';
import 'package:drawing_core/drawing_core.dart';

/// Rectangle selection tool.
///
/// Allows users to draw a rectangle to select strokes.
/// A stroke is selected if its bounding box intersects with
/// the selection rectangle.
///
/// Supports inverted rectangles (right-to-left drag).
class RectSelectionTool implements SelectionTool {
  DrawingPoint? _startPoint;
  DrawingPoint? _endPoint;
  bool _isSelecting = false;

  @override
  SelectionType get selectionType => SelectionType.rectangle;

  @override
  void startSelection(DrawingPoint point) {
    _startPoint = point;
    _endPoint = point;
    _isSelecting = true;
  }

  @override
  void updateSelection(DrawingPoint point) {
    if (!_isSelecting) return;
    _endPoint = point;
  }

  @override
  Selection? endSelection(List<Stroke> strokes) {
    if (!_isSelecting || _startPoint == null || _endPoint == null) {
      cancelSelection();
      return null;
    }

    _isSelecting = false;

    // Calculate selection rectangle bounds (handles inverted rectangles)
    final selectionBounds = BoundingBox(
      left: min(_startPoint!.x, _endPoint!.x),
      top: min(_startPoint!.y, _endPoint!.y),
      right: max(_startPoint!.x, _endPoint!.x),
      bottom: max(_startPoint!.y, _endPoint!.y),
    );

    // Minimum size check - prevent accidental tiny selections
    if (selectionBounds.width < 5 || selectionBounds.height < 5) {
      _clear();
      return null;
    }

    // Find strokes that intersect with selection rectangle
    final selectedIds = _findStrokesInRect(strokes, selectionBounds);

    if (selectedIds.isEmpty) {
      _clear();
      return null;
    }

    // Calculate actual bounds of selected strokes
    final actualBounds = _calculateSelectionBounds(strokes, selectedIds);

    final selection = Selection.create(
      type: SelectionType.rectangle,
      selectedStrokeIds: selectedIds,
      bounds: actualBounds,
    );

    _clear();
    return selection;
  }

  @override
  void cancelSelection() {
    _clear();
  }

  void _clear() {
    _startPoint = null;
    _endPoint = null;
    _isSelecting = false;
  }

  @override
  bool get isSelecting => _isSelecting;

  @override
  List<DrawingPoint> get currentPath {
    if (_startPoint == null || _endPoint == null) return [];

    // Return rectangle as 4 corners + closing point
    return [
      DrawingPoint(x: _startPoint!.x, y: _startPoint!.y),
      DrawingPoint(x: _endPoint!.x, y: _startPoint!.y),
      DrawingPoint(x: _endPoint!.x, y: _endPoint!.y),
      DrawingPoint(x: _startPoint!.x, y: _endPoint!.y),
      DrawingPoint(x: _startPoint!.x, y: _startPoint!.y), // Close path
    ];
  }

  /// Current selection bounds for preview rendering.
  ///
  /// Returns null if no selection is in progress.
  BoundingBox? get currentBounds {
    if (_startPoint == null || _endPoint == null) return null;

    return BoundingBox(
      left: min(_startPoint!.x, _endPoint!.x),
      top: min(_startPoint!.y, _endPoint!.y),
      right: max(_startPoint!.x, _endPoint!.x),
      bottom: max(_startPoint!.y, _endPoint!.y),
    );
  }

  /// Finds all strokes whose bounds intersect with the selection rectangle.
  List<String> _findStrokesInRect(
    List<Stroke> strokes,
    BoundingBox selectionBounds,
  ) {
    return strokes
        .where((s) => _isStrokeInRect(s, selectionBounds))
        .map((s) => s.id)
        .toList();
  }

  /// Checks if a stroke's bounding box intersects with the rectangle.
  bool _isStrokeInRect(Stroke stroke, BoundingBox rect) {
    final bounds = stroke.bounds;
    if (bounds == null) return false;

    // AABB intersection test
    return bounds.left < rect.right &&
        bounds.right > rect.left &&
        bounds.top < rect.bottom &&
        bounds.bottom > rect.top;
  }

  /// Calculates the bounding box of selected strokes.
  BoundingBox _calculateSelectionBounds(
    List<Stroke> strokes,
    List<String> selectedIds,
  ) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      if (!selectedIds.contains(stroke.id)) continue;

      final bounds = stroke.bounds;
      if (bounds == null) continue;

      minX = min(minX, bounds.left);
      minY = min(minY, bounds.top);
      maxX = max(maxX, bounds.right);
      maxY = max(maxY, bounds.bottom);
    }

    // Handle case where no valid bounds found
    if (minX == double.infinity) {
      return BoundingBox.zero();
    }

    return BoundingBox(
      left: minX,
      top: minY,
      right: maxX,
      bottom: maxY,
    );
  }
}
