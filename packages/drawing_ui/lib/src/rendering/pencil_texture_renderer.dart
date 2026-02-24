import 'dart:math' as math;
import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';

/// Renders strokes with a realistic pencil texture.
///
/// Uses a multi-pass approach:
/// 1. **Soft halo** — wider, slightly blurred, very faint stroke for edge softness
/// 2. **Main body** — stroke at reduced opacity
/// 3. **Core line** — thinner, darker center for depth
/// 4. **Grain dots** — scattered semi-transparent dots along the path for texture
class PencilTextureRenderer {
  final Paint _paint = Paint()
    ..isAntiAlias = true
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// Renders a pencil-textured stroke.
  void render(Canvas canvas, List<DrawingPoint> points, StrokeStyle style) {
    if (points.isEmpty) return;

    final baseColor = Color(style.color);
    final w = style.thickness;
    final opacity = style.opacity;

    // Single point → soft dot
    if (points.length == 1) {
      _paint
        ..style = PaintingStyle.fill
        ..color = baseColor.withValues(alpha: opacity * 0.6)
        ..maskFilter = null;
      canvas.drawCircle(
        Offset(points.first.x, points.first.y),
        w / 2,
        _paint,
      );
      return;
    }

    final path = _buildPath(points, style);

    // Pass 1: Soft edge halo
    _paint
      ..style = PaintingStyle.stroke
      ..color = baseColor.withValues(alpha: opacity * 0.12)
      ..strokeWidth = w * 1.6
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.35);
    canvas.drawPath(path, _paint);

    // Pass 2: Main body
    _paint
      ..color = baseColor.withValues(alpha: opacity * 0.50)
      ..strokeWidth = w
      ..maskFilter = null;
    canvas.drawPath(path, _paint);

    // Pass 3: Core line (darker center)
    _paint
      ..color = baseColor.withValues(alpha: opacity * 0.30)
      ..strokeWidth = w * 0.45;
    canvas.drawPath(path, _paint);

    // Pass 4: Grain texture
    _drawGrain(canvas, points, baseColor, opacity, w);
  }

  /// Draws scattered grain dots along the stroke path for pencil texture.
  ///
  /// Uses a single [Path] of tiny ovals for efficiency (one drawPath call).
  void _drawGrain(
    Canvas canvas,
    List<DrawingPoint> points,
    Color color,
    double opacity,
    double thickness,
  ) {
    final dotRadius = (thickness * 0.12).clamp(0.2, 1.2);
    // Sample at most ~100 points to keep performance smooth
    final step = math.max(1, (points.length / 100).ceil());
    final grainPath = Path();

    for (int i = 0; i < points.length; i += step) {
      final p = points[i];
      // 3 grain dots per sample point
      for (int d = 0; d < 3; d++) {
        final h = _hash(p.x, p.y, i + d * 7919);
        final ox = ((h & 0xFF) / 127.5 - 1.0) * thickness * 0.5;
        final oy = (((h >> 8) & 0xFF) / 127.5 - 1.0) * thickness * 0.5;
        grainPath.addOval(Rect.fromCircle(
          center: Offset(p.x + ox, p.y + oy),
          radius: dotRadius,
        ));
      }
    }

    _paint
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.12 * opacity)
      ..maskFilter = null;
    canvas.drawPath(grainPath, _paint);
  }

  /// Builds a smooth quadratic bezier path from points.
  Path _buildPath(List<DrawingPoint> points, StrokeStyle style) {
    final path = Path();

    if (points.length == 1) {
      path.addOval(Rect.fromCircle(
        center: Offset(points.first.x, points.first.y),
        radius: style.thickness / 2,
      ));
      return path;
    }

    path.moveTo(points.first.x, points.first.y);

    if (points.length == 2) {
      path.lineTo(points.last.x, points.last.y);
      return path;
    }

    for (int i = 1; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.x + p1.x) / 2;
      final midY = (p0.y + p1.y) / 2;
      path.quadraticBezierTo(p0.x, p0.y, midX, midY);
    }
    path.lineTo(points.last.x, points.last.y);
    return path;
  }

  /// Deterministic hash for pseudo-random grain offset.
  int _hash(double x, double y, int i) {
    var h = (x * 374761393).toInt() ^
        (y * 668265263).toInt() ^
        (i * 1274126177);
    h = ((h ^ (h >> 13)) * 1103515245 + 12345) & 0x7FFFFFFF;
    return h;
  }
}
