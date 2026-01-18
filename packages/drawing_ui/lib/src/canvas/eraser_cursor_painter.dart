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
    // Draw a modern eraser icon (rounded rectangle with corner fold)
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = isActive ? Colors.red.shade700 : Colors.grey.shade700;
    
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white;

    // Main eraser body (rounded rectangle)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center + const Offset(0, 2),
        width: iconSize * 0.8,
        height: iconSize * 0.5,
      ),
      const Radius.circular(2),
    );
    
    // Draw shadow first
    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black26;
    canvas.drawRRect(
      bodyRect.shift(const Offset(1, 1)),
      shadowPaint,
    );
    
    // Draw main body
    canvas.drawRRect(bodyRect, paint);
    canvas.drawRRect(bodyRect, strokePaint);
    
    // Draw highlight line (makes it look 3D)
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.5);
    
    canvas.drawLine(
      Offset(bodyRect.left + 2, bodyRect.top + 2),
      Offset(bodyRect.right - 2, bodyRect.top + 2),
      highlightPaint,
    );
    
    // Draw corner fold (top-left)
    final foldPath = Path();
    final foldSize = iconSize * 0.15;
    foldPath.moveTo(bodyRect.left, bodyRect.top + foldSize);
    foldPath.lineTo(bodyRect.left + foldSize, bodyRect.top);
    foldPath.lineTo(bodyRect.left, bodyRect.top);
    foldPath.close();
    
    final foldPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isActive ? Colors.red.shade900 : Colors.grey.shade900;
    canvas.drawPath(foldPath, foldPaint);
    canvas.drawPath(foldPath, strokePaint);
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
    
    // Skip if path is too short
    if (length < 1) return;
    
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
