import 'package:flutter/material.dart';

/// Immutable [Paint] set shared by the planner and creative template painters.
///
/// Built once per painter instance so `paint()` allocates no [Paint] objects.
/// Names say what the paint is: `hairN` is the N/10 line alpha at half width,
/// `softN` the N/10 alpha at full width. Painters must never mutate these.
class TemplateAccentPaints {
  TemplateAccentPaints({required Color lineColor, required double lineWidth})
      : ink = _stroke(lineColor, 1, lineWidth),
        ink15 = _stroke(lineColor, 1, lineWidth * 1.5),
        divider = _stroke(lineColor, 1, lineWidth * 2),
        hair3 = _stroke(lineColor, 0.3, lineWidth * 0.5),
        hair4 = _stroke(lineColor, 0.4, lineWidth * 0.5),
        hair5 = _stroke(lineColor, 0.5, lineWidth * 0.5),
        soft3 = _stroke(lineColor, 0.3, lineWidth),
        soft4 = _stroke(lineColor, 0.4, lineWidth),
        soft5 = _stroke(lineColor, 0.5, lineWidth),
        gridFaint = _stroke(lineColor, 0.15, lineWidth * 0.3),
        statusFaint = _stroke(lineColor, 0.2, lineWidth * 0.3),
        bulletDot = _fill(lineColor, 0.6),
        promptDot = _fill(lineColor, 0.5),
        dotGrid = _fill(lineColor, 0.15);

  final Paint ink;
  final Paint ink15;
  final Paint divider;
  final Paint hair3;
  final Paint hair4;
  final Paint hair5;
  final Paint soft3;
  final Paint soft4;
  final Paint soft5;
  final Paint gridFaint;
  final Paint statusFaint;
  final Paint bulletDot;
  final Paint promptDot;
  final Paint dotGrid;

  static Paint _stroke(Color color, double alpha, double width) => Paint()
    ..color = alpha == 1 ? color : color.withValues(alpha: alpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..isAntiAlias = true;

  static Paint _fill(Color color, double alpha) => Paint()
    ..color = color.withValues(alpha: alpha)
    ..style = PaintingStyle.fill;
}
