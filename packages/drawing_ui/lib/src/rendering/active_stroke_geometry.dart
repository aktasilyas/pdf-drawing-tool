import 'dart:math' as math;
import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';

import 'flutter_stroke_renderer.dart';
import 'variable_width_renderer.dart';

/// How [ActiveStrokeGeometry] renders the live stroke.
enum ActiveStrokeMode {
  /// Pressure-sensitive pens: frozen outline chunks plus a recomputed tail.
  outline,

  /// Solid stroked pens: quadratic segments appended one by one.
  stroked,

  /// Dashed, pencil, straight line: rebuilt from all points (O(n)).
  fallback,
}

/// Geometry of the stroke being drawn, updated incrementally per input event.
///
/// The work per [sync] depends on the number of new points, not on the stroke
/// length (modes [ActiveStrokeMode.outline] and [ActiveStrokeMode.stroked]).
/// Styles that cannot be built incrementally use the legacy renderer.
class ActiveStrokeGeometry {
  ActiveStrokeGeometry({FlutterStrokeRenderer? renderer})
      : _renderer = renderer ?? FlutterStrokeRenderer();

  /// Frozen outline chunks are at least this many samples long.
  static const int _chunk = 8;

  final FlutterStrokeRenderer _renderer;
  final Path _body = Path();
  final Path _tail = Path();
  final List<double> _scratch = <double>[];
  IncrementalStrokeOutline? _outline;
  Paint? _paint;
  Paint? _layerPaint;
  StrokeStyle? _style;
  List<DrawingPoint> _points = const [];

  ActiveStrokeMode _mode = ActiveStrokeMode.fallback;
  int _consumed = 0;
  int _bodyEnd = -1; // outline: last sample covered by [_body]
  DrawingPoint? _prev;
  double _minX = 0, _minY = 0, _maxX = 0, _maxY = 0;

  /// Bumped on every change; painters compare it in `shouldRepaint`.
  int version = 0;

  ActiveStrokeMode get mode => _mode;

  /// Number of input points folded into the geometry so far.
  int get consumed => _consumed;

  /// Starts a new stroke. [incremental] is false for straight-line previews
  /// and for strokes whose points are rewritten rather than appended.
  void begin(StrokeStyle style, {bool incremental = true}) {
    _style = style;
    _body.reset();
    _tail.reset();
    _consumed = 0;
    _bodyEnd = -1;
    _prev = null;
    _points = const [];
    final dashed =
        style.pattern != StrokePattern.solid && style.dashPattern != null;
    if (!incremental || dashed) {
      _mode = ActiveStrokeMode.fallback;
    } else if (style.pressureSensitive) {
      _mode = ActiveStrokeMode.outline;
      (_outline ??= IncrementalStrokeOutline(
              VariableWidthStrokeRenderer.optionsFor(style)))
          .reset(VariableWidthStrokeRenderer.optionsFor(style));
    } else if (style.texture == StrokeTexture.pencil) {
      _mode = ActiveStrokeMode.fallback;
    } else {
      _mode = ActiveStrokeMode.stroked;
    }
    _configurePaints(style);
    version++;
  }

  /// Clears the geometry (no stroke). Call [begin] before the next [sync].
  void clear() {
    _style = null;
    _body.reset();
    _tail.reset();
    _points = const [];
    _consumed = 0;
    _prev = null;
    version++;
  }

  void _configurePaints(StrokeStyle style) {
    final Paint paint;
    if (_mode == ActiveStrokeMode.outline) {
      paint = VariableWidthStrokeRenderer.fillPaintFor(style);
    } else {
      paint = _renderer.strokePaintFor(style);
    }
    final translucent =
        style.opacity < 1 || style.blendMode != DrawingBlendMode.normal;
    if (translucent && _mode != ActiveStrokeMode.fallback) {
      // Draw opaque into a layer, then composite once, so the overlap of
      // body and tail does not darken (same as a committed stroke).
      _layerPaint = Paint()
        ..blendMode = paint.blendMode
        ..color = Color(0xFF000000).withValues(alpha: style.opacity);
      paint
        ..color = paint.color.withValues(alpha: 1)
        ..blendMode = BlendMode.srcOver;
    } else {
      _layerPaint = null;
    }
    _paint = paint;
  }

