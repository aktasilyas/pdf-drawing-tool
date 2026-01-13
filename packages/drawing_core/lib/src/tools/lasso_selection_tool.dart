import 'dart:math';
import 'package:drawing_core/drawing_core.dart';

/// Lasso (free-form) selection tool.
///
/// Allows users to draw a free-form path to select strokes.
/// Uses ray casting algorithm for point-in-polygon testing.
///
/// A stroke is considered selected if any of its points
/// fall within the lasso polygon.
class LassoSelectionTool implements SelectionTool {
  final List<DrawingPoint> _path = [];
  bool _isSelecting = false;

  @override
  SelectionType get selectionType => SelectionType.lasso;

  @override
  void startSelection(DrawingPoint point) {
    _path.clear();
    _path.add(point);
    _isSelecting = true;
  }

  @override
  void updateSelection(DrawingPoint point) {
    if (!_isSelecting) return;
    _path.add(point);
  }

  @override
  Selection? endSelection(List<Stroke> strokes) {
    if (!_isSelecting || _path.length < 3) {
      cancelSelection();
      return null;
    }

    _isSelecting = false;

    // Close the path by adding first point at end
    final closedPath = List<DrawingPoint>.from(_path);
    if (closedPath.isNotEmpty && closedPath.first != closedPath.last) {
      closedPath.add(closedPath.first);
    }

    // Find strokes inside the lasso
    final selectedIds = _findStrokesInLasso(strokes, closedPath);

    if (selectedIds.isEmpty) {
      _path.clear();
      return null;
    }

    // Calculate bounds of selected strokes
    final bounds = _calculateSelectionBounds(strokes, selectedIds);

    final selection = Selection.create(
      type: SelectionType.lasso,
      selectedStrokeIds: selectedIds,
      bounds: bounds,
      lassoPath: closedPath,
    );

    _path.clear();
    return selection;
  }

  @override
  void cancelSelection() {
    _path.clear();
    _isSelecting = false;
  }

  @override
  bool get isSelecting => _isSelecting;

  @override
  List<DrawingPoint> get currentPath => List.unmodifiable(_path);

  /// Finds all strokes that have at least one point inside the lasso.
  List<String> _findStrokesInLasso(
    List<Stroke> strokes,
    List<DrawingPoint> polygon,
  ) {
    final selectedIds = <String>[];

    for (final stroke in strokes) {
      if (_isStrokeInLasso(stroke, polygon)) {
        selectedIds.add(stroke.id);
      }
    }

    return selectedIds;
  }

  /// Checks if a stroke has any point inside the lasso polygon.
  bool _isStrokeInLasso(Stroke stroke, List<DrawingPoint> polygon) {
    for (final point in stroke.points) {
      if (_isPointInPolygon(point.x, point.y, polygon)) {
        return true;
      }
    }
    return false;
  }

  /// Ray casting algorithm for point-in-polygon test.
  ///
  /// Casts a ray from the point to infinity and counts
  /// how many times it crosses the polygon edges.
  /// If odd, the point is inside; if even, outside.
  bool _isPointInPolygon(double x, double y, List<DrawingPoint> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].x;
      final yi = polygon[i].y;
      final xj = polygon[j].x;
      final yj = polygon[j].y;

      // Check if the ray crosses this edge
      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }

      j = i;
    }

    return inside;
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
