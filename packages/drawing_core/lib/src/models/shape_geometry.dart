import 'dart:math' as math;

import 'package:drawing_core/src/models/selection.dart';
import 'package:drawing_core/src/models/shape.dart';
import 'package:drawing_core/src/models/shape_type.dart';

/// One polyline of a shape outline, in page coordinates.
class ShapeGeometryPath {
  /// Vertices in drawing order.
  final List<Point2D> points;

  /// Whether the last vertex connects back to the first.
  final bool closed;

  const ShapeGeometryPath(this.points, {required this.closed});
}

/// The single source of truth for polygonal shape outlines.
///
/// The on-screen painter and both PDF export paths build their paths from
/// these vertices, so every renderer draws the same geometry.
abstract final class ShapeGeometry {
  /// Inner radius of the star, as a fraction of the outer radius.
  static const double starInnerRatio = 0.4;

  /// Number of star points.
  static const int starPoints = 5;

  static const _native = {
    ShapeType.line,
    ShapeType.arrow,
    ShapeType.rectangle,
    ShapeType.ellipse,
  };

  /// Whether [type] is drawn with a renderer's native primitive (line,
  /// rectangle, oval) rather than a vertex list.
  static bool isNative(ShapeType type) => _native.contains(type);

  /// Polygon outline of [shape], or null when [isNative] is true.
  static List<ShapeGeometryPath>? polygonPaths(Shape shape) {
    final l = shape.left;
    final r = shape.right;
    final t = shape.top;
    final b = shape.bottom;
    final cx = (l + r) / 2;
    final cy = (t + b) / 2;
    final rx = (r - l) / 2;
    final ry = (b - t) / 2;

    switch (shape.type) {
      case ShapeType.line:
      case ShapeType.arrow:
      case ShapeType.rectangle:
      case ShapeType.ellipse:
        return null;
      case ShapeType.triangle:
        final pts = [Point2D(cx, t), Point2D(l, b), Point2D(r, b)];
        return [ShapeGeometryPath(pts, closed: true)];
      case ShapeType.diamond:
        final pts = [
          Point2D(cx, t),
          Point2D(r, cy),
          Point2D(cx, b),
          Point2D(l, cy),
        ];
        return [ShapeGeometryPath(pts, closed: true)];
      case ShapeType.star:
        return [_star(cx, cy, rx, ry)];
      case ShapeType.pentagon:
        return [_regularPolygon(cx, cy, rx, ry, 5)];
      case ShapeType.hexagon:
        return [_regularPolygon(cx, cy, rx, ry, 6)];
      case ShapeType.plus:
        final vertical = [Point2D(cx, t), Point2D(cx, b)];
        final horizontal = [Point2D(l, cy), Point2D(r, cy)];
        return [
          ShapeGeometryPath(vertical, closed: false),
          ShapeGeometryPath(horizontal, closed: false),
        ];
    }
  }

  static ShapeGeometryPath _star(double cx, double cy, double rx, double ry) {
    final pts = <Point2D>[];
    for (var i = 0; i < starPoints * 2; i++) {
      final scale = i.isEven ? 1.0 : starInnerRatio;
      final angle = i * math.pi / starPoints - math.pi / 2;
      pts.add(_onEllipse(cx, cy, rx * scale, ry * scale, angle));
    }
    return ShapeGeometryPath(pts, closed: true);
  }

  static ShapeGeometryPath _regularPolygon(
    double cx,
    double cy,
    double rx,
    double ry,
    int sides,
  ) {
    final pts = <Point2D>[];
    for (var i = 0; i < sides; i++) {
      final angle = i * 2 * math.pi / sides - math.pi / 2;
      pts.add(_onEllipse(cx, cy, rx, ry, angle));
    }
    return ShapeGeometryPath(pts, closed: true);
  }

  static Point2D _onEllipse(
    double cx,
    double cy,
    double rx,
    double ry,
    double angle,
  ) {
    return Point2D(cx + rx * math.cos(angle), cy + ry * math.sin(angle));
  }
}
