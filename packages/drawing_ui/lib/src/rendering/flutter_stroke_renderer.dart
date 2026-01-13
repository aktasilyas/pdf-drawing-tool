import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

/// Renders [Stroke] objects from drawing_core to Flutter Canvas.
///
/// This class bridges the gap between the UI-agnostic drawing_core
/// and Flutter's rendering system.
class FlutterStrokeRenderer {
  /// Renders a single stroke to the canvas.
  ///
  /// Does nothing if the stroke is empty.
  void renderStroke(Canvas canvas, Stroke stroke) {
    if (stroke.isEmpty) return;

    final paint = _createPaint(stroke.style);
    final path = _createPath(stroke.points, stroke.style);

    canvas.drawPath(path, paint);
  }

  /// Renders multiple strokes to the canvas.
  ///
  /// Strokes are rendered in order, so later strokes appear on top.
  void renderStrokes(Canvas canvas, List<Stroke> strokes) {
    for (final stroke in strokes) {
      renderStroke(canvas, stroke);
    }
  }

  /// Renders an active (incomplete) stroke being drawn.
  ///
  /// This is used for live preview while the user is drawing.
  void renderActiveStroke(
    Canvas canvas,
    List<DrawingPoint> points,
    StrokeStyle style,
  ) {
    if (points.isEmpty) return;

    final paint = _createPaint(style);
    final path = _createPath(points, style);

    canvas.drawPath(path, paint);
  }

  /// Creates a [Paint] object from a [StrokeStyle].
  Paint _createPaint(StrokeStyle style) {
    final baseColor = Color(style.color);
    final paint = Paint()
      ..color = baseColor.withValues(alpha: style.opacity)
      ..strokeWidth = style.thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = _getStrokeCap(style.nibShape)
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Apply blend mode if not normal
    if (style.blendMode != DrawingBlendMode.normal) {
      paint.blendMode = _getBlendMode(style.blendMode);
    }

    return paint;
  }

  /// Creates a [Path] from a list of [DrawingPoint]s.
  ///
  /// Uses quadratic bezier curves for smooth rendering when there
  /// are 3 or more points.
  Path _createPath(List<DrawingPoint> points, StrokeStyle style) {
    final path = Path();

    if (points.isEmpty) return path;

    if (points.length == 1) {
      // Single point - draw a small circle
      final p = points.first;
      path.addOval(Rect.fromCircle(
        center: Offset(p.x, p.y),
        radius: style.thickness / 2,
      ));
      return path;
    }

    // Move to first point
    path.moveTo(points.first.x, points.first.y);

    if (points.length == 2) {
      // Two points - straight line
      path.lineTo(points.last.x, points.last.y);
      return path;
    }

    // 3+ points - use quadratic bezier for smooth curves
    for (int i = 1; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final midX = (p0.x + p1.x) / 2;
      final midY = (p0.y + p1.y) / 2;

      path.quadraticBezierTo(p0.x, p0.y, midX, midY);
    }

    // Connect to last point
    final last = points.last;
    path.lineTo(last.x, last.y);

    return path;
  }

  /// Maps [NibShape] to Flutter's [StrokeCap].
  StrokeCap _getStrokeCap(NibShape nibShape) {
    switch (nibShape) {
      case NibShape.circle:
        return StrokeCap.round;
      case NibShape.rectangle:
        return StrokeCap.square;
      case NibShape.ellipse:
        return StrokeCap.round; // Ellipse also uses round for now
    }
  }

  /// Maps [DrawingBlendMode] to Flutter's [BlendMode].
  BlendMode _getBlendMode(DrawingBlendMode mode) {
    switch (mode) {
      case DrawingBlendMode.normal:
        return BlendMode.srcOver;
      case DrawingBlendMode.multiply:
        return BlendMode.multiply;
      case DrawingBlendMode.screen:
        return BlendMode.screen;
      case DrawingBlendMode.overlay:
        return BlendMode.overlay;
      case DrawingBlendMode.darken:
        return BlendMode.darken;
      case DrawingBlendMode.lighten:
        return BlendMode.lighten;
    }
  }
}
