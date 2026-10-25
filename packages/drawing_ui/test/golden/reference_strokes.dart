import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';

/// Shared reference stroke set for the pen preset goldens.
///
/// All content is deterministic (no randomness, uniform timestamps).
const double kReferenceWidth = 480;
const double kReferenceHeight = 360;

const int _ink = 0xFF1A237E;
const int _highlight = 0xFFFFEB3B;
const int _black = 0xFF000000;

Stroke _stroke(String id, List<DrawingPoint> pts, StrokeStyle style) => Stroke(
      id: id,
      points: pts,
      style: style,
      createdAt: DateTime(2024),
    );

/// Slow S-curve with a pressure ramp up, hold, then fall.
List<DrawingPoint> _slowS() {
  const n = 60;
  return [
    for (var i = 0; i < n; i++)
      () {
        final t = i / (n - 1);
        final p = t < 0.4
            ? 0.3 + 0.7 * t / 0.4
            : t < 0.6
                ? 1.0
                : 1.0 - 0.55 * (t - 0.6) / 0.4;
        return DrawingPoint(
          x: 30 + 420 * t,
          y: 60 + 30 * math.sin(t * 2 * math.pi),
          pressure: p,
          timestamp: i * 16,
        );
      }(),
  ];
}

/// Fast flick: few widely spaced samples, 2ms apart.
List<DrawingPoint> _flick() => [
      for (var i = 0; i < 12; i++)
        DrawingPoint(
          x: 40 + i * 18.0 + i * i * 1.2,
          y: 150 - i * 4.0 - i * i * 0.25,
          pressure: 0.6,
          timestamp: i * 2,
        ),
    ];

/// A single tap.
List<DrawingPoint> _dot() => [
      DrawingPoint(x: 380, y: 150, pressure: 0.7, timestamp: 0),
      DrawingPoint(x: 380.4, y: 150.2, pressure: 0.7, timestamp: 8),
    ];

/// Handwriting-like zigzag.
List<DrawingPoint> _zigzag() => [
      for (var i = 0; i < 48; i++)
        DrawingPoint(
          x: 30 + i * 9.0,
          y: 220 + (i % 6 < 3 ? (i % 3) * 12.0 : (3 - i % 3) * 12.0),
          pressure: 0.5 + 0.4 * math.sin(i / 5),
          timestamp: i * 10,
        ),
    ];

/// Horizontal dark ink line at [y], used to prove multiply on the highlighter.
Stroke _inkLine(String id, double y, StrokeStyle style) => _stroke(
      id,
      [
        for (var i = 0; i < 30; i++)
          DrawingPoint(x: 40 + i * 14.0, y: y, pressure: 0.8, timestamp: i * 8),
      ],
      style,
    );

/// Thickness used per preset so the shape is visible at golden scale.
const _thickness = {
  PenType.fountainPen: 6.0,
  PenType.ballpointPen: 4.0,
  PenType.brushPen: 14.0,
  PenType.pencil: 5.0,
};

/// Reference strokes for [type], in z-order.
List<Stroke> referenceStrokes(PenType type) {
  final style = type.toStrokeStyle(
    color: _ink,
    thickness: _thickness[type],
  );
  if (type == PenType.highlighter) {
    final hl = type.toStrokeStyle(color: _highlight);
    final black = StrokeStyle.pen(color: _black, thickness: 4);
    return [
      _inkLine('before', 290, black),
      _stroke('s', _slowS(), hl),
      _stroke('flick', _flick(), hl),
      _stroke('dot', _dot(), hl),
      _stroke('zig', _zigzag(), hl),
      _inkLine('over-before', 290, hl),
      _inkLine('after', 330, black),
      _inkLine('over-after', 330, hl),
    ];
  }
  return [
    _stroke('s', _slowS(), style),
    _stroke('flick', _flick(), style),
    _stroke('dot', _dot(), style),
    _stroke('zig', _zigzag(), style),
  ];
}
