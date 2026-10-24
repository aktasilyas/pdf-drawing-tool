import 'dart:math' as math;

import 'package:drawing_core/src/models/selection.dart';

/// Shared math for [StrokeOutline] and [IncrementalStrokeOutline].
///
/// Internal to the package: this file is deliberately not exported.

/// Smallest radius as a fraction of the nominal half width.
const double outlineMinWidthFactor = 0.15;

/// Number of segments of a half-circle cap.
const int outlineCapSegments = 8;

/// Maximum |dr/ds| of the radius, so the offset edges cannot cross.
const double outlineSlope = 0.9;

/// A centre-line sample with pressure and time.
class OutlinePoint {
  final double x, y, pressure, t;
  const OutlinePoint(this.x, this.y, this.pressure, this.t);
}

/// Weight of the new value in the radius moving average.
double outlineEmaFactor(double smoothing) =>
    1 - 0.8 * smoothing.clamp(0.0, 1.0);

/// Weight of the new input in centre-line streamlining.
double outlineStreamlineAlpha(double streamline) =>
    1 - 0.75 * streamline.clamp(0.0, 1.0);

double outlineRadius(
  double half,
  double thinning,
  double velocityThinning,
  double pressure,
  double speed,
) {
  final p = (1 - thinning) + thinning * pressure;
  final v = 1 - velocityThinning * (speed / (speed + 2)).clamp(0.0, 1.0);
  return half * p * v;
}

double outlineSpeed(OutlinePoint a, OutlinePoint b) {
  final dt = (b.t - a.t).abs();
  final d = outlineDist(a, b);
  return dt <= 0 ? 0 : d / dt;
}

/// Width factor in [0, 1] from the start and end tapers at arc length [s].
double outlineTaper(
  double s,
  double total,
  double taperStart,
  double taperEnd,
) {
  var f = 1.0;
  if (taperStart > 0 && s < taperStart) {
    final t = s / taperStart;
    f = math.min(f, t * (2 - t));
  }
  if (taperEnd > 0 && total - s < taperEnd) {
    final t = (total - s) / taperEnd;
    f = math.min(f, t * (2 - t));
  }
  return f;
}

Point2D outlineTangent(List<OutlinePoint> c, int i) {
  final a = c[math.max(i - 1, 0)];
  final b = c[math.min(i + 1, c.length - 1)];
  final dx = b.x - a.x, dy = b.y - a.y;
  final len = math.sqrt(dx * dx + dy * dy);
  if (len < 1e-9) return const Point2D(1, 0);
  return Point2D(dx / len, dy / len);
}

/// Half circle from the left edge to the right edge around the front
/// ([atEnd]) or from right to left around the back.
List<Point2D> outlineCap(OutlinePoint c, Point2D t, double r, bool atEnd) {
  final out = <Point2D>[];
  final dir = atEnd ? 1.0 : -1.0;
  for (var i = 1; i < outlineCapSegments; i++) {
    final a = math.pi * i / outlineCapSegments;
    final fx = t.x * dir, fy = t.y * dir;
    final nx = -t.y * dir, ny = t.x * dir;
    // From the normal side sweeping through the forward direction.
    out.add(Point2D(
      c.x + (nx * math.cos(a) + fx * math.sin(a)) * r,
      c.y + (ny * math.cos(a) + fy * math.sin(a)) * r,
    ));
  }
  return out;
}

List<Point2D> outlineCircle(double x, double y, double r) => [
      for (var i = 0; i < 16; i++)
        Point2D(x + r * math.cos(2 * math.pi * i / 16),
            y + r * math.sin(2 * math.pi * i / 16)),
    ];

double outlineDist(OutlinePoint a, OutlinePoint b) {
  final dx = b.x - a.x, dy = b.y - a.y;
  return math.sqrt(dx * dx + dy * dy);
}
