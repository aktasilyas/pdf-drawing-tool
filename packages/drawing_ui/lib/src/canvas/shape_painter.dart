import 'dart:math';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';

/// Shape rendering painter
class ShapePainter extends CustomPainter {
  /// Committed shapes
  final List<Shape> shapes;

  /// Preview shape (active drawing)
  final Shape? activeShape;

  // Cached paint object (performans için)
  static final Paint _paint = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  /// Constructor
  ShapePainter({
    required this.shapes,
    this.activeShape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Committed shapes
    for (final shape in shapes) {
      _drawShape(canvas, shape);
    }

    // Active shape (preview)
    if (activeShape != null) {
      _drawShape(canvas, activeShape!, isPreview: true);
    }
  }

  void _drawShape(Canvas canvas, Shape shape, {bool isPreview = false}) {
    // Paint ayarla
    _paint.color = Color(shape.style.color).withOpacity(
      isPreview ? 0.5 : shape.style.opacity,
    );
    _paint.strokeWidth = shape.style.thickness;
    _paint.style = shape.isFilled ? PaintingStyle.fill : PaintingStyle.stroke;

    switch (shape.type) {
      case ShapeType.line:
        _drawLine(canvas, shape);
        break;
      case ShapeType.rectangle:
        _drawRectangle(canvas, shape);
        break;
      case ShapeType.ellipse:
        _drawEllipse(canvas, shape);
        break;
      case ShapeType.arrow:
        _drawArrow(canvas, shape);
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

  @override
  bool shouldRepaint(covariant ShapePainter oldDelegate) {
    return oldDelegate.shapes != shapes ||
        oldDelegate.activeShape != activeShape;
  }
}
