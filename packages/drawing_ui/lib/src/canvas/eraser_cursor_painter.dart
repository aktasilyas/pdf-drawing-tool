import 'package:flutter/material.dart';

/// Paints the eraser cursor indicator on canvas.
/// Shows a circle for pixel/stroke eraser, path for lasso eraser.
class EraserCursorPainter extends CustomPainter {
  EraserCursorPainter({
    required this.position,
    required this.size,
    required this.mode,
    this.lassoPoints = const [],
    this.isActive = false,
  });
  
  final Offset position;
  final double size;
  final EraserCursorMode mode;
  final List<Offset> lassoPoints;
  final bool isActive;
  
  // Cached paint objects
  static final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  
  static final Paint _fillPaint = Paint()
    ..style = PaintingStyle.fill;
  
  static final Paint _shadowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..color = Colors.black26;
  
  @override
  void paint(Canvas canvas, Size canvasSize) {
    switch (mode) {
      case EraserCursorMode.pixel:
      case EraserCursorMode.stroke:
        _drawCircleCursor(canvas);
        break;
      case EraserCursorMode.lasso:
        _drawLassoCursor(canvas);
        break;
    }
  }
  
  void _drawCircleCursor(Canvas canvas) {
    final radius = size / 2;
    
    // Shadow
    canvas.drawCircle(
      position + const Offset(1, 1),
      radius,
      _shadowPaint,
    );
    
    // Fill (semi-transparent)
    _fillPaint.color = isActive 
        ? Colors.red.withValues(alpha: 0.2)
        : Colors.grey.withValues(alpha: 0.1);
    canvas.drawCircle(position, radius, _fillPaint);
    
    // Stroke
    _strokePaint.color = isActive ? Colors.red : Colors.grey.shade600;
    canvas.drawCircle(position, radius, _strokePaint);
    
    // Eraser icon inside - ALWAYS SHOW, larger and more visible
    _drawEraserIcon(canvas, position, size * 0.5);
  }
  
  void _drawLassoCursor(Canvas canvas) {
    if (lassoPoints.isEmpty) {
      // Just show crosshair when not drawing
      _drawCrosshair(canvas, position);
      return;
    }
    
    // Draw lasso path
    final path = Path();
    path.moveTo(lassoPoints.first.dx, lassoPoints.first.dy);
    
    for (int i = 1; i < lassoPoints.length; i++) {
      path.lineTo(lassoPoints[i].dx, lassoPoints[i].dy);
    }
    
    // Fill
    _fillPaint.color = Colors.red.withValues(alpha: 0.1);
    canvas.drawPath(path, _fillPaint);
    
    // Stroke (dashed effect via dashPath)
    _strokePaint.color = Colors.red.shade400;
    _strokePaint.strokeWidth = 2.0;
    canvas.drawPath(path, _strokePaint);
    
    // Marching ants effect (animated dots along path)
    _drawMarchingAnts(canvas, path);
  }
  
  void _drawCrosshair(Canvas canvas, Offset center) {
    _strokePaint.color = Colors.grey.shade600;
    _strokePaint.strokeWidth = 1.0;
    
    const crossSize = 10.0;
    canvas.drawLine(
      center - const Offset(crossSize, 0),
      center + const Offset(crossSize, 0),
      _strokePaint,
    );
    canvas.drawLine(
      center - const Offset(0, crossSize),
      center + const Offset(0, crossSize),
      _strokePaint,
    );
  }
  
  void _drawEraserIcon(Canvas canvas, Offset center, double iconSize) {
    // White background for better visibility
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final iconRect = Rect.fromCenter(
      center: center,
      width: iconSize * 1.2,
      height: iconSize * 0.8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(iconRect, const Radius.circular(3)),
      bgPaint,
    );
    
    final paint = Paint()
      ..color = isActive ? Colors.red.shade700 : Colors.grey.shade700
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = isActive ? Colors.red.shade900 : Colors.grey.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Eraser shape (rectangle with angled top)
    final rect = Rect.fromCenter(
      center: center,
      width: iconSize,
      height: iconSize * 0.6,
    );
    
    final path = Path();
    path.moveTo(rect.left, rect.bottom);
    path.lineTo(rect.left, rect.top + rect.height * 0.3);
    path.lineTo(rect.left + rect.width * 0.3, rect.top);
    path.lineTo(rect.right, rect.top);
    path.lineTo(rect.right, rect.bottom);
    path.close();
    
    // Fill
    canvas.drawPath(path, paint);
    // Outline
    canvas.drawPath(path, strokePaint);
  }
  
  void _drawMarchingAnts(Canvas canvas, Path path) {
    // Simple dotted line effect
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Draw white dots along the path for contrast
    final metrics = path.computeMetrics();
    if (metrics.isEmpty) return;
    
    final metric = metrics.first;
    final length = metric.length;
    
    for (double d = 0; d < length; d += 8) {
      final tangent = metric.getTangentForOffset(d);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 1.5, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant EraserCursorPainter oldDelegate) {
    return oldDelegate.position != position ||
           oldDelegate.size != size ||
           oldDelegate.mode != mode ||
           oldDelegate.isActive != isActive ||
           oldDelegate.lassoPoints.length != lassoPoints.length;
  }
}

enum EraserCursorMode {
  pixel,
  stroke,
  lasso,
}
