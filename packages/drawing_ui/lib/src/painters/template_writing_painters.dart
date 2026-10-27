import 'dart:math';
import 'package:flutter/material.dart';

import 'template_paints.dart';

/// Mixin with the handwriting and calligraphy guide painters.
mixin TemplateWritingPainters {
  Map<String, dynamic>? get extraData;
  double get lineWidth;
  double get spacingPx;
  TemplatePaints get paints;

  void drawHandwriting(Canvas canvas, Size size) {
    final topMargin = spacingPx * 2;

    for (double y = topMargin; y < size.height; y += spacingPx) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paints.line);

      // Lighter mid line
      final midY = y - spacingPx * 0.4;
      if (midY > topMargin) {
        canvas.drawLine(
          Offset(0, midY),
          Offset(size.width, midY),
          paints.midLine,
        );
      }
    }
  }

  void drawCalligraphy(Canvas canvas, Size size) {
    final style = extraData?['style'] as String?;

    // Slant angle from extraData, default 55°
    final angleDeg = (extraData?['angle'] as num?)?.toDouble() ?? 55;
    final tanAngle = tan(angleDeg * pi / 180);

    if (style == 'copperplate') {
      _drawCopperplate(canvas, size, tanAngle);
    } else {
      _drawStandard(canvas, size, tanAngle);
    }
  }

  void _drawStandard(Canvas canvas, Size size, double tanAngle) {
    for (double y = spacingPx * 2; y < size.height; y += spacingPx) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paints.line);
    }

    for (double x = 0; x < size.width + size.height; x += spacingPx * 2) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height * tanAngle, size.height),
        paints.guide,
      );
    }
  }

  void _drawCopperplate(Canvas canvas, Size size, double tanAngle) {
    // Ratio ascender:x-height:descender (default 3:2:3)
    final ratioStr = (extraData?['ratio'] as String?) ?? '3:2:3';
    final parts = ratioStr.split(':');
    final aR = double.tryParse(parts[0]) ?? 3;
    final xR = double.tryParse(parts[1]) ?? 2;
    final dR = double.tryParse(parts[2]) ?? 3;
    final totalR = aR + xR + dR;

    final zoneH = spacingPx;
    final ascenderH = zoneH * (aR / totalR);
    final xHeightH = zoneH * (xR / totalR);
    final descenderH = zoneH * (dR / totalR);
    final topMargin = spacingPx * 2;

    for (double y = topMargin; y + zoneH <= size.height; y += zoneH) {
      final xLine = y + ascenderH;
      final baseLine = y + ascenderH + xHeightH;
      final descLine = y + ascenderH + xHeightH + descenderH;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), paints.line);
      canvas.drawLine(Offset(0, xLine), Offset(size.width, xLine), paints.zone);
      canvas.drawLine(
          Offset(0, baseLine), Offset(size.width, baseLine), paints.line);
      canvas.drawLine(
          Offset(0, descLine), Offset(size.width, descLine), paints.zone);
    }

    for (double x = 0; x < size.width + size.height; x += spacingPx * 1.5) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height * tanAngle, size.height),
        paints.angle,
      );
    }
  }
}
