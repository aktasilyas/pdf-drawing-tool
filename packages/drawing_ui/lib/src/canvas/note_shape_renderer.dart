import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

/// Renders [Shape]s inside sticky notes using Canvas drawing primitives.
///
/// Mirrors the drawing logic from [ShapePainter] but is callable
/// standalone for use inside clipped/translated note regions.
class NoteShapeRenderer {
  NoteShapeRenderer._();

  static final Paint _paint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  /// Draws a single [Shape] onto [canvas].
  static void drawShape(Canvas canvas, Shape shape) {
    if (shape.isFilled) {
      final fillColorValue = shape.fillColor ?? shape.style.color;
      _paint.color = Color(fillColorValue);
      _paint.style = PaintingStyle.fill;
      _drawByType(canvas, shape);

      _paint.color =
          Color(shape.style.color).withValues(alpha: shape.style.opacity);
      _paint.strokeWidth = shape.style.thickness;
      _paint.style = PaintingStyle.stroke;
      _drawByType(canvas, shape);
    } else {
      _paint.color =
          Color(shape.style.color).withValues(alpha: shape.style.opacity);
      _paint.strokeWidth = shape.style.thickness;
      _paint.style = PaintingStyle.stroke;
      _drawByType(canvas, shape);
    }
  }

  static void _drawByType(Canvas canvas, Shape shape) {
    final s = Offset(shape.startPoint.x, shape.startPoint.y);
    final e = Offset(shape.endPoint.x, shape.endPoint.y);
    switch (shape.type) {
      case ShapeType.line:
        canvas.drawLine(s, e, _paint);
      case ShapeType.arrow:
        _drawArrow(canvas, s, e, shape.style.thickness);
      case ShapeType.rectangle:
        canvas.drawRect(Rect.fromPoints(s, e), _paint);
      case ShapeType.ellipse:
        canvas.drawOval(Rect.fromPoints(s, e), _paint);
      case ShapeType.triangle:
        _drawTriangle(canvas, s, e);
      case ShapeType.diamond:
        _drawDiamond(canvas, s, e);
      case ShapeType.star:
        _drawStar(canvas, s, e);
      case ShapeType.pentagon:
        _drawPolygon(canvas, s, e, 5);
      case ShapeType.hexagon:
        _drawPolygon(canvas, s, e, 6);
      case ShapeType.plus:
        _drawPlus(canvas, s, e);
    }
  }

  static void _drawArrow(
      Canvas canvas, Offset s, Offset e, double thickness) {
    canvas.drawLine(s, e, _paint);
    final dx = e.dx - s.dx;
    final dy = e.dy - s.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 10) return;
    final ux = dx / len, uy = dy / len;
    final hs = thickness * 4;
    final bx = e.dx - ux * hs, by = e.dy - uy * hs;
    final px = -uy * hs * 0.5, py = ux * hs * 0.5;
    final path = Path()
      ..moveTo(e.dx, e.dy)
      ..lineTo(bx + px, by + py)
      ..lineTo(bx - px, by - py)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = _paint.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true);
  }

  static void _drawTriangle(Canvas canvas, Offset s, Offset e) {
    final l = math.min(s.dx, e.dx), r = math.max(s.dx, e.dx);
    final t = math.min(s.dy, e.dy), b = math.max(s.dy, e.dy);
    final path = Path()
      ..moveTo((l + r) / 2, t)
      ..lineTo(l, b)
      ..lineTo(r, b)
      ..close();
    canvas.drawPath(path, _paint);
  }

  static void _drawDiamond(Canvas canvas, Offset s, Offset e) {
    final cx = (s.dx + e.dx) / 2, cy = (s.dy + e.dy) / 2;
    final hw = (e.dx - s.dx).abs() / 2, hh = (e.dy - s.dy).abs() / 2;
    final path = Path()
      ..moveTo(cx, cy - hh)
      ..lineTo(cx + hw, cy)
      ..lineTo(cx, cy + hh)
      ..lineTo(cx - hw, cy)
      ..close();
    canvas.drawPath(path, _paint);
  }

  static void _drawStar(Canvas canvas, Offset s, Offset e) {
    final cx = (s.dx + e.dx) / 2, cy = (s.dy + e.dy) / 2;
    final rx = (e.dx - s.dx).abs() / 2, ry = (e.dy - s.dy).abs() / 2;
    final radius = math.min(rx, ry);
    final innerR = radius * 0.4;
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final rScale = i.isEven ? 1.0 : (innerR / radius);
      final a = (i * math.pi / 5) - math.pi / 2;
      final x = cx + (rx * rScale) * math.cos(a);
      final y = cy + (ry * rScale) * math.sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, _paint);
  }

  static void _drawPolygon(Canvas canvas, Offset s, Offset e, int sides) {
    final cx = (s.dx + e.dx) / 2, cy = (s.dy + e.dy) / 2;
    final rx = (e.dx - s.dx).abs() / 2, ry = (e.dy - s.dy).abs() / 2;
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final a = (i * 2 * math.pi / sides) - math.pi / 2;
      final x = cx + rx * math.cos(a);
      final y = cy + ry * math.sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, _paint);
  }

  static void _drawPlus(Canvas canvas, Offset s, Offset e) {
    final l = math.min(s.dx, e.dx), r = math.max(s.dx, e.dx);
    final t = math.min(s.dy, e.dy), b = math.max(s.dy, e.dy);
    final cx = (l + r) / 2, cy = (t + b) / 2;
    canvas.drawLine(Offset(cx, t), Offset(cx, b), _paint);
    canvas.drawLine(Offset(l, cy), Offset(r, cy), _paint);
  }
}
