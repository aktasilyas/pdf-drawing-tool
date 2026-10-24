import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drawing_core/src/input/outline_math.dart';
import 'package:drawing_core/src/input/stroke_outline.dart';
import 'package:drawing_core/src/models/drawing_point.dart';
import 'package:drawing_core/src/models/selection.dart';

/// Streaming version of [StrokeOutline.build].
///
/// Points are appended as they arrive. Every stage of the outline (streamline,
/// arc length, radius, moving averages, slope clamp, tangent) is causal except
/// for the backward moving average, the end taper and the end tangent. Only a
/// short tail window is therefore recomputed per call; samples further back are
/// "frozen" and never touched again. The work per call depends on the options
/// and the number of new points, never on the stroke length.
///
/// The result equals `StrokeOutline.build(allPointsSoFar, options)` up to a
/// truncation error of about 1e-6 of the stroke radius.
///
/// The backward slope clamp of the batch algorithm is a no-op after the
/// forward clamp (the constraint is symmetric), so it is not repeated here.
class IncrementalStrokeOutline {
  /// Backward moving-average influence below which a sample is frozen.
  static const double _truncation = 1e-6;

  StrokeOutlineOptions _o;
  late double _half, _minR, _k, _alpha;
  late int _kEma;

  final List<OutlinePoint> _c = [];
  final _Buf _arc = _Buf(), _rr = _Buf(), _f = _Buf(), _b = _Buf();
  final _Buf _r = _Buf(), _tx = _Buf(), _ty = _Buf();
  DrawingPoint? _last;
  bool _hasEnd = false; // The last sample is the ephemeral true end point.
  int _frozen = 0;
  int _recomputed = 0;

  IncrementalStrokeOutline(StrokeOutlineOptions options) : _o = options {
    _configure();
  }

  /// Drops all points; optionally switches to new [options].
  void reset([StrokeOutlineOptions? options]) {
    if (options != null) _o = options;
    _c.clear();
    for (final b in [_arc, _rr, _f, _b, _r, _tx, _ty]) {
      b.clear();
    }
    _last = null;
    _hasEnd = false;
    _frozen = 0;
    _recomputed = 0;
    _configure();
  }

  void _configure() {
    _half = _o.size / 2;
    _minR = math.max(_half * outlineMinWidthFactor, 0.01);
    _k = outlineEmaFactor(_o.smoothing);
    _alpha = outlineStreamlineAlpha(_o.streamline);
    _kEma = _k >= 1
        ? 1
        : math.max(1, (math.log(_truncation) / math.log(1 - _k)).ceil());
  }

  /// Number of leading samples whose edges are final.
  int get frozenCount => _frozen;

  /// Samples recomputed by the last [addAll] (test hook for the O(1) claim).
  int get lastRecomputed => _recomputed;

  /// Appends [points] and refreshes the unstable tail. O(new + window).
  void addAll(Iterable<DrawingPoint> points) {
    _dropEnd();
    final minDist = math.max(_minR, 0.05);
    var any = false;
    for (final p in points) {
      any = true;
      _last = p;
      final q = OutlinePoint(p.x, p.y, p.pressure, p.timestamp.toDouble());
      if (_c.isEmpty) {
        _append(q);
        continue;
      }
      final prev = _c.last;
      if (outlineDist(prev, q) < minDist) continue;
      _append(OutlinePoint(
        prev.x + (q.x - prev.x) * _alpha,
        prev.y + (q.y - prev.y) * _alpha,
        q.pressure,
        q.t,
      ));
    }
    if (!any && _last == null) return;
    // Keep the true end point so strokes land where the pen lifted.
    final last = _last!;
    final accepted = _c.length;
    if (accepted > 1 && (_c.last.x != last.x || _c.last.y != last.y)) {
      final q = OutlinePoint(
          last.x, last.y, last.pressure, last.timestamp.toDouble());
      if (outlineDist(_c.last, q) >= _minR) {
        _append(q);
        _hasEnd = true;
      }
    }
    _recompute();
    _freeze(accepted);
  }

  void _dropEnd() {
    if (!_hasEnd) return;
    _c.removeLast();
    for (final b in [_arc, _rr, _f, _b, _r, _tx, _ty]) {
      b.removeLast();
    }
    _hasEnd = false;
  }

  void _append(OutlinePoint q) {
    final i = _c.length;
    _c.add(q);
    _arc.add(i == 0 ? 0 : _arc[i - 1] + outlineDist(_c[i - 1], q));
    if (i == 0) {
      _rr.add(0);
    } else {
      _rr.add(_rawRadius(q.pressure, outlineSpeed(_c[i - 1], q)));
      // The first sample takes its speed from the second one.
      if (i == 1) _rr[0] = _rawRadius(_c[0].pressure, outlineSpeed(_c[0], q));
    }
    for (final b in [_f, _b, _r, _tx, _ty]) {
      b.add(0);
    }
  }

