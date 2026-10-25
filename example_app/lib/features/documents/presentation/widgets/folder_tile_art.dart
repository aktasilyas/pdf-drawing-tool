import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:drawing_ui/drawing_ui.dart' show CoverGeometry;

import 'package:example_app/core/theme/index.dart';

/// Original folder drawing for library tiles, bottom-aligned in the cover
/// board rect of its box.
///
/// Body is `w x 0.78w` on the board's bottom edge: a darkened back panel
/// with a tab, two paper sheets peeking out, and a front panel with a soft
/// top-lit gradient in the tamed folder colour, over a soft contact shadow
/// (same depth language as the notebook covers). Paints are built once in
/// the initializer list; the front-panel gradient shader is rebuilt per paint from precomputed colours.
class FolderTileArt extends CustomPainter {
  FolderTileArt({required this.color, required this.palette})
      : _backPaint = Paint()..color = _darken(_tame(color)),
        _sheetPaint = Paint()..color = palette.paper,
        _frontPaint = Paint()..color = _tame(color),
        _edgePaint = Paint()
          ..color = _darken(_tame(color), 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
        _shadowPaint = Paint()
          ..color = palette.textPrimary.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        _sheetEdgePaint = Paint()
          ..color = palette.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.75,
        _gradientColors = [
          _lighten(_tame(color)),
          _tame(color),
          _darken(_tame(color), 0.05),
        ],
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
  final List<Color> _gradientColors;
  final Paint _shadowPaint;
  final Paint _sheetEdgePaint;

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

  static Color _lighten(Color c, [double amount = 0.05]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(math.min(1.0, hsl.lightness + amount)).toColor();
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
    canvas.drawRRect(body.shift(Offset(0, w * 0.015)), _shadowPaint);
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

    for (final inset in const [0.09, 0.06]) {
      final sheet = RRect.fromLTRBR(
        r.left + w * inset,
        bodyTop + w * (inset - 0.01),
        r.left + w * (1 - inset),
        bottom,
        Radius.circular(w * 0.02),
      );
      canvas.drawRRect(sheet, _sheetPaint);
      canvas.drawRRect(sheet, _sheetEdgePaint);
    }

    final frontTop = bodyTop + w * 0.20;
    final front = Rect.fromLTRB(r.left, frontTop, r.right, bottom);
    _frontPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: _gradientColors,
      stops: const [0, 0.35, 1],
    ).createShader(front);
    canvas.drawRRect(RRect.fromRectAndRadius(front, radius), _frontPaint);
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
