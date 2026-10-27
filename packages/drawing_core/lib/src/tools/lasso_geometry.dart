import 'dart:math';

import 'package:drawing_core/src/models/bounding_box.dart';
import 'package:drawing_core/src/models/drawing_point.dart';

/// Pure polygon maths used by lasso tools.
abstract final class LassoGeometry {
  /// Ray casting point-in-polygon test.
  ///
  /// Returns false for degenerate polygons (< 3 points).
  static bool isPointInPolygon(double x, double y, List<DrawingPoint> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].x;
      final yi = polygon[i].y;
      final xj = polygon[j].x;
      final yj = polygon[j].y;

      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }

      j = i;
    }

    return inside;
  }

  /// Bounding box of [path]; [BoundingBox.zero] when empty.
  static BoundingBox pathBounds(List<DrawingPoint> path) {
    if (path.isEmpty) return BoundingBox.zero();

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final point in path) {
      minX = min(minX, point.x);
      minY = min(minY, point.y);
      maxX = max(maxX, point.x);
      maxY = max(maxY, point.y);
    }

    return BoundingBox(left: minX, top: minY, right: maxX, bottom: maxY);
  }

  /// Whether [a] and [b] overlap (touching edges count).
  static bool boundsIntersect(BoundingBox a, BoundingBox b) {
    return a.left <= b.right &&
        a.right >= b.left &&
        a.top <= b.bottom &&
        a.bottom >= b.top;
  }
}
