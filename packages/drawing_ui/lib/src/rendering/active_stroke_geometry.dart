import 'dart:math' as math;
import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'flutter_stroke_renderer.dart';
import 'stroked_stroke_body.dart';
import 'variable_width_renderer.dart';

/// How [ActiveStrokeGeometry] renders the live stroke.
enum ActiveStrokeMode {
  /// Outline pens (pressure or tapered): frozen outline chunks plus a recomputed tail.
  outline,

  /// Solid stroked pens: quadratic segments appended one by one; the body
  /// is frozen every [ActiveStrokeGeometry.strokedChunk] segments so the
  /// live (mutated) path stays short (see [StrokedStrokeBody]).
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

  /// Stroked mode freezes the live body path every this many
  /// quadratic segments, so per-event work does not grow with the stroke.
  static const int strokedChunk = StrokedStrokeBody.chunk;

  final FlutterStrokeRenderer _renderer;
  final Path _body = Path(); // outline: frozen polygons
  final Path _tail = Path(); // outline: recomputed tail
  final StrokedStrokeBody _stroked = StrokedStrokeBody();
  final List<double> _scratch = <double>[];
  IncrementalStrokeOutline? _outline;
  Paint? _paint;
  Paint? _chunkPaint; // stroked: butt-capped copy of [_paint] for chunks
  Paint? _layerPaint;
  StrokeStyle? _style;
  List<DrawingPoint> _points = const [];

  ActiveStrokeMode _mode = ActiveStrokeMode.fallback;
  int _consumed = 0;
  int _bodyEnd = -1; // outline: last sample covered by [_body]
  double _minX = 0, _minY = 0, _maxX = 0, _maxY = 0;

  /// Bumped on every change; painters compare it in `shouldRepaint`.
  int version = 0;

  ActiveStrokeMode get mode => _mode;

  /// Number of input points folded into the geometry so far.
  int get consumed => _consumed;

  /// Stroked mode: segments in the live (not yet frozen) body path.
  @visibleForTesting
  int get liveSegments => _stroked.liveSegments;

  /// Stroked mode: number of body chunks frozen so far.
  @visibleForTesting
  int get frozenChunks => _stroked.frozenChunks;

  /// Starts a new stroke. [incremental] is false for straight-line previews
  /// and for strokes whose points are rewritten rather than appended.
  void begin(StrokeStyle style, {bool incremental = true}) {
    _style = style;
    _body.reset();
    _tail.reset();
    _consumed = 0;
    _bodyEnd = -1;
    _points = const [];
    final dashed =
        style.pattern != StrokePattern.solid && style.dashPattern != null;
    if (!incremental || dashed) {
      _mode = ActiveStrokeMode.fallback;
    } else if (style.texture == StrokeTexture.pencil) {
      _mode = ActiveStrokeMode.fallback;
    } else if (VariableWidthStrokeRenderer.usesOutline(style)) {
      _mode = ActiveStrokeMode.outline;
      (_outline ??= IncrementalStrokeOutline(
              VariableWidthStrokeRenderer.optionsFor(style)))
          .reset(VariableWidthStrokeRenderer.optionsFor(style));
    } else {
      _mode = ActiveStrokeMode.stroked;
    }
    _configurePaints(style);
    _stroked.reset(cap: _paint!.strokeCap, thickness: style.thickness);
    version++;
  }

  /// Clears the geometry (no stroke). Call [begin] before the next [sync].
  void clear() {
    _style = null;
    _body.reset();
    _tail.reset();
    _points = const [];
    _consumed = 0;
    _stroked.dropFrozen();
    version++;
  }

  /// Drops the frozen chunks. The geometry stays usable.
  void dispose() => _stroked.dropFrozen();

  void _configurePaints(StrokeStyle style) {
    final translucent =
        style.opacity < 1 || style.blendMode != DrawingBlendMode.normal;
    final layered = translucent && _mode != ActiveStrokeMode.fallback;
    final paint = _buildPaint(style, layered);
    if (layered) {
      // Draw opaque into a layer, then composite once, so overlapping
      // chunks, body and tail do not darken (same as a committed stroke).
      _layerPaint = Paint()
        ..blendMode = paint.blendMode
        ..color = Color(0xFF000000).withValues(alpha: style.opacity);
      paint.blendMode = BlendMode.srcOver;
    } else {
      _layerPaint = null;
    }
    _paint = paint;
    final squareish = paint.strokeCap != StrokeCap.round;
    if (_mode == ActiveStrokeMode.stroked && squareish) {
      _chunkPaint = _buildPaint(style, layered)
        ..blendMode = paint.blendMode
        ..strokeCap = StrokeCap.butt;
    } else {
      _chunkPaint = paint;
    }
  }

  /// The style's paint; opaque colour when it is drawn into a layer.
  Paint _buildPaint(StrokeStyle style, bool layered) {
    final paint = _mode == ActiveStrokeMode.outline
        ? VariableWidthStrokeRenderer.fillPaintFor(style)
        : _renderer.strokePaintFor(style);
    if (layered) paint.color = paint.color.withValues(alpha: 1);
    return paint;
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
      _stroked.add(i, p);
      _consumed = i + 1;
    }
    _stroked.updateTail(points, style.thickness);
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
    if (_mode == ActiveStrokeMode.stroked) {
      _stroked.paint(canvas, _paint!, _chunkPaint!);
    } else {
      canvas.drawPath(_body, _paint!);
      canvas.drawPath(_tail, _paint!);
    }
    if (layer != null) canvas.restore();
  }
}
