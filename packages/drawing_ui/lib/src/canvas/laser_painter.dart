import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:drawing_ui/src/canvas/laser_controller.dart';
import 'package:drawing_ui/src/canvas/laser_stroke.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';

/// Renders laser strokes with a 3-layer neon glow effect.
///
/// Layers (outer to inner):
/// 1. Outer glow - wide, heavily blurred, low opacity
/// 2. Middle glow - medium blur, medium opacity
/// 3. Inner core - sharp, bright, near-white
///
/// Performance: Paint objects are created per-stroke (not per-frame)
/// only when color/thickness change. No allocations in tight loops.
class LaserPainter extends CustomPainter {
  LaserPainter({required this.controller})
      : super(repaint: controller);

  final LaserController controller;

  // Reusable paint objects (reset per stroke render)
  static final Paint _outerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  static final Paint _middlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  static final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();

    // Render fading strokes
    for (final stroke in controller.fadingStrokes) {
      final progress = stroke.fadeProgress(now);
      if (progress >= 1.0) continue;
      final opacity = 1.0 - progress;
      _renderStroke(canvas, stroke, opacity);
    }

    // Render active stroke (full opacity)
    final active = controller.activeStroke;
    if (active != null) {
      _renderStroke(canvas, active, 1.0);
    }
  }

  void _renderStroke(Canvas canvas, LaserStroke stroke, double opacity) {
    if (stroke.points.isEmpty) return;

    if (stroke.mode == LaserMode.dot || stroke.points.length == 1) {
      _renderDot(canvas, stroke, opacity);
    } else {
      switch (stroke.lineStyle) {
        case LaserLineStyle.solid:
          _renderSolidLine(canvas, stroke, opacity);
        case LaserLineStyle.hollow:
          _renderHollowLine(canvas, stroke, opacity);
        case LaserLineStyle.rainbow:
          _renderRainbowLine(canvas, stroke, opacity);
      }
    }
  }

  // ─── SOLID LINE (4-layer vivid neon glow) ───

  void _renderSolidLine(Canvas canvas, LaserStroke stroke, double opacity) {
    final path = _buildPath(stroke.points);
    final t = stroke.thickness;
    final color = stroke.color;

    // Layer 1: Wide outer glow
    _outerPaint
      ..color = color.withValues(alpha: 0.5 * opacity)
      ..strokeWidth = t * 10
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 6);
    canvas.drawPath(path, _outerPaint);

    // Layer 2: Middle glow
    _middlePaint
      ..color = color.withValues(alpha: 0.85 * opacity)
      ..strokeWidth = t * 5
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 2);
    canvas.drawPath(path, _middlePaint);

    // Layer 3: Tight bright glow
    _corePaint
      ..color = color.withValues(alpha: 0.95 * opacity)
      ..strokeWidth = t * 2.5
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 0.5);
    canvas.drawPath(path, _corePaint);

    // Layer 4: Bright white core
    final coreColor = Color.lerp(color, Colors.white, 0.7)!;
    _corePaint
      ..color = coreColor.withValues(alpha: opacity)
      ..strokeWidth = t * 1.2
      ..maskFilter = null;
    canvas.drawPath(path, _corePaint);
  }

  // ─── HOLLOW LINE (tight glow + sharp colored core) ───

  void _renderHollowLine(Canvas canvas, LaserStroke stroke, double opacity) {
    final path = _buildPath(stroke.points);
    final t = stroke.thickness;
    final color = stroke.color;

    // Layer 1: Subtle outer glow (narrow)
    _outerPaint
      ..color = color.withValues(alpha: 0.3 * opacity)
      ..strokeWidth = t * 6
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 3);
    canvas.drawPath(path, _outerPaint);

    // Layer 2: Tight inner glow
    _middlePaint
      ..color = color.withValues(alpha: 0.6 * opacity)
      ..strokeWidth = t * 3
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 0.8);
    canvas.drawPath(path, _middlePaint);

    // Layer 3: Sharp solid color core (dominant)
    _corePaint
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = t * 1.8
      ..maskFilter = null;
    canvas.drawPath(path, _corePaint);
  }

  // ─── RAINBOW LINE (spectrum gradient along path) ───

  static const _rainbowColors = [
    Color(0xFFFF0000), // Red
    Color(0xFFFF8800), // Orange
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00FF00), // Green
    Color(0xFF0088FF), // Blue
    Color(0xFF8800FF), // Indigo
    Color(0xFFFF00FF), // Violet
  ];

  void _renderRainbowLine(Canvas canvas, LaserStroke stroke, double opacity) {
    if (stroke.points.length < 2) return;
    final path = _buildPath(stroke.points);
    final t = stroke.thickness;

    // Compute path bounds for gradient direction
    final bounds = path.getBounds();

    final gradient = ui.Gradient.linear(
      bounds.topLeft,
      bounds.bottomRight,
      _rainbowColors.map((c) => c.withValues(alpha: opacity)).toList(),
      List.generate(
        _rainbowColors.length,
        (i) => i / (_rainbowColors.length - 1),
      ),
    );

    // Layer 1: Rainbow outer glow
    _outerPaint
      ..shader = gradient
      ..strokeWidth = t * 8
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 4);
    canvas.drawPath(path, _outerPaint);
    _outerPaint.shader = null;

    // Layer 2: Rainbow middle glow
    _middlePaint
      ..shader = gradient
      ..strokeWidth = t * 3.5
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, t * 1.5);
    canvas.drawPath(path, _middlePaint);
    _middlePaint.shader = null;

    // Layer 3: Bright white core
    _corePaint
      ..color = Colors.white.withValues(alpha: 0.9 * opacity)
      ..strokeWidth = t * 1.5
      ..maskFilter = null;
    canvas.drawPath(path, _corePaint);
  }

  void _renderDot(Canvas canvas, LaserStroke stroke, double opacity) {
    final center = stroke.points.last;
    final r = stroke.thickness * 1.5;
    final color = stroke.color;

    // Layer 1: Wide outer glow
    _outerPaint
      ..color = color.withValues(alpha: 0.5 * opacity)
      ..strokeWidth = 0
      ..style = PaintingStyle.fill
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, r * 5);
    canvas.drawCircle(center, r * 5, _outerPaint);
    _outerPaint.style = PaintingStyle.stroke;

    // Layer 2: Middle glow
    _middlePaint
      ..color = color.withValues(alpha: 0.85 * opacity)
      ..strokeWidth = 0
      ..style = PaintingStyle.fill
      ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, r * 2);
    canvas.drawCircle(center, r * 2.5, _middlePaint);
    _middlePaint.style = PaintingStyle.stroke;

    // Layer 3: Bright core
    final coreColor = Color.lerp(color, Colors.white, 0.7)!;
    _corePaint
      ..color = coreColor.withValues(alpha: opacity)
      ..strokeWidth = 0
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    canvas.drawCircle(center, r, _corePaint);
    _corePaint.style = PaintingStyle.stroke;
  }

  /// Builds a smooth path using quadratic bezier curves.
  Path _buildPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);

    if (points.length == 1) return path;

    if (points.length == 2) {
      path.lineTo(points.last.dx, points.last.dy);
      return path;
    }

    // Quadratic bezier smoothing (same approach as FlutterStrokeRenderer)
    for (int i = 1; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      final midY = (p0.dy + p1.dy) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
    }

    final last = points.last;
    path.lineTo(last.dx, last.dy);

    return path;
  }

  @override
  bool shouldRepaint(covariant LaserPainter oldDelegate) => false;
}
