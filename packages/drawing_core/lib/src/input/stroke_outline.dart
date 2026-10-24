import 'dart:math' as math;

import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/selection.dart';

/// Tuning for [StrokeOutline.build].
class StrokeOutlineOptions {
  /// Nominal stroke width in logical pixels.
  final double size;

  /// How strongly pressure changes width (0 = constant, 1 = full range).
  final double thinning;

  /// How strongly speed thins the stroke (0 = ignore velocity).
  final double velocityThinning;

  /// Smooths width changes along the stroke (0 = raw, 1 = heavy).
  final double smoothing;

  /// Smooths the centre line (0 = raw, 1 = heavy).
  final double streamline;

  /// Length in px over which the start tapers from zero width (0 = round cap).
  final double taperStart;

  /// Length in px over which the end tapers to zero width (0 = round cap).
  final double taperEnd;

  const StrokeOutlineOptions({
    this.size = 4,
    this.thinning = 0.6,
    this.velocityThinning = 0.2,
    this.smoothing = 0.5,
    this.streamline = 0.5,
    this.taperStart = 0,
    this.taperEnd = 0,
  });
}

/// Builds a closed outline polygon for a pressure/velocity-aware stroke.
///
/// Pure Dart implementation in the spirit of perfect-freehand (MIT, studied
/// as reference only). Render the result as a single filled path.
class StrokeOutline {
  StrokeOutline._();

  static const double _minWidthFactor = 0.15;
  static const int _capSegments = 8;

  /// Returns the closed polygon (implicitly closed; first != last) around
  /// [points], or an empty list when [points] is empty.
  static List<Point2D> build(
    List<DrawingPoint> points,
    StrokeOutlineOptions options,
  ) {
    if (points.isEmpty) return const [];
    final half = options.size / 2;
    final minR = math.max(half * _minWidthFactor, 0.01);

    final centre = _streamline(points, options.streamline, minR);
    if (centre.length == 1) {
      final r = _radius(half, options, points.first.pressure, 0);
      return _circle(centre.first.x, centre.first.y, math.max(r, minR));
    }

    final n = centre.length;
    final arc = List<double>.filled(n, 0);
    for (var i = 1; i < n; i++) {
      arc[i] = arc[i - 1] + _dist(centre[i - 1], centre[i]);
    }
    final total = arc.last;

    // Per-point radius from pressure and speed.
    final radii = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final speed = i == 0
          ? _speed(centre[0], centre[1])
          : _speed(centre[i - 1], centre[i]);
      var r = _radius(half, options, centre[i].pressure, speed);
      r *= _taper(arc[i], total, options);
      radii[i] = math.max(r, minR);
    }
    _smoothRadii(radii, arc, options.smoothing);

    final tangents = List<Point2D>.generate(n, (i) => _tangent(centre, i));
    final left = <Point2D>[];
    final right = <Point2D>[];
    for (var i = 0; i < n; i++) {
      final t = tangents[i];
      final r = radii[i];
      left.add(Point2D(centre[i].x - t.y * r, centre[i].y + t.x * r));
      right.add(Point2D(centre[i].x + t.y * r, centre[i].y - t.x * r));
    }

    final out = <Point2D>[...left];
    out.addAll(_cap(centre.last, tangents.last, radii.last, true));
    out.addAll(right.reversed);
    out.addAll(_cap(centre.first, tangents.first, radii.first, false));
    return out;
  }

  static double _radius(
    double half,
    StrokeOutlineOptions o,
    double pressure,
    double speed,
  ) {
    final p = (1 - o.thinning) + o.thinning * pressure;
    final v = 1 - o.velocityThinning * (speed / (speed + 2)).clamp(0.0, 1.0);
    return half * p * v;
  }

  static double _speed(_P a, _P b) {
    final dt = (b.t - a.t).abs();
    final d = _dist(a, b);
    return dt <= 0 ? 0 : d / dt;
  }

  static double _taper(double s, double total, StrokeOutlineOptions o) {
    var f = 1.0;
    if (o.taperStart > 0 && s < o.taperStart) {
      final t = s / o.taperStart;
      f = math.min(f, t * (2 - t));
    }
    if (o.taperEnd > 0 && total - s < o.taperEnd) {
      final t = (total - s) / o.taperEnd;
      f = math.min(f, t * (2 - t));
    }
    return f;
  }

  /// Limits radius change per unit of arc length so that the offset edges
  /// cannot cross each other (|dr/ds| < 1), then low-pass filters.
  static void _smoothRadii(List<double> r, List<double> arc, double smoothing) {
    final k = 1 - 0.8 * smoothing.clamp(0.0, 1.0);
    for (var i = 1; i < r.length; i++) {
      r[i] = k * r[i] + (1 - k) * r[i - 1];
    }
    for (var i = r.length - 2; i >= 0; i--) {
      r[i] = k * r[i] + (1 - k) * r[i + 1];
    }
    const slope = 0.9;
    for (var i = 1; i < r.length; i++) {
      final lim = (arc[i] - arc[i - 1]) * slope;
      r[i] = r[i].clamp(r[i - 1] - lim, r[i - 1] + lim);
    }
    for (var i = r.length - 2; i >= 0; i--) {
      final lim = (arc[i + 1] - arc[i]) * slope;
      r[i] = r[i].clamp(r[i + 1] - lim, r[i + 1] + lim);
    }
  }

  static List<_P> _streamline(
    List<DrawingPoint> pts,
    double streamline,
    double minDist,
  ) {
    final a = 1 - 0.75 * streamline.clamp(0.0, 1.0);
    final out = <_P>[];
    for (final p in pts) {
      final q = _P(p.x, p.y, p.pressure, p.timestamp.toDouble());
      if (out.isEmpty) {
        out.add(q);
        continue;
      }
      final prev = out.last;
      if (_dist(prev, q) < math.max(minDist, 0.05)) continue;
      out.add(_P(
        prev.x + (q.x - prev.x) * a,
        prev.y + (q.y - prev.y) * a,
        q.pressure,
        q.t,
      ));
    }
    // Keep the true end point so strokes land where the pen lifted.
    final last = pts.last;
    if (out.length > 1 && (out.last.x != last.x || out.last.y != last.y)) {
      final q = _P(last.x, last.y, last.pressure, last.timestamp.toDouble());
      if (_dist(out.last, q) >= minDist) out.add(q);
    }
    return out;
  }

  static Point2D _tangent(List<_P> c, int i) {
    final a = c[math.max(i - 1, 0)];
    final b = c[math.min(i + 1, c.length - 1)];
    final dx = b.x - a.x, dy = b.y - a.y;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1e-9) return const Point2D(1, 0);
    return Point2D(dx / len, dy / len);
  }

  /// Half circle from the left edge to the right edge around the front
  /// ([atEnd]) or from right to left around the back.
  static List<Point2D> _cap(_P c, Point2D t, double r, bool atEnd) {
    final out = <Point2D>[];
    final dir = atEnd ? 1.0 : -1.0;
    for (var i = 1; i < _capSegments; i++) {
      final a = math.pi * i / _capSegments;
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

  static List<Point2D> _circle(double x, double y, double r) => [
        for (var i = 0; i < 16; i++)
          Point2D(x + r * math.cos(2 * math.pi * i / 16),
              y + r * math.sin(2 * math.pi * i / 16)),
      ];

  static double _dist(_P a, _P b) {
    final dx = b.x - a.x, dy = b.y - a.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}

class _P {
  final double x, y, pressure, t;
  const _P(this.x, this.y, this.pressure, this.t);
}
