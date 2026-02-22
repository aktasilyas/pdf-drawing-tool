import 'dart:math' as math;
import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';

/// Renders strokes with pressure-sensitive variable width.
///
/// Builds a filled polygon whose edges follow the stroke path offset by
/// half the computed width at each point, instead of fixed-width stroke.
///
/// Width formula: `max(base*0.15, base * ((1-S) + S*P) * T)`
/// where S = sensitivity, P = pressure, T = taper factor.
class VariableWidthStrokeRenderer {
  final Paint _fillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  /// Renders a variable-width stroke on [canvas].
  void render(Canvas canvas, List<DrawingPoint> points, StrokeStyle style) {
    if (points.isEmpty) return;
    _configurePaint(style);

    final base = style.thickness;
    final s = style.pressureSensitivity;

    if (points.length == 1) {
      final w = _widthAt(base, s, points.first.pressure, 1.0);
      canvas.drawCircle(Offset(points.first.x, points.first.y), w / 2, _fillPaint);
      return;
    }

    if (points.length == 2) {
      _renderTwoPoints(canvas, points, base, s);
      return;
    }

    _renderPolygon(canvas, points, base, s);
  }

  void _configurePaint(StrokeStyle style) {
    _fillPaint
      ..color = Color(style.color).withValues(alpha: style.opacity)
      ..blendMode = _blendMode(style.blendMode)
      ..maskFilter = (style.glowRadius > 0 && style.glowIntensity > 0)
          ? MaskFilter.blur(BlurStyle.normal, style.glowRadius * style.glowIntensity)
          : null;
  }

  /// Two points: trapezoid with rounded caps.
  void _renderTwoPoints(
    Canvas canvas, List<DrawingPoint> pts, double base, double s,
  ) {
    final p0 = pts[0], p1 = pts[1];
    final dx = p1.x - p0.x, dy = p1.y - p0.y;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 0.001) {
      final w = _widthAt(base, s, p0.pressure, 1.0);
      canvas.drawCircle(Offset(p0.x, p0.y), w / 2, _fillPaint);
      return;
    }

    final nx = -dy / len, ny = dx / len;
    final h0 = _widthAt(base, s, p0.pressure, 1.0) / 2;
    final h1 = _widthAt(base, s, p1.pressure, 1.0) / 2;

