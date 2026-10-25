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

  /// Whether [style] is drawn as a filled [StrokeOutline] polygon.
  ///
  /// Single routing predicate shared by committed, live and PDF rendering.
  /// Pencil texture always wins; otherwise pressure or any outline tuning
  /// (tapers, custom streamline/velocity) selects the outline.
  static bool usesOutline(StrokeStyle style) =>
      style.texture != StrokeTexture.pencil &&
      (style.pressureSensitive || !style.dynamics.isNone);

  /// Outline options shared by the committed and the live render so the two
  /// cannot drift apart.
  static StrokeOutlineOptions optionsFor(StrokeStyle style) {
    final d = style.dynamics;
    return StrokeOutlineOptions(
      size: style.thickness,
      thinning: style.pressureSensitive ? style.pressureSensitivity : 0,
      velocityThinning: d.velocityThinning,
      streamline: d.streamline,
      taperStart: d.taperStart,
      taperEnd: d.taperEnd,
    );
  }

  /// Creates the fill paint used for [style].
  static Paint fillPaintFor(StrokeStyle style) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    _applyStyle(paint, style);
    return paint;
  }

  /// Renders a variable-width stroke on [canvas].
  void render(Canvas canvas, List<DrawingPoint> points, StrokeStyle style) {
    if (points.isEmpty) return;
    _configurePaint(style);

    final outline = StrokeOutline.build(
      points,
      optionsFor(style),
    );
    if (outline.length < 3) return;

    final path = Path()..moveTo(outline.first.x, outline.first.y);
    for (var i = 1; i < outline.length; i++) {
      path.lineTo(outline[i].x, outline[i].y);
    }
    path.close();
    canvas.drawPath(path, _fillPaint);
  }

  void _configurePaint(StrokeStyle style) => _applyStyle(_fillPaint, style);

  static void _applyStyle(Paint paint, StrokeStyle style) {
    paint
      ..color = Color(style.color).withValues(alpha: style.opacity)
      ..blendMode = _blendMode(style.blendMode)
      ..maskFilter = (style.glowRadius > 0 && style.glowIntensity > 0)
          ? MaskFilter.blur(
              BlurStyle.normal, style.glowRadius * style.glowIntensity)
          : null;
  }

  static BlendMode _blendMode(DrawingBlendMode mode) {
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
