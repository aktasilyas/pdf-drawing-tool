import 'dart:math' as math;

import 'package:drawing_core/src/internal.dart';

/// One step of a pixel-eraser gesture: the area swept while the eraser moved
/// from the previous sample to the current one (a capsule).
///
/// A capsule whose two ends coincide is a disc (the first sample).
class EraserCapsule {
  const EraserCapsule({
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    required this.radius,
  });

  /// Disc of [radius] at a single eraser sample.
  const EraserCapsule.point(double x, double y, double radius)
      : this(x0: x, y0: y, x1: x, y1: y, radius: radius);

  final double x0;
  final double y0;
  final double x1;
  final double y1;

  /// Eraser radius in canvas units.
  final double radius;

  double get left => math.min(x0, x1) - radius;
  double get right => math.max(x0, x1) + radius;
  double get top => math.min(y0, y1) - radius;
  double get bottom => math.max(y0, y1) + radius;

  /// Distance from the capsule's centre line to the point (px, py).
  double distanceToPoint(double px, double py) =>
      pointToSegmentDistance(px, py, x0, y0, x1, y1);

  /// Distance from the capsule's centre line to the segment a-b.
  double distanceToSegment(double ax, double ay, double bx, double by) =>
      segmentToSegmentDistance(ax, ay, bx, by, x0, y0, x1, y1);

  /// Whether the box [l, t, r, b] grown by [pad] can touch this capsule.
  bool overlapsBox(double l, double t, double r, double b, double pad) {
    if (l - pad > right || r + pad < left) return false;
    return t - pad <= bottom && b + pad >= top;
  }

  /// Whether [box] grown by [pad] can touch this capsule.
  bool overlapsBounds(BoundingBox box, double pad) =>
      overlapsBox(box.left, box.top, box.right, box.bottom, pad);
}

/// The whole path of one pixel-eraser gesture as a chain of [EraserCapsule]s.
///
/// Consecutive samples are joined, so a fast stroke of the eraser removes a
/// continuous band instead of a row of separate dots.
class EraserSweep {
  final List<EraserCapsule> _capsules = [];
  double? _lastX;
  double? _lastY;
  double _lastRadius = 0;

  /// Capsules in gesture order.
  List<EraserCapsule> get capsules => List.unmodifiable(_capsules);

  bool get isEmpty => _capsules.isEmpty;

  /// Starts a new sweep.
  void clear() {
    _capsules.clear();
    _lastX = null;
    _lastY = null;
    _lastRadius = 0;
  }

  /// Adds an eraser sample at (x, y) with [radius] (canvas units) and returns
  /// the capsule that joins it to the previous sample.
  ///
  /// The joining capsule uses the larger of the two radii so a pressure
  /// change between samples never leaves an unerased gap.
  EraserCapsule add(double x, double y, double radius) {
    final lx = _lastX;
    final ly = _lastY;
    final EraserCapsule capsule;
    if (lx == null || ly == null) {
      capsule = EraserCapsule.point(x, y, radius);
    } else {
      final r = math.max(radius, _lastRadius);
      capsule = EraserCapsule(x0: lx, y0: ly, x1: x, y1: y, radius: r);
    }
    _capsules.add(capsule);
    _lastX = x;
    _lastY = y;
    _lastRadius = radius;
    return capsule;
  }
}

/// Distance from (px, py) to the segment (x1, y1)-(x2, y2).
double pointToSegmentDistance(
  double px,
  double py,
  double x1,
  double y1,
  double x2,
  double y2,
) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) return _hypot(px - x1, py - y1);
  final t = (((px - x1) * dx + (py - y1) * dy) / len2).clamp(0.0, 1.0);
  return _hypot(px - (x1 + t * dx), py - (y1 + t * dy));
}

/// Shortest distance between segments a-b and c-d (0 when they cross).
double segmentToSegmentDistance(
  double ax,
  double ay,
  double bx,
  double by,
  double cx,
  double cy,
  double dx,
  double dy,
) {
  if (_segmentsCross(ax, ay, bx, by, cx, cy, dx, dy)) return 0;
  return math.min(
    math.min(
      pointToSegmentDistance(ax, ay, cx, cy, dx, dy),
      pointToSegmentDistance(bx, by, cx, cy, dx, dy),
    ),
    math.min(
      pointToSegmentDistance(cx, cy, ax, ay, bx, by),
      pointToSegmentDistance(dx, dy, ax, ay, bx, by),
    ),
  );
}

bool _segmentsCross(
  double ax,
  double ay,
  double bx,
  double by,
  double cx,
  double cy,
  double dx,
  double dy,
) {
  final d1 = _cross(cx, cy, dx, dy, ax, ay);
  final d2 = _cross(cx, cy, dx, dy, bx, by);
  final d3 = _cross(ax, ay, bx, by, cx, cy);
  final d4 = _cross(ax, ay, bx, by, dx, dy);
  final straddlesCd = (d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0);
  final straddlesAb = (d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0);
  return straddlesCd && straddlesAb;
}

/// Z component of (b - a) x (p - a).
double _cross(
  double ax,
  double ay,
  double bx,
  double by,
  double px,
  double py,
) {
  return (bx - ax) * (py - ay) - (by - ay) * (px - ax);
}

double _hypot(double x, double y) => math.sqrt(x * x + y * y);
