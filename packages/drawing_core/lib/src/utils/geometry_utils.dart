import 'dart:math' as math;

/// Utility functions for geometry calculations.
class GeometryUtils {
  GeometryUtils._();

  /// Calculates the distance between two points.
  static double distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculates the angle in radians between two points.
  static double angle(double x1, double y1, double x2, double y2) {
    return math.atan2(y2 - y1, x2 - x1);
  }

  /// Linear interpolation between two values.
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  /// Clamps a value between min and max.
  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Calculates the perpendicular angle from a given angle.
  static double perpendicular(double angle) {
    return angle + math.pi / 2;
  }

  /// Converts degrees to radians.
  static double degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Converts radians to degrees.
  static double radiansToDegrees(double radians) {
    return radians * 180 / math.pi;
  }

  /// Calculates the midpoint between two points.
  static (double x, double y) midpoint(
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    return ((x1 + x2) / 2, (y1 + y2) / 2);
  }

  /// Checks if a point is inside a rectangle.
  static bool pointInRect(
    double px,
    double py,
    double rx,
    double ry,
    double rw,
    double rh,
  ) {
    return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh;
  }

  /// Calculates the bounding box of a list of points.
  static (double minX, double minY, double maxX, double maxY) boundingBox(
    List<(double, double)> points,
  ) {
    if (points.isEmpty) {
      return (0, 0, 0, 0);
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final (x, y) in points) {
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }

    return (minX, minY, maxX, maxY);
  }

  /// Calculates a quadratic bezier point.
  static (double x, double y) quadraticBezier(
    double t,
    double x0,
    double y0,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final mt = 1 - t;
    final mt2 = mt * mt;
    final t2 = t * t;

    final x = mt2 * x0 + 2 * mt * t * x1 + t2 * x2;
    final y = mt2 * y0 + 2 * mt * t * y1 + t2 * y2;

    return (x, y);
  }

  /// Calculates a cubic bezier point.
  static (double x, double y) cubicBezier(
    double t,
    double x0,
    double y0,
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {
    final mt = 1 - t;
    final mt2 = mt * mt;
    final mt3 = mt2 * mt;
    final t2 = t * t;
    final t3 = t2 * t;

    final x = mt3 * x0 + 3 * mt2 * t * x1 + 3 * mt * t2 * x2 + t3 * x3;
    final y = mt3 * y0 + 3 * mt2 * t * y1 + 3 * mt * t2 * y2 + t3 * y3;

    return (x, y);
  }

  /// Calculates the area of a triangle given three points.
  static double triangleArea(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {
    return ((x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)) / 2).abs();
  }

  /// Checks if a point is inside a circle.
  static bool pointInCircle(
    double px,
    double py,
    double cx,
    double cy,
    double radius,
  ) {
    final dx = px - cx;
    final dy = py - cy;
    return dx * dx + dy * dy <= radius * radius;
  }

  /// Normalizes an angle to be between 0 and 2*PI.
  static double normalizeAngle(double angle) {
    while (angle < 0) {
      angle += 2 * math.pi;
    }
    while (angle >= 2 * math.pi) {
      angle -= 2 * math.pi;
    }
    return angle;
  }

  /// Calculates the shortest angle difference between two angles.
  static double angleDifference(double a, double b) {
    var diff = b - a;
    while (diff > math.pi) {
      diff -= 2 * math.pi;
    }
    while (diff < -math.pi) {
      diff += 2 * math.pi;
    }
    return diff;
  }
}
