import 'dart:math' as math;

import 'package:drawing_core/src/internal.dart';

/// Cuts the part of a stroke covered by an [EraserSweep] out of the stroke.
///
/// Geometry is removed exactly where the ink overlaps the swept area (eraser
/// radius plus half the stroke thickness), independent of how densely the
/// stroke was sampled: long segments are cut at the boundary instead of being
/// dropped whole, and the cut ends get interpolated points.
class SweepStrokeEraser {
  SweepStrokeEraser._();

  /// Bisection steps used to place a cut point (error < length / 2^steps).
  static const int _bisectSteps = 14;

  /// Pieces shorter than this (canvas units) are dropped.
  static const double _minPieceLength = 0.01;

  /// Returns the remaining pieces of [stroke], or null when the sweep does
  /// not touch it. An empty list means the stroke is erased completely.
  ///
  /// Pieces get ids `<stroke.id>_split_<k>`, the convention
  /// [ErasePointsCommand] uses to keep z-order.
  static List<Stroke>? erase(Stroke stroke, List<EraserCapsule> capsules) {
    final points = stroke.points;
    if (points.isEmpty || capsules.isEmpty) return null;

    final pad = stroke.style.thickness / 2;
    final bounds = stroke.bounds!;
    final near = [
      for (final c in capsules)
        if (c.overlapsBounds(bounds, pad)) c,
    ];
    if (near.isEmpty) return null;

    bool inside(double x, double y) {
      for (final c in near) {
        if (c.distanceToPoint(x, y) <= c.radius + pad) return true;
      }
      return false;
    }

    if (points.length == 1) {
      return inside(points.first.x, points.first.y) ? const [] : null;
    }

    var minReach = double.infinity;
    for (final c in near) {
      minReach = math.min(minReach, c.radius + pad);
    }
    // Sub-steps small enough that no eraser disc fits between two of them.
    final step = math.max(minReach / 2, 0.25);

    final pieces = <List<DrawingPoint>>[];
    var current = <DrawingPoint>[];
    var erasedAny = false;

    void addPoint(DrawingPoint p) {
      final last = current.isEmpty ? null : current.last;
      if (last != null && last.x == p.x && last.y == p.y) return;
      current.add(p);
    }

    void flush() {
      if (current.length >= 2 && _length(current) >= _minPieceLength) {
        pieces.add(current);
      }
      current = <DrawingPoint>[];
    }

    var prevIn = inside(points.first.x, points.first.y);
    if (prevIn) {
      erasedAny = true;
    } else {
      current.add(points.first);
    }

    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];

      if (!prevIn && !_segmentNear(a, b, near, pad)) {
        addPoint(b);
        continue;
      }

      final len = _dist(a, b);
      final k = math.max(1, (len / step).ceil());
      var prevT = 0.0;
      for (var j = 1; j <= k; j++) {
        final t = j / k;
        final q = j == k ? b : _lerp(a, b, t);
        final qIn = inside(q.x, q.y);
        if (qIn) erasedAny = true;
        if (qIn != prevIn) {
          final cut = _bisect(a, b, prevT, t, prevIn, inside);
          if (prevIn) {
            // Leaving the erased area: a new piece starts at the cut.
            current = <DrawingPoint>[cut];
          } else {
            // Entering the erased area: the current piece ends at the cut.
            addPoint(cut);
            flush();
          }
        }
        prevIn = qIn;
        prevT = t;
      }
      if (!prevIn) addPoint(b);
    }
    flush();

    if (!erasedAny) return null;

    return [
      for (var k = 0; k < pieces.length; k++)
        Stroke(
          id: '${stroke.id}_split_$k',
          points: pieces[k],
          style: stroke.style,
          createdAt: stroke.createdAt,
        ),
    ];
  }

  static bool _segmentNear(
    DrawingPoint a,
    DrawingPoint b,
    List<EraserCapsule> near,
    double pad,
  ) {
    final l = math.min(a.x, b.x);
    final r = math.max(a.x, b.x);
    final t = math.min(a.y, b.y);
    final bt = math.max(a.y, b.y);
    for (final c in near) {
      if (!c.overlapsBox(l, t, r, bt, pad)) continue;
      if (c.distanceToSegment(a.x, a.y, b.x, b.y) <= c.radius + pad) {
        return true;
      }
    }
    return false;
  }

  /// Finds the boundary between parameters [t0] (state [in0]) and [t1] on
  /// a-b and returns the point on the outside of it, so kept ink never
  /// reaches into the erased area.
  static DrawingPoint _bisect(
    DrawingPoint a,
    DrawingPoint b,
    double t0,
    double t1,
    bool in0,
    bool Function(double x, double y) inside,
  ) {
    var outT = in0 ? t1 : t0;
    var inT = in0 ? t0 : t1;
    for (var s = 0; s < _bisectSteps; s++) {
      final mid = (outT + inT) / 2;
      final m = _lerp(a, b, mid);
      if (inside(m.x, m.y)) {
        inT = mid;
      } else {
        outT = mid;
      }
    }
    if (outT == 0) return a;
    if (outT == 1) return b;
    return _lerp(a, b, outT);
  }

  static DrawingPoint _lerp(DrawingPoint a, DrawingPoint b, double t) =>
      DrawingPoint(
        x: a.x + (b.x - a.x) * t,
        y: a.y + (b.y - a.y) * t,
        pressure: a.pressure + (b.pressure - a.pressure) * t,
        tilt: a.tilt + (b.tilt - a.tilt) * t,
        timestamp: (a.timestamp + (b.timestamp - a.timestamp) * t).round(),
      );

  static double _dist(DrawingPoint a, DrawingPoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static double _length(List<DrawingPoint> pts) {
    var sum = 0.0;
    for (var i = 1; i < pts.length; i++) {
      sum += _dist(pts[i - 1], pts[i]);
    }
    return sum;
  }
}
