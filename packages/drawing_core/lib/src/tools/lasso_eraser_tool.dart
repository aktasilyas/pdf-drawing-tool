import 'dart:math' as math;
import 'package:drawing_core/drawing_core.dart';

/// Lasso-based eraser that removes all strokes within drawn selection.
class LassoEraserTool {
  LassoEraserTool();
  
  /// Points forming the lasso path
  final List<DrawingPoint> _lassoPoints = [];
  
  bool get isActive => _lassoPoints.isNotEmpty;
  
  List<DrawingPoint> get lassoPoints => List.unmodifiable(_lassoPoints);
  
  void onPointerDown(double x, double y) {
    _lassoPoints.clear();
    _lassoPoints.add(DrawingPoint(
      x: x,
      y: y,
      pressure: 1.0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }
  
  void onPointerMove(double x, double y) {
    _lassoPoints.add(DrawingPoint(
      x: x,
      y: y,
      pressure: 1.0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }
  
  /// Returns IDs of strokes to erase
  List<String> onPointerUp(List<Stroke> strokes) {
    if (_lassoPoints.length < 3) {
      _lassoPoints.clear();
      return [];
    }
    
    // IMPORTANT: Find strokes BEFORE clearing points
    final strokeIds = findStrokesInLasso(strokes);
    _lassoPoints.clear();
    return strokeIds;
  }
  
  void cancel() {
    _lassoPoints.clear();
  }
  
  /// Find all strokes that have any point inside the lasso
  List<String> findStrokesInLasso(List<Stroke> strokes) {
    if (_lassoPoints.length < 3) return [];
    
    final result = <String>[];
    final polygon = _lassoPoints.map((p) => math.Point(p.x, p.y)).toList();
    
    for (final stroke in strokes) {
      // Quick bounds check
      if (!_boundsIntersect(stroke.bounds, _getLassoBounds())) {
        continue;
      }
      
      // Check if any point is inside lasso
      for (final point in stroke.points) {
        if (_isPointInPolygon(math.Point(point.x, point.y), polygon)) {
          result.add(stroke.id);
          break; // One point inside is enough
        }
      }
    }
    
    return result;
  }
  
  BoundingBox _getLassoBounds() {
    if (_lassoPoints.isEmpty) {
      return const BoundingBox(left: 0, top: 0, right: 0, bottom: 0);
    }
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final point in _lassoPoints) {
      minX = math.min(minX, point.x);
      minY = math.min(minY, point.y);
      maxX = math.max(maxX, point.x);
      maxY = math.max(maxY, point.y);
    }
    
    return BoundingBox(left: minX, top: minY, right: maxX, bottom: maxY);
  }
  
  bool _boundsIntersect(BoundingBox? strokeBounds, BoundingBox lassoBounds) {
    if (strokeBounds == null) return false;
    
    return !(strokeBounds.right < lassoBounds.left ||
             strokeBounds.left > lassoBounds.right ||
             strokeBounds.bottom < lassoBounds.top ||
             strokeBounds.top > lassoBounds.bottom);
  }
  
  /// Ray casting algorithm for point-in-polygon
  bool _isPointInPolygon(math.Point<double> point, List<math.Point<double>> polygon) {
    if (polygon.length < 3) return false;
    
    int intersections = 0;
    final n = polygon.length;
    
    for (int i = 0; i < n; i++) {
      var p1 = polygon[i];
      var p2 = polygon[(i + 1) % n];
      
      if (_rayIntersectsSegment(point, p1, p2)) {
        intersections++;
      }
    }
    
    return intersections.isOdd;
  }
  
  bool _rayIntersectsSegment(
    math.Point<double> point,
    math.Point<double> p1,
    math.Point<double> p2,
  ) {
    // Ray goes from point to the right (positive x direction)
    if (p1.y > p2.y) {
      final temp = p1;
      p1 = p2;
      p2 = temp;
    }
    
    var testY = point.y;
    if (testY == p1.y || testY == p2.y) {
      // Avoid edge cases by slightly adjusting
      testY += 0.0001;
    }
    
    if (testY < p1.y || testY > p2.y) {
      return false;
    }
    
    if (point.x >= math.max(p1.x, p2.x)) {
      return false;
    }
    
    if (point.x < math.min(p1.x, p2.x)) {
      return true;
    }
    
    final dx = p2.x - p1.x;
    if (dx == 0) {
      return point.x < p1.x;
    }
    
    final slope = (p2.y - p1.y) / dx;
    final xIntersect = p1.x + (testY - p1.y) / slope;
    
    return point.x < xIntersect;
  }
}
