import 'dart:math';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_core/src/tools/lasso_geometry.dart';

/// Lasso (free-form) selection tool.
///
/// Draw a free-form path to select strokes and shapes.
/// Point-in-polygon maths lives in `LassoGeometry`.
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
  Selection? endSelection(
    List<Stroke> strokes, [
    List<Shape> shapes = const [],
    List<ImageElement> images = const [],
    List<TextElement> texts = const [],
  ]) {
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

    // Minimum size check - prevent accidental tiny selections (e.g. taps)
    final pathBounds = LassoGeometry.pathBounds(closedPath);
    if (pathBounds.width < 20 || pathBounds.height < 20) {
      _path.clear();
      return null;
    }

    // Find strokes inside the lasso
    final selectedStrokeIds = _findStrokesInLasso(strokes, closedPath);

    // Find shapes inside the lasso
    final selectedShapeIds = _findShapesInLasso(shapes, closedPath);

    // Find images inside the lasso
    final selectedImageIds = _findImagesInLasso(images, closedPath);

    // Find texts inside the lasso
    final selectedTextIds = _findTextsInLasso(texts, closedPath);

    final bool hasSelectedItems = selectedStrokeIds.isNotEmpty ||
        selectedShapeIds.isNotEmpty ||
        selectedImageIds.isNotEmpty ||
        selectedTextIds.isNotEmpty;

    // Use actual bounds of selected items, or the lasso path bounds for empty selections
    final bounds = hasSelectedItems
        ? _calculateSelectionBounds(
            strokes,
            selectedStrokeIds,
            shapes,
            selectedShapeIds,
            images,
            selectedImageIds,
            texts,
            selectedTextIds,
          )
        : LassoGeometry.pathBounds(closedPath);

    final selection = Selection.create(
      type: SelectionType.lasso,
      selectedStrokeIds: selectedStrokeIds,
      selectedShapeIds: selectedShapeIds,
      selectedImageIds: selectedImageIds,
      selectedTextIds: selectedTextIds,
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
    final lassoBounds = LassoGeometry.pathBounds(polygon);

    for (final stroke in strokes) {
      final bounds = stroke.bounds;
      if (bounds == null ||
          !LassoGeometry.boundsIntersect(bounds, lassoBounds)) {
        continue;
      }
      if (_isStrokeInLasso(stroke, polygon)) {
        selectedIds.add(stroke.id);
      }
    }

    return selectedIds;
  }

  /// Finds all texts whose center is inside the lasso.
  List<String> _findTextsInLasso(
    List<TextElement> texts,
    List<DrawingPoint> polygon,
  ) {
    final selectedIds = <String>[];
    final lassoBounds = LassoGeometry.pathBounds(polygon);
    for (final text in texts) {
      final bounds = text.bounds;
      if (!LassoGeometry.boundsIntersect(bounds, lassoBounds)) continue;
      final cx = (bounds.left + bounds.right) / 2;
      final cy = (bounds.top + bounds.bottom) / 2;
      if (LassoGeometry.isPointInPolygon(cx, cy, polygon)) {
        selectedIds.add(text.id);
      }
    }
    return selectedIds;
  }

  /// Finds all images whose center is inside the lasso.
  List<String> _findImagesInLasso(
    List<ImageElement> images,
    List<DrawingPoint> polygon,
  ) {
    final selectedIds = <String>[];
    final lassoBounds = LassoGeometry.pathBounds(polygon);
    for (final image in images) {
      if (!LassoGeometry.boundsIntersect(image.bounds, lassoBounds)) continue;
      final cx = image.x + image.width / 2;
      final cy = image.y + image.height / 2;
      if (LassoGeometry.isPointInPolygon(cx, cy, polygon)) {
        selectedIds.add(image.id);
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
    final lassoBounds = LassoGeometry.pathBounds(polygon);

    for (final shape in shapes) {
      if (!LassoGeometry.boundsIntersect(shape.bounds, lassoBounds)) continue;
      if (_isShapeInLasso(shape, polygon)) {
        selectedIds.add(shape.id);
      }
    }

    return selectedIds;
  }

  /// Checks if a stroke has any point inside the lasso polygon.
  bool _isStrokeInLasso(Stroke stroke, List<DrawingPoint> polygon) {
    for (final point in stroke.points) {
      if (LassoGeometry.isPointInPolygon(point.x, point.y, polygon)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if a shape's center is inside the lasso polygon.
  bool _isShapeInLasso(Shape shape, List<DrawingPoint> polygon) {
    // Check center point
    if (LassoGeometry.isPointInPolygon(shape.centerX, shape.centerY, polygon)) {
      return true;
    }
    // Also check start and end points for lines/arrows
    if (shape.type == ShapeType.line || shape.type == ShapeType.arrow) {
      if (LassoGeometry.isPointInPolygon(
              shape.startPoint.x, shape.startPoint.y, polygon) ||
          LassoGeometry.isPointInPolygon(
              shape.endPoint.x, shape.endPoint.y, polygon)) {
        return true;
      }
    }
    return false;
  }

  /// Calculates the bounding box of selected strokes, shapes, images, and texts.
  BoundingBox _calculateSelectionBounds(
    List<Stroke> strokes,
    List<String> selectedStrokeIds,
    List<Shape> shapes,
    List<String> selectedShapeIds,
    List<ImageElement> images,
    List<String> selectedImageIds, [
    List<TextElement> texts = const [],
    List<String> selectedTextIds = const [],
  ]) {
    final strokeIds = selectedStrokeIds.toSet();
    final shapeIds = selectedShapeIds.toSet();
    final imageIds = selectedImageIds.toSet();
    final textIds = selectedTextIds.toSet();

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    // Add stroke bounds
    for (final stroke in strokes) {
      if (!strokeIds.contains(stroke.id)) continue;

      final bounds = stroke.bounds;
      if (bounds == null) continue;

      minX = min(minX, bounds.left);
      minY = min(minY, bounds.top);
      maxX = max(maxX, bounds.right);
      maxY = max(maxY, bounds.bottom);
    }

    // Add shape bounds
    for (final shape in shapes) {
      if (!shapeIds.contains(shape.id)) continue;

      final bounds = shape.bounds;
      minX = min(minX, bounds.left);
      minY = min(minY, bounds.top);
      maxX = max(maxX, bounds.right);
      maxY = max(maxY, bounds.bottom);
    }

    // Add image bounds
    for (final image in images) {
      if (!imageIds.contains(image.id)) continue;

      final bounds = image.bounds;
      minX = min(minX, bounds.left);
      minY = min(minY, bounds.top);
      maxX = max(maxX, bounds.right);
      maxY = max(maxY, bounds.bottom);
    }

    // Add text bounds
    for (final text in texts) {
      if (!textIds.contains(text.id)) continue;

      final bounds = text.bounds;
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
