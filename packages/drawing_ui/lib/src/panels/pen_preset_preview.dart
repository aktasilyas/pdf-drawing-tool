import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';

/// Inset of the curve inside the preview box (mirrors AppSpacing sm / md).
const double _kInsetH = 8;
const double _kInsetV = 12;

/// Thickness range a preview stroke is mapped into, per pen type.
(double, double) _previewRange(PenType type) {
  switch (type) {
    case PenType.brushPen:
      return (2, 8);
    case PenType.highlighter:
      return (6, 14);
    default:
      return (1.5, 6);
  }
}

// Soft S-shape: cubic (0,0.8) (0.3,-0.6) (0.7,1.6) (1,0.2) in a unit box.
const int _kCurveSamples = 17;

/// Live preview of the stroke a pen preset produces with [style].
///
/// Drawn by the real stroke renderer, so taper, texture and blend mode match
/// the canvas. Owns no state; the box ratio is taken from the layout.
class PenPresetPreview extends StatelessWidget {
  const PenPresetPreview({
    super.key,
    required this.penType,
    required this.style,
  });

  /// Preset the preview belongs to (selects curve and thickness range).
  final PenType penType;

  /// Current style of the tool (colour, thickness, dynamics).
  final StrokeStyle style;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) => CustomPaint(
          size: constraints.biggest,
          painter: PenPresetPreviewPainter(
            penType: penType,
            style: style,
            size: constraints.biggest,
          ),
        ),
      ),
    );
  }
}

/// Painter for [PenPresetPreview]; geometry is built once in the constructor.
class PenPresetPreviewPainter extends CustomPainter {
  PenPresetPreviewPainter({
    required this.penType,
    required this.style,
    required this.size,
  }) : _stroke = _buildStroke(penType, style, size);

  final PenType penType;
  final StrokeStyle style;
  final Size size;
  final Stroke _stroke;
  static final FlutterStrokeRenderer _renderer = FlutterStrokeRenderer();

  /// The stroke that is drawn (exposed for tests).
  Stroke get stroke => _stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (_stroke.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _renderer.renderStroke(canvas, _stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PenPresetPreviewPainter old) =>
      old.style != style || old.size != size || old.penType != penType;

  static Stroke _buildStroke(PenType type, StrokeStyle style, Size size) {
    final w = math.max(0.0, size.width - 2 * _kInsetH);
    final h = math.max(0.0, size.height - 2 * _kInsetV);
    final points = <DrawingPoint>[];
    if (w > 0 && h > 0) {
      points.addAll(_samples(type, _kInsetH, _kInsetV, w, h));
    }

    final cfg = type.config;
    final (lo, hi) = _previewRange(type);
    final span = cfg.maxThickness - cfg.minThickness;
    final n = span <= 0
        ? 0.0
        : ((style.thickness - cfg.minThickness) / span).clamp(0.0, 1.0);
    final thickness = ui.lerpDouble(lo, hi, n)!;
    final k = style.thickness <= 0 ? 1.0 : thickness / style.thickness;

    var length = 0.0;
    for (var i = 1; i < points.length; i++) {
      length += math.sqrt(math.pow(points[i].x - points[i - 1].x, 2) +
          math.pow(points[i].y - points[i - 1].y, 2));
    }
    var ts = style.dynamics.taperStart * k;
    var te = style.dynamics.taperEnd * k;
    final cap = 0.6 * length;
    if (ts + te > cap && ts + te > 0) {
      final f = cap / (ts + te);
      ts *= f;
      te *= f;
    }
    return Stroke(
      id: 'pen-preview',
      points: points,
      style: style.copyWith(
        thickness: thickness,
        dynamics: StrokeDynamics(
          taperStart: ts,
          taperEnd: te,
          streamline: style.dynamics.streamline,
          velocityThinning: style.dynamics.velocityThinning,
        ),
      ),
      createdAt: DateTime(2024),
    );
  }

  static List<DrawingPoint> _samples(
    PenType type,
    double ox,
    double oy,
    double w,
    double h,
  ) {
    if (type == PenType.highlighter) {
      return [
        for (var i = 0; i < 9; i++)
          DrawingPoint(
            x: ox + w * i / 8,
            y: oy + h / 2,
            pressure: 1,
            timestamp: i * 8,
          ),
      ];
    }
    return [
      for (var i = 0; i < _kCurveSamples; i++)
        () {
          final t = i / (_kCurveSamples - 1);
          final u = 1 - t;
          final x = 3 * u * u * t * 0.30 + 3 * u * t * t * 0.70 + t * t * t;
          final y = u * u * u * 0.80 +
              3 * u * u * t * -0.60 +
              3 * u * t * t * 1.60 +
              t * t * t * 0.20;
          final p = t < 0.4
              ? 0.3 + 0.7 * t / 0.4
              : t < 0.6
                  ? 1.0
                  : 1.0 - 0.55 * (t - 0.6) / 0.4;
          return DrawingPoint(
            x: ox + w * x,
            y: oy + h * y,
            pressure: p,
            timestamp: i * 8,
          );
        }(),
    ];
  }
}
