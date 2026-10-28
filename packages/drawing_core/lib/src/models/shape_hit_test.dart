part of 'shape.dart';

/// Per-type hit testing for [Shape].
///
/// Kept in a part so `shape.dart` stays small; [Shape.containsPoint] runs the
/// bounds pre-filter and then delegates here.
extension _ShapeHitTest on Shape {
  bool _hitTestByType(double x, double y, double tolerance) {
    switch (type) {
      case ShapeType.line:
        return _lineContainsPoint(x, y, tolerance);
      case ShapeType.arrow:
        return _arrowContainsPoint(x, y, tolerance);
      case ShapeType.rectangle:
      case ShapeType.plus:
        return _rectangleContainsPoint(x, y, tolerance);
      case ShapeType.ellipse:
        return _ellipseContainsPoint(x, y, tolerance);
      case ShapeType.triangle:
      case ShapeType.diamond:
      case ShapeType.star:
      case ShapeType.pentagon:
      case ShapeType.hexagon:
        // Polygon shapes use bounds-based hit test for simplicity
        return _polygonContainsPoint(x, y, tolerance);
    }
  }

  bool _polygonContainsPoint(double x, double y, double tolerance) {
    // Simplified hit test using bounding box for complex polygon shapes
    // This provides good UX without complex polygon intersection math
    final effectiveTolerance = tolerance + style.thickness / 2;
    final b = bounds;

    if (isFilled) {
      return x >= b.left - effectiveTolerance &&
          x <= b.right + effectiveTolerance &&
          y >= b.top - effectiveTolerance &&
          y <= b.bottom + effectiveTolerance;
    } else {
      // For stroked polygons, check if near any edge (approximate)
      final cx = centerX;
      final cy = centerY;
      final hw = width / 2;
      final hh = height / 2;

      // Check distance from center as approximation
      final dx = (x - cx).abs();
      final dy = (y - cy).abs();

      // If within tolerance of the polygon boundary
      final normalizedDist = (dx / hw + dy / hh) / 2;
      return normalizedDist >= 0.7 - effectiveTolerance / min(hw, hh) &&
          normalizedDist <= 1.0 + effectiveTolerance / min(hw, hh);
    }
  }

  bool _lineContainsPoint(double x, double y, double tolerance) {
    final effectiveTolerance = tolerance + style.thickness / 2;
    return _pointToLineDistance(
          x,
          y,
          startPoint.x,
          startPoint.y,
          endPoint.x,
          endPoint.y,
        ) <=
        effectiveTolerance;
  }

  bool _arrowContainsPoint(double x, double y, double tolerance) {
    // Ana çizgi kontrolü
    if (_lineContainsPoint(x, y, tolerance)) return true;

    // Ok başı kontrolü (basitleştirilmiş - bounds check yeterli)
    final arrowHeadSize = style.thickness * 4;
    final dx = endPoint.x - startPoint.x;
    final dy = endPoint.y - startPoint.y;
    final length = sqrt(dx * dx + dy * dy);

    if (length < 1) return false;

    // Ok başı bölgesinde mi?
    final distToEnd = sqrt(pow(x - endPoint.x, 2) + pow(y - endPoint.y, 2));
    return distToEnd <= arrowHeadSize + tolerance;
  }

  bool _rectangleContainsPoint(double x, double y, double tolerance) {
    final effectiveTolerance = tolerance + style.thickness / 2;
    final b = bounds;

    if (isFilled) {
      // İçi dolu - bounds içinde mi?
      return x >= b.left - effectiveTolerance &&
          x <= b.right + effectiveTolerance &&
          y >= b.top - effectiveTolerance &&
          y <= b.bottom + effectiveTolerance;
    } else {
      // Sadece kenarlar
      final onLeft = (x - b.left).abs() <= effectiveTolerance &&
          y >= b.top &&
          y <= b.bottom;
      final onRight = (x - b.right).abs() <= effectiveTolerance &&
          y >= b.top &&
          y <= b.bottom;
      final onTop = (y - b.top).abs() <= effectiveTolerance &&
          x >= b.left &&
          x <= b.right;
      final onBottom = (y - b.bottom).abs() <= effectiveTolerance &&
          x >= b.left &&
          x <= b.right;

      return onLeft || onRight || onTop || onBottom;
    }
  }

  bool _ellipseContainsPoint(double x, double y, double tolerance) {
    final cx = centerX;
    final cy = centerY;
    final rx = width / 2;
    final ry = height / 2;

    if (rx < 1 || ry < 1) return false;

    // Normalize edilmiş mesafe
    final normalizedDist = pow((x - cx) / rx, 2) + pow((y - cy) / ry, 2);

    if (isFilled) {
      return normalizedDist <= 1.0 + tolerance / min(rx, ry);
    } else {
      // Kenar üzerinde mi?
      final innerRx = rx - style.thickness / 2;
      final innerRy = ry - style.thickness / 2;
      final outerRx = rx + style.thickness / 2;
      final outerRy = ry + style.thickness / 2;

      final innerDist = innerRx > 0 && innerRy > 0
          ? pow((x - cx) / innerRx, 2) + pow((y - cy) / innerRy, 2)
          : 0.0;
      final outerDist = pow((x - cx) / outerRx, 2) + pow((y - cy) / outerRy, 2);

      return outerDist <= 1.0 + tolerance / min(rx, ry) &&
          innerDist >= 1.0 - tolerance / min(rx, ry);
    }
  }
}

double _pointToLineDistance(
  double px,
  double py,
  double x1,
  double y1,
  double x2,
  double y2,
) {
  final dx = x2 - x1;
  final dy = y2 - y1;

  if (dx == 0 && dy == 0) {
    return sqrt(pow(px - x1, 2) + pow(py - y1, 2));
  }

  final t = max(
      0.0, min(1.0, ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)));

  final nearestX = x1 + t * dx;
  final nearestY = y1 + t * dy;

  return sqrt(pow(px - nearestX, 2) + pow(py - nearestY, 2));
}
