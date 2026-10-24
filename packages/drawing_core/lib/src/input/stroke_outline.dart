import 'dart:math' as math;

import 'package:drawing_core/src/input/outline_math.dart';
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

  /// Returns the closed polygon (implicitly closed; first != last) around
  /// [points], or an empty list when [points] is empty.
  static List<Point2D> build(
    List<DrawingPoint> points,
    StrokeOutlineOptions options,
  ) {
    if (points.isEmpty) return const [];
    final half = options.size / 2;
    final minR = math.max(half * outlineMinWidthFactor, 0.01);

    final centre = _streamline(points, options.streamline, minR);
    if (centre.length == 1) {
      final r = _radius(half, options, points.first.pressure, 0);
      return outlineCircle(centre.first.x, centre.first.y, math.max(r, minR));
    }

    final n = centre.length;
    final arc = List<double>.filled(n, 0);
    for (var i = 1; i < n; i++) {
      arc[i] = arc[i - 1] + outlineDist(centre[i - 1], centre[i]);
    }
    final total = arc.last;

    // Per-point radius from pressure and speed.
    final radii = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final speed = i == 0
          ? outlineSpeed(centre[0], centre[1])
          : outlineSpeed(centre[i - 1], centre[i]);
      var r = _radius(half, options, centre[i].pressure, speed);
      r *= outlineTaper(arc[i], total, options.taperStart, options.taperEnd);
      radii[i] = math.max(r, minR);
    }
    _smoothRadii(radii, arc, options.smoothing);

    final tangents =
        List<Point2D>.generate(n, (i) => outlineTangent(centre, i));
    final left = <Point2D>[];
    final right = <Point2D>[];
    for (var i = 0; i < n; i++) {
      final t = tangents[i];
      final r = radii[i];
      left.add(Point2D(centre[i].x - t.y * r, centre[i].y + t.x * r));
      right.add(Point2D(centre[i].x + t.y * r, centre[i].y - t.x * r));
    }

    final out = <Point2D>[...left];
    out.addAll(outlineCap(centre.last, tangents.last, radii.last, true));
    out.addAll(right.reversed);
    out.addAll(outlineCap(centre.first, tangents.first, radii.first, false));
    return out;
  }

  static double _radius(
    double half,
    StrokeOutlineOptions o,
    double pressure,
    double speed,
  ) =>
      outlineRadius(half, o.thinning, o.velocityThinning, pressure, speed);

  /// Limits radius change per unit of arc length so that the offset edges
  /// cannot cross each other (|dr/ds| < 1), then low-pass filters.
  static void _smoothRadii(List<double> r, List<double> arc, double smoothing) {
    final k = outlineEmaFactor(smoothing);
    for (var i = 1; i < r.length; i++) {
      r[i] = k * r[i] + (1 - k) * r[i - 1];
    }
    for (var i = r.length - 2; i >= 0; i--) {
      r[i] = k * r[i] + (1 - k) * r[i + 1];
    }
    for (var i = 1; i < r.length; i++) {
      final lim = (arc[i] - arc[i - 1]) * outlineSlope;
      r[i] = r[i].clamp(r[i - 1] - lim, r[i - 1] + lim);
    }
    for (var i = r.length - 2; i >= 0; i--) {
      final lim = (arc[i + 1] - arc[i]) * outlineSlope;
      r[i] = r[i].clamp(r[i + 1] - lim, r[i + 1] + lim);
    }
  }

  static List<OutlinePoint> _streamline(
    List<DrawingPoint> pts,
    double streamline,
    double minDist,
  ) {
    final a = outlineStreamlineAlpha(streamline);
    final out = <OutlinePoint>[];
    for (final p in pts) {
      final q = OutlinePoint(p.x, p.y, p.pressure, p.timestamp.toDouble());
      if (out.isEmpty) {
        out.add(q);
        continue;
      }
      final prev = out.last;
      if (outlineDist(prev, q) < math.max(minDist, 0.05)) continue;
      out.add(OutlinePoint(
        prev.x + (q.x - prev.x) * a,
        prev.y + (q.y - prev.y) * a,
        q.pressure,
        q.t,
      ));
    }
    // Keep the true end point so strokes land where the pen lifted.
    final last = pts.last;
    if (out.length > 1 && (out.last.x != last.x || out.last.y != last.y)) {
      final q = OutlinePoint(
          last.x, last.y, last.pressure, last.timestamp.toDouble());
      if (outlineDist(out.last, q) >= minDist) out.add(q);
    }
    return out;
  }
}
