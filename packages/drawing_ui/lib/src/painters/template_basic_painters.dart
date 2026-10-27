import 'dart:math';
import 'package:flutter/material.dart';

import 'template_paints.dart';

/// Mixin with the geometric template painters: lines, grid, dots,
/// isometric, hexagonal, Cornell and music staves.
mixin TemplateBasicPainters {
  Map<String, dynamic>? get extraData;
  double get lineWidth;
  double get spacingPx;
  TemplatePaints get paints;

  void drawLines(Canvas canvas, Size size) {
    final topMargin = spacingPx * 2;
    for (double y = topMargin; y < size.height; y += spacingPx) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paints.line);
    }
  }

  void drawGrid(Canvas canvas, Size size) {
    for (double x = spacingPx; x < size.width; x += spacingPx) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paints.line);
    }
    for (double y = spacingPx; y < size.height; y += spacingPx) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paints.line);
    }

    // Margin support (engineer_pad etc.)
    final showMarginLeft = extraData?['showMarginLeft'] as bool? ?? false;
    if (showMarginLeft) {
      final marginMm = (extraData?['marginMm'] as num?)?.toDouble() ?? 25;
      final marginPx = marginMm * 72 / 25.4;
      canvas.drawLine(
        Offset(marginPx, 0),
        Offset(marginPx, size.height),
        paints.margin,
      );
    }
  }

  void drawDots(Canvas canvas, Size size) {
    final radius = lineWidth * 1.5;
    for (double x = spacingPx; x < size.width; x += spacingPx) {
      for (double y = spacingPx; y < size.height; y += spacingPx) {
        canvas.drawCircle(Offset(x, y), radius, paints.dot);
      }
    }
  }

  void drawIsometric(Canvas canvas, Size size) {
    final paint = paints.line;
    final spacing = spacingPx;

    // 30° lines (tan(30°) ≈ 0.577)
    const angle = 0.577;

    for (double x = -size.height; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * angle, size.height),
        paint,
      );
    }

    for (double x = 0; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height * angle, size.height),
        paint,
      );
    }

    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void drawHexagonal(Canvas canvas, Size size) {
    final radius = spacingPx / 2;
    final hexHeight = radius * 1.732; // sqrt(3)
    final hexWidth = radius * 2;

    for (double y = radius; y < size.height + radius; y += hexHeight * 0.75) {
      final rowOffset = (y ~/ (hexHeight * 0.75)) % 2 == 0 ? 0.0 : radius * 1.5;
      for (double x = rowOffset;
          x < size.width + hexWidth;
          x += hexWidth * 1.5) {
        _drawHexagon(canvas, Offset(x, y), radius);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * pi / 180;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paints.outline);
  }

  void drawCornell(Canvas canvas, Size size) {
    final leftRatio = (extraData?['leftMarginRatio'] as num?)?.toDouble();
    final bottomRatio = (extraData?['bottomSummaryRatio'] as num?)?.toDouble();
    final marginLeft = leftRatio != null
        ? size.width * leftRatio
        : (extraData?['marginLeft'] as num?)?.toDouble() ?? size.width * 0.3;
    final marginBottom = bottomRatio != null
        ? size.height * bottomRatio
        : (extraData?['marginBottom'] as num?)?.toDouble() ?? size.height * 0.2;

    // Cue column
    canvas.drawLine(
      Offset(marginLeft, 0),
      Offset(marginLeft, size.height - marginBottom),
      paints.bold,
    );

    // Summary divider
    canvas.drawLine(
      Offset(0, size.height - marginBottom),
      Offset(size.width, size.height - marginBottom),
      paints.bold,
    );

    // Note-taking lines
    for (double y = spacingPx * 2;
        y < size.height - marginBottom;
        y += spacingPx) {
      canvas.drawLine(
        Offset(marginLeft + 10, y),
        Offset(size.width, y),
        paints.line,
      );
    }
  }

  void drawMusic(Canvas canvas, Size size) {
    // Each staff has 5 lines.
    final staffLineSpacing = spacingPx * 0.25;
    final staffHeight = staffLineSpacing * 4;
    final staffGroupSpacing = spacingPx * 2;

    double y = spacingPx;

    while (y + staffHeight < size.height) {
      for (int i = 0; i < 5; i++) {
        final lineY = y + (i * staffLineSpacing);
        canvas.drawLine(
          Offset(0, lineY),
          Offset(size.width, lineY),
          paints.line,
        );
      }
      y += staffHeight + staffGroupSpacing;
    }
  }
}
