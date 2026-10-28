import 'dart:ui';

import 'template_structural_helpers.dart';

/// Mixin providing the design-sketch template painters.
///
/// Contains: storyboard, wireframe.
/// All measurements proportional. All colors derive from lineColor.
mixin TemplateCreativePainters on TemplateStructuralHelpers {
  void drawStoryboard(Canvas canvas, Size size) {
    final margin = size.width * 0.04;
    final headerH = size.height * 0.05;
    final framesPerPage = (extraData?['framesPerPage'] as int?) ?? 6;
    const cols = 2;
    final rows = (framesPerPage / cols).ceil();

    drawDividerLine(canvas, headerH, margin, size.width - margin);

    final cellW = (size.width - margin * 2) / cols;
    final cellH = (size.height - headerH - margin) / rows;
    final framePadding = cellW * 0.08;

    final aspectStr = (extraData?['aspectRatio'] as String?) ?? '16:9';
    final parts = aspectStr.split(':');
    final aspect =
        (double.tryParse(parts[0]) ?? 16) / (double.tryParse(parts[1]) ?? 9);

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        _drawStoryboardFrame(canvas, margin, headerH, row, col, cellW, cellH,
            framePadding, aspect);
      }
    }
  }

  void _drawStoryboardFrame(
    Canvas canvas,
    double margin,
    double headerH,
    int row,
    int col,
    double cellW,
    double cellH,
    double framePadding,
    double aspect,
  ) {
    final cellX = margin + (col * cellW);
    final cellY = headerH + (row * cellH);

    final frameW = cellW - framePadding * 2;
    var frameH = frameW / aspect;
    if (frameH > cellH * 0.6) frameH = cellH * 0.6;

    final frameX = cellX + framePadding;
    final frameY = cellY + framePadding;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(frameX, frameY, frameW, frameH),
        Radius.circular(frameW * 0.01),
      ),
      accent.ink,
    );

    // Description lines
    final descY = frameY + frameH + framePadding * 0.8;
    final descLineSpacing = cellH * 0.08;
    for (var i = 0; i < 2; i++) {
      final y = descY + (i * descLineSpacing);
      if (y < cellY + cellH - framePadding * 0.5) {
        canvas.drawLine(
            Offset(frameX, y), Offset(frameX + frameW, y), accent.hair3);
      }
    }
  }

  void drawWireframe(Canvas canvas, Size size) {
    final margin = size.width * 0.04;
    final headerH = size.height * 0.05;
    final deviceType = (extraData?['deviceType'] as String?) ?? 'mobile';
    final framesPerPage = (extraData?['framesPerPage'] as int?) ?? 3;

    drawDividerLine(canvas, headerH, margin, size.width - margin);

    final deviceAspect = deviceType == 'tablet' ? 4.0 / 3.0 : 9.0 / 19.5;
    final availableH = size.height - headerH - margin * 2;
    final frameH = availableH / framesPerPage - margin;
    final frameW = frameH * deviceAspect;
    final frameX = (size.width - frameW) * 0.5;

    for (var i = 0; i < framesPerPage; i++) {
      final frameY = headerH + margin + (i * (frameH + margin));
      _drawWireframeDevice(canvas, frameX, frameY, frameW, frameH);
    }
  }

  void _drawWireframeDevice(
    Canvas canvas,
    double frameX,
    double frameY,
    double frameW,
    double frameH,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(frameX, frameY, frameW, frameH),
        Radius.circular(frameW * 0.06),
      ),
      accent.ink15,
    );

    // Inner grid (optional)
    if (extraData?['showGrid'] == true) {
      final innerMargin = frameW * 0.05;
      final gridSpacing = frameW * 0.1;
      for (var x = frameX + innerMargin + gridSpacing;
          x < frameX + frameW - innerMargin;
          x += gridSpacing) {
        canvas.drawLine(Offset(x, frameY + innerMargin),
            Offset(x, frameY + frameH - innerMargin), accent.gridFaint);
      }
      for (var y = frameY + innerMargin + gridSpacing;
          y < frameY + frameH - innerMargin;
          y += gridSpacing) {
        canvas.drawLine(Offset(frameX + innerMargin, y),
            Offset(frameX + frameW - innerMargin, y), accent.gridFaint);
      }
    }

    // Status bar hint
    final statusY = frameY + frameH * 0.04;
    canvas.drawLine(
      Offset(frameX + frameW * 0.1, statusY),
      Offset(frameX + frameW * 0.9, statusY),
      accent.statusFaint,
    );
  }
}
