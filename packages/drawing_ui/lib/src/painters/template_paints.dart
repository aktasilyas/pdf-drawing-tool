import 'package:flutter/material.dart';

/// Immutable [Paint] set shared by the basic template painters.
///
/// Built once per painter instance so `paint()` allocates no [Paint] objects.
/// Painters must never mutate these paints.
class TemplatePaints {
  TemplatePaints({
    required Color lineColor,
    required double lineWidth,
    required Color backgroundColor,
  })  : background = Paint()..color = backgroundColor,
        line = _stroke(lineColor, lineWidth),
        bold = _stroke(lineColor, lineWidth * 2),
        margin = _stroke(lineColor, lineWidth * 3),
        midLine = _stroke(lineColor.withValues(alpha: 0.4), lineWidth),
        guide = _stroke(lineColor.withValues(alpha: 0.3), lineWidth),
        zone = _stroke(lineColor.withValues(alpha: 0.25), lineWidth * 0.5),
        angle = _stroke(lineColor.withValues(alpha: 0.2), lineWidth * 0.5),
        dot = Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill,
        outline = _stroke(lineColor, lineWidth)..style = PaintingStyle.stroke;

  final Paint background;
  final Paint line;
  final Paint bold;
  final Paint margin;
  final Paint midLine;
  final Paint guide;
  final Paint zone;
  final Paint angle;
  final Paint dot;
  final Paint outline;

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..strokeWidth = width
    ..isAntiAlias = true;
}