  double _rawRadius(double pressure, double speed) =>
      outlineRadius(_half, _o.thinning, _o.velocityThinning, pressure, speed);

  /// Recomputes every stage for samples [_frozen, n).
  void _recompute() {
    final n = _c.length;
    _recomputed = n - _frozen;
    if (n < 2) return;
    final total = _arc[n - 1];
    for (var i = _frozen; i < n; i++) {
      final taper = outlineTaper(_arc[i], total, _o.taperStart, _o.taperEnd);
      final r = math.max(_rr[i] * taper, _minR);
      _f[i] = i == 0 ? r : _k * r + (1 - _k) * _f[i - 1];
    }
    _b[n - 1] = _f[n - 1];
    for (var i = n - 2; i >= _frozen; i--) {
      _b[i] = _k * _f[i] + (1 - _k) * _b[i + 1];
    }
    for (var i = _frozen; i < n; i++) {
      if (i == 0) {
        _r[0] = _b[0];
        continue;
      }
      final lim = (_arc[i] - _arc[i - 1]) * outlineSlope;
      _r[i] = _b[i].clamp(_r[i - 1] - lim, _r[i - 1] + lim);
    }
    for (var i = _frozen; i < n; i++) {
      final t = outlineTangent(_c, i);
      _tx[i] = t.x;
      _ty[i] = t.y;
    }
  }

  /// Freezes samples that the end of the stroke can no longer influence.
  /// [accepted] excludes the ephemeral end point, whose arc can shrink later.
  void _freeze(int accepted) {
    if (accepted < 2) return;
    final end = _arc[accepted - 1];
    while (
        accepted - 1 - _frozen >= _kEma && end - _arc[_frozen] >= _o.taperEnd) {
      _frozen++;
    }
  }

  /// Appends the closed polygon of frozen samples [from]..[to] to [out] as
  /// interleaved x,y. [from] == 0 includes the start cap.
  void writeFrozen(int from, int to, List<double> out) {
    if (from < 0 || to < from || to >= _frozen) {
      throw RangeError('Frozen range $from..$to outside 0..${_frozen - 1}');
    }
    _ribbon(from, to, false, from == 0, out);
  }

  /// Appends the closed polygon of the unstable tail to [out]: samples from
  /// two before the frozen boundary to the end, plus the end cap (the dot
  /// when there is a single sample).
  void writeTail(List<double> out) {
    final n = _c.length;
    if (n == 0) return;
    if (n == 1) {
      _addAll(out, _dot());
      return;
    }
    final s = math.max(0, _frozen - 2);
    _ribbon(s, n - 1, true, s == 0, out);
  }

  /// The complete polygon, equal to `StrokeOutline.build` on all points.
  List<Point2D> toPolygon() {
    final n = _c.length;
    if (n == 0) return const [];
    if (n == 1) return _dot();
    final out = <double>[];
    _ribbon(0, n - 1, true, true, out);
    return [
      for (var i = 0; i < out.length; i += 2) Point2D(out[i], out[i + 1]),
    ];
  }

  List<Point2D> _dot() {
    final r = _rawRadius(_c[0].pressure, 0);
    return outlineCircle(_c[0].x, _c[0].y, math.max(r, _minR));
  }

  static void _addAll(List<double> out, List<Point2D> pts) {
    for (final p in pts) {
      out
        ..add(p.x)
        ..add(p.y);
    }
  }

  void _ribbon(int from, int to, bool endCap, bool startCap, List<double> out) {
    for (var i = from; i <= to; i++) {
      out
        ..add(_c[i].x - _ty[i] * _r[i])
        ..add(_c[i].y + _tx[i] * _r[i]);
    }
    if (endCap) {
      _addAll(out, outlineCap(_c[to], Point2D(_tx[to], _ty[to]), _r[to], true));
    }
    for (var i = to; i >= from; i--) {
      out
        ..add(_c[i].x + _ty[i] * _r[i])
        ..add(_c[i].y - _tx[i] * _r[i]);
    }
    if (startCap) {
      _addAll(out, outlineCap(_c[0], Point2D(_tx[0], _ty[0]), _r[0], false));
    }
  }
}

/// Growable list of doubles backed by a doubling [Float64List].
class _Buf {
  Float64List _d = Float64List(64);
  int length = 0;

  double operator [](int i) => _d[i];
  void operator []=(int i, double v) => _d[i] = v;

  void add(double v) {
    if (length == _d.length) {
      _d = Float64List(length * 2)..setRange(0, length, _d);
    }
    _d[length++] = v;
  }

  void removeLast() => length--;
  void clear() => length = 0;
}
