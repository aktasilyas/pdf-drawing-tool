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
  static void shadow(ui.Canvas c, CoverGeometry g) {
    final u = g.unit;
    final outer = g.pageLayer(3);
    c.drawRRect(
        outer.shift(ui.Offset(u * 0.014, u * 0.026)),
        ui.Paint()
          ..color = const ui.Color(0x47000000)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, u * 0.022));
    c.drawRRect(
        outer.shift(ui.Offset(u * 0.003, u * 0.007)),
        ui.Paint()
          ..color = const ui.Color(0x73000000)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, u * 0.005));
  }

  /// Three cream page-edge layers on the fore-edge and bottom.
  static void pages(ui.Canvas c, CoverGeometry g) {
    final line = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = (g.unit * 0.0016).clamp(0.4, 1.0)
      ..color = const ui.Color(0x38000000);
    const creams = [
      ui.Color(0xFFEFE8D6),
      ui.Color(0xFFF7F2E4),
      ui.Color(0xFFE9E1CD)
    ];
    for (var k = 3; k >= 1; k--) {
      final r = g.pageLayer(k);
      c.drawRRect(r, ui.Paint()..color = creams[k - 1]);
      c.drawRRect(r, line);
    }
  }

  /// Cover body: base colour, material grain, light, vignette, spine, bevel.
  /// Clipped to the cover shape by the caller.
  static void body(ui.Canvas c, CoverGeometry g, Cover cover,
      {double textureScale = 1}) {
    final base = ui.Color(cover.primaryColor);
    final r = g.cover;
    c.drawRect(r, ui.Paint()..color = base);

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

    // Soft top-left light and bottom-right falloff.
    c.drawRect(
        r,
        ui.Paint()
          ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, const [
            ui.Color(0x2EFFFFFF),
            ui.Color(0x00FFFFFF),
            ui.Color(0x2E000000),
          ], const [
            0,
            0.45,
            1
          ]));
    // Gentle vignette.
    c.drawRect(
        r,
        ui.Paint()
          ..shader = ui.Gradient.radial(
              r.center,
              r.longestSide * 0.78,
              const [ui.Color(0x00000000), ui.Color(0x38000000)],
              const [0.55, 1.0],
              ui.TileMode.clamp));
    spine(c, g);
  }

  /// Binding band with a hinge crease: dark band, thin highlight, soft inner
  /// shadow where the cover bends.
  static void spine(ui.Canvas c, CoverGeometry g) {
    final r = g.cover;
    final sw = g.spineWidth;
    final band = ui.Rect.fromLTWH(r.left, r.top, sw, r.height);
    c.drawRect(
        band,
        ui.Paint()
          ..shader =
              ui.Gradient.linear(band.centerLeft, band.centerRight, const [
            ui.Color(0x4A000000),
            ui.Color(0x0A000000),
            ui.Color(0x3A000000),
          ], const [
            0,
            0.4,
            1
          ]));
    final px = (g.unit * 0.004).clamp(0.8, 2.0);
    final x = r.left + sw;
    // Crease: dark groove, then a highlight line, then the soft inner shadow.
    c.drawRect(ui.Rect.fromLTWH(x - px, r.top, px, r.height),
        ui.Paint()..color = const ui.Color(0x66000000));
    c.drawRect(ui.Rect.fromLTWH(x, r.top, px, r.height),
        ui.Paint()..color = const ui.Color(0x40FFFFFF));
    final soft = ui.Rect.fromLTWH(x + px, r.top, g.unit * 0.04, r.height);
    c.drawRect(
        soft,
        ui.Paint()
          ..shader = ui.Gradient.linear(soft.centerLeft, soft.centerRight,
              const [ui.Color(0x38000000), ui.Color(0x00000000)]));
  }

  /// Faint edge bevel: lit top-left, shaded bottom-right.
  static void bevel(ui.Canvas c, CoverGeometry g, {double strength = 1}) {
    final w = (g.unit * 0.005).clamp(0.8, 3.0);
    final rr = g.coverRRect.deflate(w / 2);
    final a = (0x66 * strength).round().clamp(0, 255);
    final b = (0x5C * strength).round().clamp(0, 255);
    c.drawRRect(
        rr,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = w
          ..shader = ui.Gradient.linear(g.cover.topLeft, g.cover.bottomRight, [
            ui.Color.fromARGB(a, 255, 255, 255),
            const ui.Color(0x00FFFFFF),
            ui.Color.fromARGB(b, 0, 0, 0),
          ], const [
            0,
            0.5,
            1
          ]));
  }
}
