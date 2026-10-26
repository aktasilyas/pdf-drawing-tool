import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:drawing_ui/src/providers/providers.dart';

// content: the hot white core of a laser beam, not chrome.
const Color _kLaserCore = Color(0xFFFFFFFF);

/// Preview of the laser pointer (line styles and dot) at the chosen colour
/// and thickness.
class LaserPreview extends StatelessWidget {
  const LaserPreview({
    super.key,
    required this.color,
    required this.thickness,
    required this.mode,
    required this.lineStyle,
  });

  final Color color;
  final double thickness;
  final LaserMode mode;
  final LaserLineStyle lineStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: _LaserPreviewPainter(color, thickness, mode, lineStyle),
      ),
    );
  }
}

class _LaserPreviewPainter extends CustomPainter {
  _LaserPreviewPainter(this.color, this.thickness, this.mode, this.lineStyle);

  final Color color;
  final double thickness;
  final LaserMode mode;
  final LaserLineStyle lineStyle;

  // content: the rainbow beam colours are user-visible ink.
  static const _rainbowColors = [
    Color(0xFFFF0000),
    Color(0xFFFF8800),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF0088FF),
    Color(0xFF8800FF),
    Color(0xFFFF00FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = thickness.clamp(0.5, 5.0);

    if (mode == LaserMode.dot) {
      _drawDot(canvas, Offset(w / 2, h / 2), t);
      return;
    }

    final path = Path()
      ..moveTo(w * 0.10, h * 0.75)
      ..cubicTo(w * 0.20, h * 0.10, w * 0.35, h * 0.05, w * 0.50, h * 0.30)
      ..cubicTo(w * 0.65, h * 0.55, w * 0.75, h * 0.85, w * 0.90, h * 0.25);

    switch (lineStyle) {
      case LaserLineStyle.solid:
        _drawSolid(canvas, path, t);
      case LaserLineStyle.hollow:
        _drawHollow(canvas, path, t);
      case LaserLineStyle.rainbow:
        _drawRainbow(canvas, path, t);
    }
  }

  void _drawSolid(Canvas canvas, Path path, double t) {
    final p = _strokePaint();
    // Layer 1: Wide outer glow
    canvas.drawPath(
        path,
        p
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = t * 10
          ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 6));
    // Layer 2: Middle glow
    canvas.drawPath(
        path,
        p
          ..color = color.withValues(alpha: 0.85)
          ..strokeWidth = t * 5
          ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 2));
    // Layer 3: Tight bright glow
    canvas.drawPath(
        path,
        p
          ..color = color.withValues(alpha: 0.95)
          ..strokeWidth = t * 2.5
          ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 0.5));
    // Layer 4: White core
    final coreColor = Color.lerp(color, _kLaserCore, 0.7)!;
    canvas.drawPath(
        path,
        p
          ..color = coreColor
          ..strokeWidth = t * 1.2
          ..maskFilter = null);
  }

  void _drawHollow(Canvas canvas, Path path, double t) {
    final p = _strokePaint();
    // Layer 1: Subtle outer glow (narrow)
    canvas.drawPath(
        path,
        p
          ..color = color.withValues(alpha: 0.3)
          ..strokeWidth = t * 6
          ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 3));
    // Layer 2: Tight inner glow
    canvas.drawPath(
        path,
        p
          ..color = color.withValues(alpha: 0.6)
          ..strokeWidth = t * 3
          ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 0.8));
    // Layer 3: Sharp solid color core (dominant)
    canvas.drawPath(
        path,
        p
          ..color = color
          ..strokeWidth = t * 1.8
          ..maskFilter = null);
  }

  void _drawRainbow(Canvas canvas, Path path, double t) {
    final bounds = path.getBounds();
    final gradient = ui.Gradient.linear(
      bounds.topLeft,
      bounds.bottomRight,
      _rainbowColors,
      List.generate(
        _rainbowColors.length,
        (i) => i / (_rainbowColors.length - 1),
      ),
    );
    final p = _strokePaint();
    // Outer glow
    canvas.drawPath(
        path,
        p
          ..shader = gradient
          ..strokeWidth = t * 10
          ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 6));
    // Middle glow
    canvas.drawPath(
        path,
        p
          ..strokeWidth = t * 5
          ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 2));
    p.shader = null;
    // White core
    canvas.drawPath(
        path,
        p
          ..color = _kLaserCore.withValues(alpha: 0.9)
          ..strokeWidth = t * 1.2
          ..maskFilter = null);
  }

  void _drawDot(Canvas canvas, Offset center, double t) {
    final r = t * 1.5;
    canvas.drawCircle(
        center,
        r * 5,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, r * 5));
    canvas.drawCircle(
        center,
        r * 2.5,
        Paint()
          ..color = color.withValues(alpha: 0.85)
          ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, r * 2));
    final coreColor = Color.lerp(color, _kLaserCore, 0.7)!;
    canvas.drawCircle(center, r, Paint()..color = coreColor);
  }

  Paint _strokePaint() => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  bool shouldRepaint(_LaserPreviewPainter o) =>
      color != o.color ||
      thickness != o.thickness ||
      mode != o.mode ||
      lineStyle != o.lineStyle;
}
