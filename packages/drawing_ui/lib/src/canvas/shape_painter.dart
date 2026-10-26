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

  /// Renders a single shape onto the canvas.
  ///
  /// This static method allows other painters (e.g. UnifiedElementPainter)
  /// to render shapes without instantiating a ShapePainter.
  static void paintSingleShape(Canvas canvas, Shape shape) {
    _paintShapeImpl(canvas, shape, isPreview: false);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Committed shapes
    for (final shape in shapes) {
      if (excludedShapeIds.contains(shape.id)) continue;
      _paintShapeImpl(canvas, shape);
    }

    // Active shape (preview)
    if (activeShape != null) {
      _paintShapeImpl(canvas, activeShape!, isPreview: true);
    }
  }

  static void _paintShapeImpl(Canvas canvas, Shape shape,
      {bool isPreview = false}) {
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

  static void _drawShapeByType(Canvas canvas, Shape shape) {
    switch (shape.type) {
      case ShapeType.line:
        _drawLine(canvas, shape);
      case ShapeType.arrow:
        _drawArrow(canvas, shape);
      case ShapeType.rectangle:
        _drawRectangle(canvas, shape);
      case ShapeType.ellipse:
        _drawEllipse(canvas, shape);
      case ShapeType.triangle:
      case ShapeType.diamond:
      case ShapeType.star:
      case ShapeType.pentagon:
      case ShapeType.hexagon:
      case ShapeType.plus:
        drawGeometry(canvas, ShapeGeometry.polygonPaths(shape)!, _paint);
    }
  }

  /// Draws [paths] from [ShapeGeometry] with [paint].
  ///
  /// Closed paths become one [Path]; open two-point paths are drawn as lines
  /// so they always render as strokes, whatever the paint style.
  static void drawGeometry(
    Canvas canvas,
    List<ShapeGeometryPath> paths,
    Paint paint,
  ) {
    for (final p in paths) {
      final pts = p.points;
      if (pts.length < 2) continue;
      if (!p.closed && pts.length == 2) {
        canvas.drawLine(
          Offset(pts[0].x, pts[0].y),
          Offset(pts[1].x, pts[1].y),
          paint,
        );
        continue;
      }
      final path = Path()..moveTo(pts.first.x, pts.first.y);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].x, pts[i].y);
      }
      if (p.closed) path.close();
      canvas.drawPath(path, paint);
    }
  }

  static void _drawLine(Canvas canvas, Shape shape) {
    canvas.drawLine(
      Offset(shape.startPoint.x, shape.startPoint.y),
      Offset(shape.endPoint.x, shape.endPoint.y),
      _paint,
    );
  }

  static void _drawRectangle(Canvas canvas, Shape shape) {
    final rect = Rect.fromPoints(
      Offset(shape.startPoint.x, shape.startPoint.y),
      Offset(shape.endPoint.x, shape.endPoint.y),
    );
    canvas.drawRect(rect, _paint);
  }

  static void _drawEllipse(Canvas canvas, Shape shape) {
    final rect = Rect.fromPoints(
      Offset(shape.startPoint.x, shape.startPoint.y),
      Offset(shape.endPoint.x, shape.endPoint.y),
    );
    canvas.drawOval(rect, _paint);
  }

  static void _drawArrow(Canvas canvas, Shape shape) {
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
        oldDelegate.activeShape != activeShape ||
        !identical(oldDelegate.excludedShapeIds, excludedShapeIds);
  }
}
