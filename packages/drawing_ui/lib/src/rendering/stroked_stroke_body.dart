import 'dart:math' as math;
import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';

/// Live path geometry of a solid stroked pen, built one quadratic segment at
/// a time (same curve as `FlutterStrokeRenderer`'s committed path).
///
/// The body is frozen every [chunk] segments, so the live (mutated) path
/// stays short and per-event work does not grow with the stroke.
///
/// Round caps: chunk joints sit at quadratic end points where neighbouring
/// segments share the tangent, so the round caps meet like the round join.
///
/// Square caps (rectangle nib, e.g. highlighter) would poke out at joints on
/// tight turns, so chunks and body are drawn butt-capped instead, and every
/// new live body repeats the last frozen segment: each butt end then lies
/// inside the neighbouring chunk and no anti-aliased seam shows. The square
/// start cap is drawn as its own path ([paint]'s `chunkPaint`), and the end
/// cap comes from the tail, which keeps the style's cap.
class StrokedStrokeBody {
  /// Segments per frozen chunk.
  static const int chunk = 32;

  /// How far the start cap reaches into the body, past the first point, so
  /// its butt end is covered (page units; the curve barely deviates from its
  /// tangent over this length).
  static const double _capOverlap = 1;

  Path _body = Path();
  final Path _tail = Path();
  final Path _startCap = Path();
  final List<Path> _frozen = <Path>[]; // never mutated again

  bool _overlap = false; // non-round caps: repeat a segment after a freeze
  bool _squareStart = false; // draw [_startCap]
  bool _capPending = false; // start cap direction not known yet
  double _halfWidth = 0;
  DrawingPoint? _prev;
  double _startX = 0, _startY = 0; // first point
  double _bodyX = 0, _bodyY = 0; // current end point of [_body]
  double _segX = 0, _segY = 0; // start point of the last segment
  int _segments = 0; // segments in [_body] since the last freeze

  /// Segments in the live (not yet frozen) body path.
  int get liveSegments => _segments;

  /// Number of body chunks frozen so far.
  int get frozenChunks => _frozen.length;

  /// Starts an empty stroke drawn with [cap] at [thickness].
  void reset({required StrokeCap cap, required double thickness}) {
    _overlap = cap != StrokeCap.round;
    _squareStart = cap == StrokeCap.square;
    _halfWidth = thickness / 2;
    _body.reset();
    _tail.reset();
    _startCap.reset();
    _capPending = false;
    _prev = null;
    dropFrozen();
  }

  /// Drops the frozen chunks (end of stroke). The live body is kept.
  void dropFrozen() {
    _segments = 0;
    _frozen.clear();
  }

  /// Appends input point [i] (0-based) of the stroke.
  void add(int i, DrawingPoint p) {
    if (i == 0) {
      _body.moveTo(p.x, p.y);
      _startX = _bodyX = p.x;
      _startY = _bodyY = p.y;
      _capPending = _squareStart;
    } else {
      if (_capPending) _tryStartCap(p);
      if (i >= 2) {
        final q = _prev!;
        _segX = _bodyX;
        _segY = _bodyY;
        _bodyX = (q.x + p.x) / 2;
        _bodyY = (q.y + p.y) / 2;
        _body.quadraticBezierTo(q.x, q.y, _bodyX, _bodyY);
        if (++_segments >= chunk) _freeze(q);
      }
    }
    _prev = p;
  }

  /// The square cap at the first point points back along the initial tangent,
  /// which is the direction to the first point that differs from it.
  void _tryStartCap(DrawingPoint p) {
    final dx = p.x - _startX;
    final dy = p.y - _startY;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final ux = dx / len;
    final uy = dy / len;
    _startCap
      ..moveTo(_startX - ux * _halfWidth, _startY - uy * _halfWidth)
      ..lineTo(_startX + ux * _capOverlap, _startY + uy * _capOverlap);
    _capPending = false;
  }

  /// Freezes [_body]; [control] is the control point of its last segment.
  void _freeze(DrawingPoint control) {
    _frozen.add(_body);
    _body = Path();
    if (_overlap) {
      _body
        ..moveTo(_segX, _segY)
        ..quadraticBezierTo(control.x, control.y, _bodyX, _bodyY);
      _segments = 1;
    } else {
      _body.moveTo(_bodyX, _bodyY);
      _segments = 0;
    }
  }

  /// Rebuilds the tail from the end of the body to the last of [points].
  void updateTail(List<DrawingPoint> points, double thickness) {
    _tail.reset();
    final n = points.length;
    if (n == 0) return;
    final last = points[n - 1];
    if (n == 1) {
      _tail.addOval(Rect.fromCircle(
        center: Offset(last.x, last.y),
        radius: thickness / 2,
      ));
    } else if (n == 2) {
      _tail.moveTo(points[0].x, points[0].y);
      _tail.lineTo(last.x, last.y);
    } else {
      final q = points[n - 2];
      _tail.moveTo((q.x + last.x) / 2, (q.y + last.y) / 2);
      _tail.lineTo(last.x, last.y);
    }
  }

  /// Draws chunks, body and start cap with [chunkPaint] (butt cap for
  /// non-round styles) and the tail with [paint] (the style's cap).
  /// Allocates nothing.
  void paint(Canvas canvas, Paint paint, Paint chunkPaint) {
    for (var i = 0; i < _frozen.length; i++) {
      canvas.drawPath(_frozen[i], chunkPaint);
    }
    canvas.drawPath(_body, chunkPaint);
    if (_squareStart) canvas.drawPath(_startCap, chunkPaint);
    canvas.drawPath(_tail, paint);
  }
}
