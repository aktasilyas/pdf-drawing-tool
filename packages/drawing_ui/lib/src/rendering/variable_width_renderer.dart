import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';

/// Renders strokes with pressure-sensitive variable width.
///
/// Fills the closed outline polygon produced by [StrokeOutline] (pressure
/// and velocity aware) instead of stroking a fixed-width path.
class VariableWidthStrokeRenderer {
  final Paint _fillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  /// Renders a variable-width stroke on [canvas].
  void render(Canvas canvas, List<DrawingPoint> points, StrokeStyle style) {
    if (points.isEmpty) return;
    _configurePaint(style);


    final outline = StrokeOutline.build(
      points,
      StrokeOutlineOptions(
        size: style.thickness,
        thinning: style.pressureSensitivity,
      ),
    );
    if (outline.length < 3) return;

    final path = Path()..moveTo(outline.first.x, outline.first.y);
    for (var i = 1; i < outline.length; i++) {
      path.lineTo(outline[i].x, outline[i].y);
    }
    path.close();
    canvas.drawPath(path, _fillPaint);
  }

  void _configurePaint(StrokeStyle style) {
    _fillPaint
      ..color = Color(style.color).withValues(alpha: style.opacity)
      ..blendMode = _blendMode(style.blendMode)
      ..maskFilter = (style.glowRadius > 0 && style.glowIntensity > 0)
          ? MaskFilter.blur(
              BlurStyle.normal, style.glowRadius * style.glowIntensity)
          : null;
  }

  BlendMode _blendMode(DrawingBlendMode mode) {
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
