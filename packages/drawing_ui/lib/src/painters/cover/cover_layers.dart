import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/painters/cover/cover_geometry.dart';
import 'package:drawing_ui/src/painters/cover/cover_material_style.dart';

/// Notebook-object layers shared by every cover material. Everything here
/// runs once per (cover, size) while recording the cached picture.
class CoverLayers {
  CoverLayers._();

  static const _black = ui.Color(0xFF000000);
  static const _white = ui.Color(0xFFFFFFFF);

  static ui.Color mix(ui.Color a, ui.Color b, double t) =>
      ui.Color.lerp(a, b, t)!;

  /// Two-layer drop shadow: tight contact shadow + soft ambient shadow.
  /// Strong enough to separate the book from a dark background.
  ///
  /// The page block runs under the spine, but the shadows start further in
  /// so neither spills into the margin left of the book (light is top-left).
  static void shadow(ui.Canvas c, CoverGeometry g) {
    final dp = g.dp;
    final ambient = _shadowSource(g, g.cover.left + g.spineWidth);
    c.drawRRect(
        ambient.shift(ui.Offset(dp * 2, dp * 6)),
        ui.Paint()
          ..color = const ui.Color(0x8C000000)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, dp * 6));
    final contact = _shadowSource(g, g.cover.left + dp * 3);
    c.drawRRect(
        contact.shift(ui.Offset(dp * 0.5, dp * 1.5)),
        ui.Paint()
          ..color = const ui.Color(0xB3000000)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, dp * 0.8));
  }

  /// The outer page-block shape with its left edge moved to [left].
  static ui.RRect _shadowSource(CoverGeometry g, double left) {
    final outer = g.pageLayer(g.pageLayers);
    final rect = ui.Rect.fromLTRB(left, outer.top, outer.right, outer.bottom);
    return ui.RRect.fromRectAndCorners(
      rect,
      topRight: outer.trRadius,
      bottomRight: outer.brRadius,
    );
  }

  /// Page-edge layers on the fore-edge and bottom (about 80% of paper tone,
  /// so they stay visible against both light and dark backgrounds).
  static void pages(ui.Canvas c, CoverGeometry g) {
    final line = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const ui.Color(0x33000000);
    const tones = [
      ui.Color(0xFFCFC8B8),
      ui.Color(0xFFD9D2C2),
      ui.Color(0xFFC4BDAC),
    ];
    // The block's left edge lines up with the board's anti-aliased edge;
    // drawing both there leaves a 1px seam, so hide it wherever the board
    // covers it and keep it only below the board, where it meets the corner.
    final r0 = g.cover;
    final seam = ui.Rect.fromLTRB(
      r0.left - g.dp,
      r0.top - g.dp,
      r0.left + g.dp,
      r0.bottom - g.dp * 0.5,
    );
    c.save();
    c.clipRect(seam, clipOp: ui.ClipOp.difference);
    for (var k = g.pageLayers; k >= 1; k--) {
      final r = g.pageLayer(k);
      c.drawRRect(r, ui.Paint()..color = tones[(k - 1) % 3]);
      if (g.pageLayers > 1) c.drawRRect(r, line);
    }
    c.restore();
  }

  /// Cover body: base colour, material grain, light, hue-keeping vignette,
  /// spine and top rim. Clipped to the cover shape by the caller.
  static void body(ui.Canvas c, CoverGeometry g, Cover cover,
      {double textureScale = 1}) {
    final base = ui.Color(cover.primaryColor);
    final r = g.cover;
    c.drawRect(r, ui.Paint()..color = base);

    // One continuous grain across spine and face.
    final paints = CoverMaterialStyle.paints(
      cover.material ?? CoverMaterial.linen,
      base,
      g.unit,
      mix(base, _white, 0.55),
      mix(base, _black, 0.7),
      scale: textureScale,
    );
    if (paints != null) {
      for (final p in paints) {
        c.drawRect(r, p);
      }
    }

    // Soft top-left light.
    c.drawRect(
        r,
        ui.Paint()
          ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, const [
            ui.Color(0x26FFFFFF),
            ui.Color(0x00FFFFFF),
          ], const [
            0,
            0.55
          ]));
    // Vignette: multiply with a tinted, darkened cover colour so the hue is
    // kept (never neutral black or grey).
    final edge = mix(_white, base, 0.32);
    c.drawRect(
        r,
        ui.Paint()
          ..blendMode = ui.BlendMode.multiply
          ..shader = ui.Gradient.radial(r.center, r.longestSide * 0.8,
              [_white, _white, edge], const [0, 0.5, 1.0], ui.TileMode.clamp));
    // 1 dp top rim highlight.
    c.drawRect(ui.Rect.fromLTWH(r.left, r.top, r.width, g.dp),
        ui.Paint()..color = const ui.Color(0x14FFFFFF));
    spine(c, g);
  }

  /// Binding band: hue-preserving horizontal darkening (multiply, outer edge
  /// about -22%, about -8% at the crease) and a groove-style hinge.
  static void spine(ui.Canvas c, CoverGeometry g) {
    final r = g.cover;
    final sw = g.spineWidth;
    final band = ui.Rect.fromLTWH(r.left, r.top, sw, r.height);
    c.drawRect(
        band,
        ui.Paint()
          ..blendMode = ui.BlendMode.multiply
          ..shader =
              ui.Gradient.linear(band.centerLeft, band.centerRight, const [
            ui.Color(0xFFC7C7C7),
            ui.Color(0xFFEBEBEB),
          ]));
    final px = g.dp;
    final x = r.left + sw;
    // Groove: 1 dp black ~28%, 1 dp white ~15% to its right, 6 dp soft inner
    // shadow falling onto the front.
    c.drawRect(ui.Rect.fromLTWH(x - px, r.top, px, r.height),
        ui.Paint()..color = const ui.Color(0x47000000));
    c.drawRect(ui.Rect.fromLTWH(x, r.top, px, r.height),
        ui.Paint()..color = const ui.Color(0x26FFFFFF));
    final soft = ui.Rect.fromLTWH(x + px, r.top, g.dp * 6, r.height);
    c.drawRect(
        soft,
        ui.Paint()
          ..shader = ui.Gradient.linear(soft.centerLeft, soft.centerRight,
              const [ui.Color(0x33000000), ui.Color(0x00000000)]));
  }

  /// Soft bevel roll (about 1.5 dp, blurred) lit top-left, shaded bottom-right.
  static void bevel(ui.Canvas c, CoverGeometry g, {double strength = 1}) {
    final w = g.dp * 1.5;
    final a = (0x40 * strength).round().clamp(0, 255);
    final b = (0x40 * strength).round().clamp(0, 255);
    c.save();
    c.clipRRect(g.coverRRect);
    c.drawRRect(
        g.coverRRect.deflate(w / 2),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = w
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, g.dp * 0.6)
          ..shader = ui.Gradient.linear(g.cover.topLeft, g.cover.bottomRight, [
            ui.Color.fromARGB(a, 255, 255, 255),
            const ui.Color(0x00FFFFFF),
            ui.Color.fromARGB(b, 0, 0, 0),
          ], const [
            0,
            0.5,
            1
          ]));
    c.restore();
  }
}