    final path = Path();
    // Start cap
    _addCap(path, p0.x, p0.y, h0, nx, ny, dx / len, dy / len, true);
    // Left edge to end
    path.lineTo(p1.x + nx * h1, p1.y + ny * h1);
    // End cap
    _addCap(path, p1.x, p1.y, h1, nx, ny, dx / len, dy / len, false);
    // Right edge back
    path.lineTo(p0.x - nx * h0, p0.y - ny * h0);
    path.close();
    canvas.drawPath(path, _fillPaint);
  }

  /// Main polygon rendering for 3+ points.
  void _renderPolygon(
    Canvas canvas, List<DrawingPoint> pts, double base, double s,
  ) {
    final n = pts.length;
    final taperLen = math.min(8, n ~/ 3).toDouble();

    // Pre-compute widths and normals
    final widths = List<double>.generate(n, (i) {
      return _widthAt(base, s, pts[i].pressure, _taper(i, n, taperLen));
    });
    final norms = List<Offset>.generate(n, (i) => _normalAt(pts, i));

    // Build left/right edges
    final left = List<Offset>.generate(n, (i) {
      final hw = widths[i] / 2;
      return Offset(pts[i].x + norms[i].dx * hw, pts[i].y + norms[i].dy * hw);
    });
    final right = List<Offset>.generate(n, (i) {
      final hw = widths[i] / 2;
      return Offset(pts[i].x - norms[i].dx * hw, pts[i].y - norms[i].dy * hw);
    });

    final path = Path();

    // Start cap
    final t0 = _tangentAt(pts, 0);
    _addCap(path, pts[0].x, pts[0].y, widths[0] / 2,
        norms[0].dx, norms[0].dy, t0.dx, t0.dy, true);

    // Left edge with quadratic bezier smoothing
    for (int i = 1; i < n - 1; i++) {
      final mid = Offset(
        (left[i].dx + left[i + 1].dx) / 2,
        (left[i].dy + left[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(left[i].dx, left[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(left[n - 1].dx, left[n - 1].dy);

    // End cap
    final tEnd = _tangentAt(pts, n - 1);
    _addCap(path, pts[n - 1].x, pts[n - 1].y, widths[n - 1] / 2,
        norms[n - 1].dx, norms[n - 1].dy, tEnd.dx, tEnd.dy, false);

    // Right edge reversed with quadratic bezier smoothing
    for (int i = n - 2; i > 0; i--) {
      final mid = Offset(
        (right[i].dx + right[i - 1].dx) / 2,
        (right[i].dy + right[i - 1].dy) / 2,
      );
      path.quadraticBezierTo(right[i].dx, right[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(right[0].dx, right[0].dy);

    path.close();
    canvas.drawPath(path, _fillPaint);
  }

  /// Adds a semicircular cap using two cubic bezier quarter-arcs.
  void _addCap(
    Path path, double cx, double cy, double r,
    double nx, double ny, double tx, double ty,
    bool isStart,
  ) {
    if (r < 0.5) {
      if (isStart) {
        path.moveTo(cx + nx * r, cy + ny * r);
      } else {
        path.lineTo(cx - nx * r, cy - ny * r);
      }
      return;
    }
    const k = 0.5522847498; // kappa for quarter-circle bezier approximation

    if (isStart) {
      // Arc from left-of-normal to right-of-normal through back
      path.moveTo(cx + nx * r, cy + ny * r);
      path.cubicTo(
        cx + nx * r - tx * r * k, cy + ny * r - ty * r * k,
        cx - tx * r + nx * r * k, cy - ty * r + ny * r * k,
        cx - tx * r, cy - ty * r,
      );
      path.cubicTo(
        cx - tx * r - nx * r * k, cy - ty * r - ny * r * k,
        cx - nx * r - tx * r * k, cy - ny * r - ty * r * k,
        cx - nx * r, cy - ny * r,
      );
    } else {
      // Arc from left-edge to right-edge through front
      path.cubicTo(
        cx + nx * r + tx * r * k, cy + ny * r + ty * r * k,
        cx + tx * r + nx * r * k, cy + ty * r + ny * r * k,
        cx + tx * r, cy + ty * r,
      );
      path.cubicTo(
        cx + tx * r - nx * r * k, cy + ty * r - ny * r * k,
        cx - nx * r + tx * r * k, cy - ny * r + ty * r * k,
        cx - nx * r, cy - ny * r,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Math helpers
  // ---------------------------------------------------------------------------

  double _widthAt(double base, double s, double pressure, double taper) {
    return math.max(base * 0.15, base * ((1.0 - s) + s * pressure) * taper);
  }

  /// Taper: easeInQuad (t^2) for first/last [taperLen] points.
  double _taper(int index, int total, double taperLen) {
    if (taperLen <= 0) return 1.0;
    if (index < taperLen) {
      final t = (index + 1) / taperLen;
      return t * t;
    }
    final fromEnd = total - 1 - index;
    if (fromEnd < taperLen) {
      final t = (fromEnd + 1) / taperLen;
      return t * t;
    }
    return 1.0;
  }

  Offset _normalAt(List<DrawingPoint> pts, int i) {
    final t = _tangentAt(pts, i);
    return Offset(-t.dy, t.dx);
  }

  Offset _tangentAt(List<DrawingPoint> pts, int i) {
    double dx, dy;
    if (i == 0) {
      dx = pts[1].x - pts[0].x;
      dy = pts[1].y - pts[0].y;
    } else if (i == pts.length - 1) {
      dx = pts[i].x - pts[i - 1].x;
      dy = pts[i].y - pts[i - 1].y;
    } else {
      dx = pts[i + 1].x - pts[i - 1].x;
      dy = pts[i + 1].y - pts[i - 1].y;
    }
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 0.001) return const Offset(1.0, 0.0);
    return Offset(dx / len, dy / len);
  }

  BlendMode _blendMode(DrawingBlendMode mode) {
    switch (mode) {
      case DrawingBlendMode.normal: return BlendMode.srcOver;
      case DrawingBlendMode.multiply: return BlendMode.multiply;
      case DrawingBlendMode.screen: return BlendMode.screen;
      case DrawingBlendMode.overlay: return BlendMode.overlay;
      case DrawingBlendMode.darken: return BlendMode.darken;
      case DrawingBlendMode.lighten: return BlendMode.lighten;
    }
  }
}
