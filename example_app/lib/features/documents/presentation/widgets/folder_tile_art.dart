import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:drawing_ui/drawing_ui.dart' show CoverGeometry;

import 'package:example_app/core/theme/index.dart';

/// Original folder drawing for library tiles, bottom-aligned in the cover
/// board rect of its box.
///
/// Body is `w x 0.78w` on the board's bottom edge: a darkened back panel
/// with a tab, a paper sheet peeking out, and a front panel in the tamed
/// folder colour. All paints are built once in the initializer list.
class FolderTileArt extends CustomPainter {
  FolderTileArt({required this.color, required this.palette})
      : _backPaint = Paint()..color = _darken(_tame(color)),
        _sheetPaint = Paint()..color = palette.paper,
        _frontPaint = Paint()..color = _tame(color),
        _edgePaint = Paint()
          ..color = _darken(_tame(color), 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
        _highlightPaint = Paint()
          ..color = palette.paper.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

  final Color color;
  final AppPalette palette;

  final Paint _backPaint;
  final Paint _sheetPaint;
  final Paint _frontPaint;
  final Paint _edgePaint;
  final Paint _highlightPaint;

  /// Calms saturated folder colours the same way in light and dark themes.
  static Color _tame(Color c) {
    final hsl = HSLColor.fromColor(c);
    final saturation = math.min(hsl.saturation, 0.45);
    final lightness = hsl.lightness.clamp(0.42, 0.62).toDouble();
    return hsl.withSaturation(saturation).withLightness(lightness).toColor();
  }

  static Color _darken(Color c, [double amount = 0.08]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(math.max(0.0, hsl.lightness - amount)).toColor();
  }

  /// The folder body (without the tab) when painted in a box of [box].
  static Rect bodyRect(Size box) {
    final r = CoverGeometry.of(box).cover;
    final top = r.bottom - r.width * 0.78;
    return Rect.fromLTRB(r.left, top, r.right, r.bottom);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = CoverGeometry.of(size).cover;
    final w = r.width;
    final bottom = r.bottom;
    final radius = Radius.circular(w * 0.06);
    final bodyTop = bottom - w * 0.78;

    final body = RRect.fromLTRBR(r.left, bodyTop, r.right, bottom, radius);
    canvas.drawRRect(body, _backPaint);

    final tabRadius = Radius.circular(w * 0.04);
    final tabTop = bodyTop - w * 0.08;
    final tabHeight = w * 0.08 + radius.y;
    final tabRect = Rect.fromLTWH(r.left, tabTop, w * 0.40, tabHeight);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        tabRect,
        topLeft: tabRadius,
        topRight: tabRadius,
      ),
      _backPaint,
    );

    canvas.drawRRect(
      RRect.fromLTRBR(
        r.left + w * 0.06,
        bodyTop + w * 0.05,
        r.left + w * 0.94,
        bottom,
        Radius.circular(w * 0.02),
      ),
      _sheetPaint,
    );

    final frontTop = bodyTop + w * 0.20;
    canvas.drawRRect(
      RRect.fromLTRBR(r.left, frontTop, r.right, bottom, radius),
      _frontPaint,
    );
    canvas.drawLine(
      Offset(r.left + radius.x, frontTop + 0.5),
      Offset(r.right - radius.x, frontTop + 0.5),
      _highlightPaint,
    );
    canvas.drawLine(
      Offset(r.left + radius.x, bottom - 0.5),
      Offset(r.right - radius.x, bottom - 0.5),
      _edgePaint,
    );
  }

  @override
  bool shouldRepaint(FolderTileArt oldDelegate) =>
      color != oldDelegate.color || palette != oldDelegate.palette;
}
