import 'dart:math' as math;

import 'package:drawing_core/src/internal.dart';

/// Tuning for [StrokeInputFilter].
class StrokeInputFilterConfig {
  /// One Euro minimum cutoff in Hz (lower = smoother).
  final double minCutoff;

  /// One Euro speed coefficient (higher = less lag when fast).
  final double beta;

  /// Fixed spacing between emitted points, in logical pixels.
  final double spacing;

  /// One Euro cutoff for pressure in Hz; higher keeps pressure ramps responsive.
  final double pressureCutoff;

  /// Assumed sample interval in seconds when timestamps are missing.
  final double fallbackDt;

  /// Creates a config; defaults suit stylus input at ~120 Hz.
  const StrokeInputFilterConfig({
    this.minCutoff = 1.5,
    this.beta = 0.01,
    this.spacing = 1.5,
    this.pressureCutoff = 8.0,
    this.fallbackDt = 1 / 120,
  })  : assert(spacing > 0, 'spacing must be positive'),
        assert(minCutoff > 0, 'minCutoff must be positive');
}

/// Streaming input stage: One Euro filter over x/y/pressure, then resampling
/// to fixed spacing. Pure Dart and deterministic.
class StrokeInputFilter {
  /// Tuning used by this filter.
  final StrokeInputFilterConfig config;

  late final OneEuroFilter _fx = _make();
  late final OneEuroFilter _fy = _make();
  late final OneEuroFilter _fp =
      OneEuroFilter(minCutoff: config.pressureCutoff);

  int? _lastTimestamp;
  DrawingPoint? _lastFiltered;
  DrawingPoint? _lastEmitted;
  DrawingPoint? _lastRaw;

  /// Creates a filter.
  StrokeInputFilter([this.config = const StrokeInputFilterConfig()]);

  OneEuroFilter _make() =>
      OneEuroFilter(minCutoff: config.minCutoff, beta: config.beta);

  /// Starts a new stroke and returns its first point.
  DrawingPoint begin(DrawingPoint p) {
    _fx.reset();
    _fy.reset();
    _fp.reset();
    _lastTimestamp = p.timestamp;
    _lastRaw = p;
    final first = _apply(p, config.fallbackDt);
    _lastFiltered = first;
    _lastEmitted = first;
    return first;
  }

  /// Feeds [p]; returns the resampled points it produces (possibly none).
  List<DrawingPoint> add(DrawingPoint p) {
    final last = _lastTimestamp;
    final dt = (last != null && p.timestamp > last)
        ? (p.timestamp - last) / 1000.0
        : config.fallbackDt;
    _lastTimestamp = p.timestamp;
    _lastRaw = p;
    final cur = _apply(p, dt);
    final prev = _lastFiltered ?? cur;
    _lastFiltered = cur;

    final spacing = math.max(config.spacing, 0.01);
    final out = <DrawingPoint>[];
    var from = _lastEmitted ?? prev;
    var segStart = prev;
    var segLen = _dist(segStart, cur);
    while (segLen > 0) {
      final remaining = math.max(0.0, spacing - _dist(from, segStart));
      if (remaining > segLen) break;
      final next = _lerp(segStart, cur, remaining / segLen);
      out.add(next);
      from = next;
      segStart = next;
      segLen = _dist(next, cur);
    }
    if (out.isNotEmpty) _lastEmitted = out.last;
    return out;
  }

  /// Ends the stroke; returns the raw last point so the stroke finishes
  /// exactly where the pen lifted, or null if it was already emitted.
  DrawingPoint? end() {
    final raw = _lastRaw;
    final le = _lastEmitted;
    if (raw == null || (le != null && _dist(raw, le) < 1e-9)) return null;
    _lastEmitted = raw;
    return raw;
  }

  DrawingPoint _apply(DrawingPoint p, double dt) => DrawingPoint(
        x: _fx.filter(p.x, dt),
        y: _fy.filter(p.y, dt),
        pressure: _fp.filter(p.pressure, dt),
        tilt: p.tilt,
        timestamp: p.timestamp,
      );

  static double _dist(DrawingPoint a, DrawingPoint b) =>
      math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

  static DrawingPoint _lerp(DrawingPoint a, DrawingPoint b, double t) =>
      DrawingPoint(
        x: a.x + (b.x - a.x) * t,
        y: a.y + (b.y - a.y) * t,
        pressure: a.pressure + (b.pressure - a.pressure) * t,
        tilt: a.tilt + (b.tilt - a.tilt) * t,
        timestamp: (a.timestamp + (b.timestamp - a.timestamp) * t).round(),
      );
}
