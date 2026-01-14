import 'dart:math';
import 'package:drawing_core/drawing_core.dart';

/// Lasso (free-form) selection tool.
///
/// Allows users to draw a free-form path to select strokes and shapes.
/// Uses ray casting algorithm for point-in-polygon testing.
///
/// A stroke is considered selected if any of its points
/// fall within the lasso polygon.
/// A shape is considered selected if its center point
/// falls within the lasso polygon.
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
  Selection? endSelection(List<Stroke> strokes, [List<Shape> shapes = const []]) {
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
    final selectedStrokeIds = _findStrokesInLasso(strokes, closedPath);

    // Find shapes inside the lasso
    final selectedShapeIds = _findShapesInLasso(shapes, closedPath);

    if (selectedStrokeIds.isEmpty && selectedShapeIds.isEmpty) {
      _path.clear();
      return null;
    }

    // Calculate bounds of selected items
    final bounds = _calculateSelectionBounds(
      strokes,
      selectedStrokeIds,
      shapes,
      selectedShapeIds,
    );

    final selection = Selection.create(
      type: SelectionType.lasso,
      selectedStrokeIds: selectedStrokeIds,
      selectedShapeIds: selectedShapeIds,
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

  /// Finds all shapes that have their center inside the lasso.
  List<String> _findShapesInLasso(
    List<Shape> shapes,
    List<DrawingPoint> polygon,
  ) {
    final selectedIds = <String>[];

    for (final shape in shapes) {
      if (_isShapeInLasso(shape, polygon)) {
        selectedIds.add(shape.id);
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

  /// Checks if a shape's center is inside the lasso polygon.
  bool _isShapeInLasso(Shape shape, List<DrawingPoint> polygon) {
    // Check center point
    if (_isPointInPolygon(shape.centerX, shape.centerY, polygon)) {
      return true;
    }
    // Also check start and end points for lines/arrows
    if (shape.type == ShapeType.line || shape.type == ShapeType.arrow) {
      if (_isPointInPolygon(shape.startPoint.x, shape.startPoint.y, polygon) ||
          _isPointInPolygon(shape.endPoint.x, shape.endPoint.y, polygon)) {
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

  /// Calculates the bounding box of selected strokes and shapes.
  BoundingBox _calculateSelectionBounds(
    List<Stroke> strokes,
    List<String> selectedStrokeIds,
    List<Shape> shapes,
    List<String> selectedShapeIds,
  ) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    // Add stroke bounds
    for (final stroke in strokes) {
      if (!selectedStrokeIds.contains(stroke.id)) continue;

      final bounds = stroke.bounds;
      if (bounds == null) continue;

      minX = min(minX, bounds.left);
      minY = min(minY, bounds.top);
      maxX = max(maxX, bounds.right);
      maxY = max(maxY, bounds.bottom);
    }

    // Add shape bounds
    for (final shape in shapes) {
      if (!selectedShapeIds.contains(shape.id)) continue;

      final bounds = shape.bounds;
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
