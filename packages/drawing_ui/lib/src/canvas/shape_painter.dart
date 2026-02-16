import 'dart:math';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';

/// Shape rendering painter
class ShapePainter extends CustomPainter {
  /// Committed shapes
  final List<Shape> shapes;

  /// Preview shape (active drawing)
  final Shape? activeShape;

  /// Shape IDs to skip rendering (used during live selection move/rotate).
  final Set<String> excludedShapeIds;

  // Cached paint object (performans için)
  static final Paint _paint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  /// Constructor
  ShapePainter({
    required this.shapes,
    this.activeShape,
    this.excludedShapeIds = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Committed shapes
    for (final shape in shapes) {
      if (excludedShapeIds.contains(shape.id)) continue;
      _drawShape(canvas, shape);
    }

    // Active shape (preview)
    if (activeShape != null) {
      _drawShape(canvas, activeShape!, isPreview: true);
    }
  }

  void _drawShape(Canvas canvas, Shape shape, {bool isPreview = false}) {
    final previewOpacity = isPreview ? 0.5 : 1.0;

    // Filled shapes: önce dolgu, sonra kontur çiz
    if (shape.isFilled) {
      // Dolgu rengi
      final fillColorValue = shape.fillColor ?? shape.style.color;
      _paint.color = Color(fillColorValue).withValues(alpha: previewOpacity);
      _paint.style = PaintingStyle.fill;
      _drawShapeByType(canvas, shape);

      // Kontur çiz (stroke)
      _paint.color = Color(shape.style.color).withValues(
        alpha: shape.style.opacity * previewOpacity,
      );
      _paint.strokeWidth = shape.style.thickness;
      _paint.style = PaintingStyle.stroke;
      _drawShapeByType(canvas, shape);
    } else {
      // Sadece kontur
      _paint.color = Color(shape.style.color).withValues(
        alpha: shape.style.opacity * previewOpacity,
      );
      _paint.strokeWidth = shape.style.thickness;
      _paint.style = PaintingStyle.stroke;
      _drawShapeByType(canvas, shape);
    }
  }

  void _drawShapeByType(Canvas canvas, Shape shape) {
    switch (shape.type) {
      case ShapeType.line:
        _drawLine(canvas, shape);
        break;
      case ShapeType.arrow:
        _drawArrow(canvas, shape);
        break;
      case ShapeType.rectangle:
        _drawRectangle(canvas, shape);
        break;
      case ShapeType.ellipse:
        _drawEllipse(canvas, shape);
        break;
      case ShapeType.triangle:
        _drawTriangle(canvas, shape);
        break;
      case ShapeType.diamond:
        _drawDiamond(canvas, shape);
        break;
      case ShapeType.star:
        _drawStar(canvas, shape);
        break;
      case ShapeType.pentagon:
        _drawPolygon(canvas, shape, 5);
        break;
      case ShapeType.hexagon:
        _drawPolygon(canvas, shape, 6);
        break;
      case ShapeType.plus:
        _drawPlus(canvas, shape);
        break;
    }
  }

  void _drawLine(Canvas canvas, Shape shape) {
    canvas.drawLine(
      Offset(shape.startPoint.x, shape.startPoint.y),
      Offset(shape.endPoint.x, shape.endPoint.y),
      _paint,
    );
  }

  void _drawRectangle(Canvas canvas, Shape shape) {
    final rect = Rect.fromPoints(
      Offset(shape.startPoint.x, shape.startPoint.y),
      Offset(shape.endPoint.x, shape.endPoint.y),
    );
    canvas.drawRect(rect, _paint);
  }

  void _drawEllipse(Canvas canvas, Shape shape) {
    final rect = Rect.fromPoints(
      Offset(shape.startPoint.x, shape.startPoint.y),
      Offset(shape.endPoint.x, shape.endPoint.y),
    );
    canvas.drawOval(rect, _paint);
  }

  void _drawArrow(Canvas canvas, Shape shape) {
    final start = Offset(shape.startPoint.x, shape.startPoint.y);
    final end = Offset(shape.endPoint.x, shape.endPoint.y);

    // Ana çizgi
    canvas.drawLine(start, end, _paint);

    // Ok başı hesapla
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);

    if (length < 10) return;

    final unitX = dx / length;
    final unitY = dy / length;

    final arrowHeadSize = shape.style.thickness * 4;

    // Ok başı tabanı
    final baseX = end.dx - unitX * arrowHeadSize;
    final baseY = end.dy - unitY * arrowHeadSize;

    // Perpendicular (dik) vektör
    final perpX = -unitY * arrowHeadSize * 0.5;
    final perpY = unitX * arrowHeadSize * 0.5;

    // Ok başı üçgeni
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(baseX + perpX, baseY + perpY)
      ..lineTo(baseX - perpX, baseY - perpY)
      ..close();

    // Ok başı dolgulu çiz
    final fillPaint = Paint()
      ..color = _paint.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, fillPaint);
  }

  void _drawTriangle(Canvas canvas, Shape shape) {
    final left = min(shape.startPoint.x, shape.endPoint.x);
    final right = max(shape.startPoint.x, shape.endPoint.x);
    final top = min(shape.startPoint.y, shape.endPoint.y);
    final bottom = max(shape.startPoint.y, shape.endPoint.y);

    final path = Path()
      ..moveTo((left + right) / 2, top) // Top center
      ..lineTo(left, bottom) // Bottom left
      ..lineTo(right, bottom) // Bottom right
      ..close();
    canvas.drawPath(path, _paint);
  }

  void _drawDiamond(Canvas canvas, Shape shape) {
    final cx = (shape.startPoint.x + shape.endPoint.x) / 2;
    final cy = (shape.startPoint.y + shape.endPoint.y) / 2;
    final hw = (shape.endPoint.x - shape.startPoint.x).abs() / 2;
    final hh = (shape.endPoint.y - shape.startPoint.y).abs() / 2;

    final path = Path()
      ..moveTo(cx, cy - hh) // Top
      ..lineTo(cx + hw, cy) // Right
      ..lineTo(cx, cy + hh) // Bottom
      ..lineTo(cx - hw, cy) // Left
      ..close();
    canvas.drawPath(path, _paint);
  }

  void _drawStar(Canvas canvas, Shape shape) {
    final cx = (shape.startPoint.x + shape.endPoint.x) / 2;
    final cy = (shape.startPoint.y + shape.endPoint.y) / 2;
    final rx = (shape.endPoint.x - shape.startPoint.x).abs() / 2;
    final ry = (shape.endPoint.y - shape.startPoint.y).abs() / 2;
    final radius = min(rx, ry);
    final innerRadius = radius * 0.4;

    final path = Path();
    const points = 5;

    for (int i = 0; i < points * 2; i++) {
      final rScale = i.isEven ? 1.0 : (innerRadius / radius);
      final angle = (i * pi / points) - pi / 2;
      final x = cx + (rx * rScale) * cos(angle);
      final y = cy + (ry * rScale) * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, _paint);
  }

  void _drawPolygon(Canvas canvas, Shape shape, int sides) {
    final cx = (shape.startPoint.x + shape.endPoint.x) / 2;
    final cy = (shape.startPoint.y + shape.endPoint.y) / 2;
    final rx = (shape.endPoint.x - shape.startPoint.x).abs() / 2;
    final ry = (shape.endPoint.y - shape.startPoint.y).abs() / 2;

    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      final x = cx + rx * cos(angle);
      final y = cy + ry * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, _paint);
  }

  void _drawPlus(Canvas canvas, Shape shape) {
    final left = min(shape.startPoint.x, shape.endPoint.x);
    final right = max(shape.startPoint.x, shape.endPoint.x);
    final top = min(shape.startPoint.y, shape.endPoint.y);
    final bottom = max(shape.startPoint.y, shape.endPoint.y);
    final cx = (left + right) / 2;
    final cy = (top + bottom) / 2;

    // Vertical line
    canvas.drawLine(Offset(cx, top), Offset(cx, bottom), _paint);
    // Horizontal line
    canvas.drawLine(Offset(left, cy), Offset(right, cy), _paint);
  }

  @override
  bool shouldRepaint(covariant ShapePainter oldDelegate) {
    return oldDelegate.shapes != shapes ||
        oldDelegate.activeShape != activeShape ||
        !identical(oldDelegate.excludedShapeIds, excludedShapeIds);
  }
}
