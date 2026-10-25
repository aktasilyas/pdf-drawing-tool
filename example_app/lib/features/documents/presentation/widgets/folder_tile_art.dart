import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Original folder drawing for library tiles, bottom-aligned in its box.
///
/// Body is `w x 0.78w` on the bottom edge: a darkened back panel with a tab,
/// a paper sheet peeking out, and a front panel in the (softened) folder
/// colour. All paints are built once in the initializer list.
class FolderTileArt extends CustomPainter {
  FolderTileArt({required this.color, required this.palette})
      : _backPaint = Paint()..color = _darken(color),
        _sheetPaint = Paint()..color = palette.paper,
        _frontPaint = Paint()
          ..color = Color.lerp(color, palette.surface, 0.30)!,
        _highlightPaint = Paint()
          ..color = palette.paper.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

  final Color color;
  final AppPalette palette;

  final Paint _backPaint;
  final Paint _sheetPaint;
  final Paint _frontPaint;
  final Paint _highlightPaint;

  static Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(math.max(0.0, hsl.lightness - 0.08)).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final radius = Radius.circular(w * 0.06);
    final bodyTop = size.height - w * 0.78;

    final body = RRect.fromLTRBR(0, bodyTop, w, size.height, radius);
    canvas.drawRRect(body, _backPaint);

    final tabRadius = Radius.circular(w * 0.04);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, bodyTop - w * 0.08, w * 0.40, w * 0.08 + radius.y),
        topLeft: tabRadius,
        topRight: tabRadius,
      ),
      _backPaint,
    );

    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.06, bodyTop + w * 0.05, w * 0.94, size.height,
          Radius.circular(w * 0.02)),
      _sheetPaint,
    );

    final frontTop = bodyTop + w * 0.20;
    canvas.drawRRect(
      RRect.fromLTRBR(0, frontTop, w, size.height, radius),
      _frontPaint,
    );
    canvas.drawLine(
      Offset(radius.x, frontTop + 0.5),
      Offset(w - radius.x, frontTop + 0.5),
      _highlightPaint,
    );
  }

  @override
  bool shouldRepaint(FolderTileArt oldDelegate) =>
      color != oldDelegate.color || palette != oldDelegate.palette;
}
