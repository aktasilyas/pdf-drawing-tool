import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'pencil_texture_renderer.dart';
import 'variable_width_renderer.dart';

/// Renders [Stroke] objects from drawing_core to Flutter Canvas.
///
/// This class bridges the gap between the UI-agnostic drawing_core
/// and Flutter's rendering system.
class FlutterStrokeRenderer {
  /// Variable-width renderer for pressure-sensitive strokes.
  final VariableWidthStrokeRenderer _variableWidthRenderer =
      VariableWidthStrokeRenderer();

  /// Pencil texture renderer for pencil/chalk-like effects.
  final PencilTextureRenderer _pencilRenderer = PencilTextureRenderer();

  /// Renders a single stroke to the canvas.
  ///
  /// Does nothing if the stroke is empty.
  /// Delegates to [VariableWidthStrokeRenderer] when pressure-sensitive.
  void renderStroke(Canvas canvas, Stroke stroke) {
    if (stroke.isEmpty) return;

    final style = stroke.style;

    if (style.pressureSensitive) {
      _variableWidthRenderer.render(canvas, stroke.points, style);
      return;
    }

    if (style.texture == StrokeTexture.pencil) {
      _pencilRenderer.render(canvas, stroke.points, style);
      return;
    }

    var paint = _createPaint(style);
    var path = _createPath(stroke.points, style);

    // Apply glow effect
    paint = _buildPaintWithGlow(style, paint);

    // Apply dash pattern
    if (style.pattern != StrokePattern.solid && style.dashPattern != null) {
      path = _createDashedPath(path, style.dashPattern!);
    }

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

  /// Renders a stroke while skipping [excludedSegments].
  ///
  /// A segment at index `i` connects `points[i]` to `points[i+1]`.
  /// Excluded segments are visually removed, splitting the stroke into
  /// contiguous sub-paths that are each rendered separately.
  void renderStrokeExcluding(
    Canvas canvas,
    Stroke stroke,
    Set<int> excludedSegments,
  ) {
    if (stroke.isEmpty) return;
    if (excludedSegments.isEmpty) {
      renderStroke(canvas, stroke);
      return;
    }

    final points = stroke.points;
    final style = stroke.style;
    final totalSegments = points.length - 1;

    int i = 0;
    while (i < totalSegments) {
      if (excludedSegments.contains(i)) {
        i++;
        continue;
      }

      final rangeStart = i;
      while (i < totalSegments && !excludedSegments.contains(i)) {
        i++;
      }

      final subPoints = points.sublist(rangeStart, i + 1);

      if (style.pressureSensitive) {
        _variableWidthRenderer.render(canvas, subPoints, style);
      } else if (style.texture == StrokeTexture.pencil) {
        _pencilRenderer.render(canvas, subPoints, style);
      } else {
        var paint = _createPaint(style);
        paint = _buildPaintWithGlow(style, paint);
        var path = _createPath(subPoints, style);
        if (style.pattern != StrokePattern.solid &&
            style.dashPattern != null) {
          path = _createDashedPath(path, style.dashPattern!);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  /// Renders an active (incomplete) stroke being drawn.
  ///
  /// This is used for live preview while the user is drawing.
  /// Delegates to [VariableWidthStrokeRenderer] when pressure-sensitive.
  void renderActiveStroke(
    Canvas canvas,
    List<DrawingPoint> points,
    StrokeStyle style,
  ) {
    if (points.isEmpty) return;

    if (style.pressureSensitive) {
      _variableWidthRenderer.render(canvas, points, style);
      return;
    }

    if (style.texture == StrokeTexture.pencil) {
      _pencilRenderer.render(canvas, points, style);
      return;
    }

    var paint = _createPaint(style);
    var path = _createPath(points, style);

    // Apply glow effect
    paint = _buildPaintWithGlow(style, paint);

    // Apply dash pattern
    if (style.pattern != StrokePattern.solid && style.dashPattern != null) {
      path = _createDashedPath(path, style.dashPattern!);
    }

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

  /// Creates a dashed path from a continuous path.
  ///
  /// Uses the provided [dashPattern] to create alternating
  /// drawn and empty segments.
  Path _createDashedPath(Path source, List<double> dashPattern) {
    if (dashPattern.isEmpty) return source;

    final result = Path();

    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      int patternIndex = 0;

      while (distance < metric.length) {
        final len = dashPattern[patternIndex % dashPattern.length];
        final end = (distance + len).clamp(0.0, metric.length);

        if (draw) {
          result.addPath(metric.extractPath(distance, end), Offset.zero);
        }

        distance = end;
        draw = !draw;
        patternIndex++;
      }
    }

    return result;
  }

  /// Builds paint with glow support.
  ///
  /// Applies a blur mask filter if glow radius and intensity are set.
  Paint _buildPaintWithGlow(StrokeStyle style, Paint basePaint) {
    if (style.glowRadius > 0 && style.glowIntensity > 0) {
      return basePaint
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          style.glowRadius * style.glowIntensity,
        );
    }
    return basePaint;
  }
}