  /// Brings the geometry up to date with [points], the controller's list.
  ///
  /// Appends only the points not seen yet. If [points] shrank, or the mode is
  /// [ActiveStrokeMode.fallback], the stroke is rebuilt from scratch.
  void sync(List<DrawingPoint> points) {
    _points = points;
    final style = _style;
    if (style == null) return;
    if (points.length < _consumed) {
      begin(style, incremental: _mode != ActiveStrokeMode.fallback);
      _points = points;
    }
    switch (_mode) {
      case ActiveStrokeMode.outline:
        _syncOutline(points);
      case ActiveStrokeMode.stroked:
        _syncStroked(points, style);
      case ActiveStrokeMode.fallback:
        _consumed = points.length;
    }
    version++;
  }

  void _grow(DrawingPoint p) {
    if (_consumed == 0) {
      _minX = _maxX = p.x;
      _minY = _maxY = p.y;
    } else {
      _minX = math.min(_minX, p.x);
      _maxX = math.max(_maxX, p.x);
      _minY = math.min(_minY, p.y);
      _maxY = math.max(_maxY, p.y);
    }
  }

  void _syncOutline(List<DrawingPoint> points) {
    final outline = _outline!;
    if (points.length == _consumed) return;
    final fresh = points.sublist(_consumed);
    for (final p in fresh) {
      _grow(p);
      _consumed++;
    }
    outline.addAll(fresh);

    final to = outline.frozenCount - 1;
    final from = math.max(_bodyEnd, 0);
    if (to - from >= _chunk) {
      _scratch.clear();
      outline.writeFrozen(from, to, _scratch);
      _addPolygon(_body);
      _bodyEnd = to;
    }
    _scratch.clear();
    outline.writeTail(_scratch, from: math.max(_bodyEnd, 0));
    _tail.reset();
    _addPolygon(_tail);
  }

  void _addPolygon(Path path) {
    if (_scratch.length < 6) return;
    path.moveTo(_scratch[0], _scratch[1]);
    for (var i = 2; i < _scratch.length; i += 2) {
      path.lineTo(_scratch[i], _scratch[i + 1]);
    }
    path.close();
  }

  void _syncStroked(List<DrawingPoint> points, StrokeStyle style) {
    for (var i = _consumed; i < points.length; i++) {
      final p = points[i];
      _grow(p);
      if (i == 0) {
        _body.moveTo(p.x, p.y);
      } else if (i >= 2) {
        final q = _prev!;
        _body.quadraticBezierTo(q.x, q.y, (q.x + p.x) / 2, (q.y + p.y) / 2);
      }
      _prev = p;
      _consumed = i + 1;
    }
    _tail.reset();
    final n = points.length;
    if (n == 0) return;
    final last = points[n - 1];
    if (n == 1) {
      _tail.addOval(Rect.fromCircle(
        center: Offset(last.x, last.y),
        radius: style.thickness / 2,
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

  /// Draws the live stroke. Allocates nothing in outline and stroked modes
  /// besides the saveLayer bounds for translucent styles.
  void paint(Canvas canvas) {
    final style = _style;
    if (style == null || _points.isEmpty) return;
    if (_mode == ActiveStrokeMode.fallback) {
      _renderer.renderActiveStroke(canvas, _points, style);
      return;
    }
    final layer = _layerPaint;
    if (layer != null) {
      final pad = style.thickness + style.glowRadius * 2 + 2;
      canvas.saveLayer(
        Rect.fromLTRB(_minX - pad, _minY - pad, _maxX + pad, _maxY + pad),
        layer,
      );
    }
    canvas.drawPath(_body, _paint!);
    canvas.drawPath(_tail, _paint!);
    if (layer != null) canvas.restore();
  }
}
