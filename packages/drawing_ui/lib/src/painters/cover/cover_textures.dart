import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/painters/cover/cover_noise.dart';

/// Records material textures once, in a unit 600x800 space.
///
/// Textures are neutral (white highlights, black shadows) so the cover base
/// color shows through; the renderer scales and alpha-blends the picture.
class CoverTextures {
  CoverTextures._();

  static const double width = 600;
  static const double height = 800;

  /// Builds the texture picture for [cover]. [detailed] selects the LOD used
  /// for large renders; small renders use a coarser, lower-density texture.
  static ui.Picture build(Cover cover, {required bool detailed}) {
    final recorder = ui.PictureRecorder();
    final canvas =
        ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, width, height));
    final r = CoverNoise.randomFor(cover.id);
    final density = detailed ? 1.0 : 0.4;
    switch (cover.material ?? CoverMaterial.linen) {
      case CoverMaterial.linen:
        _linen(canvas, r, density);
      case CoverMaterial.leather:
        _leather(canvas, r, density);
      case CoverMaterial.kraft:
        _kraft(canvas, r, density, ui.Color(cover.primaryColor));
      case CoverMaterial.felt:
        _felt(canvas, r, density);
    }
    return recorder.endRecording();
  }

  static ui.Paint _stroke(int argb, double w) => ui.Paint()
    ..color = ui.Color(argb)
    ..strokeWidth = w
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round;

  static int _alpha(int base, int alpha) =>
      (alpha.clamp(0, 255) << 24) | (base & 0xFFFFFF);

  /// Fine, even crosshatch: alternating light/dark threads split into short
  /// segments with slight alpha jitter, plus occasional slubs.
  static void _linen(ui.Canvas c, math.Random r, double d) {
    // Low detail keeps the same on-screen pitch as the 240dp render
    // (12 units at ~0.2 scale ~ 6 units at ~0.4) with a faded weave.
    final step = d >= 1 ? 6.0 : 12.0;
    final w = d >= 1 ? 1.6 : 3.4;
    final fade = d >= 1 ? 1.0 : 0.6;
    final p = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.butt;
    void thread(bool horizontal, double pos, bool isLight) {
      final base = isLight ? 0xFFFFFF : 0x000000;
      final alpha = ((isLight ? 0x14 : 0x12) * fade).round();
      final extent = horizontal ? width : height;
      var t = 0.0;
      while (t < extent) {
        final len = CoverNoise.range(r, 24, 90);
        final end = math.min(t + len, extent);
        p
          ..strokeWidth = w
          ..color = ui.Color(_alpha(base, alpha + r.nextInt(13) - 6));
        _seg(c, p, horizontal, pos, t, end);
        // Small break between thread pieces so it reads as woven.
        if (r.nextInt(3) == 0) {
          t = end + CoverNoise.range(r, 3, 9);
          continue;
        }
        if (r.nextInt(15) == 0) {
          final s = CoverNoise.range(r, 0, extent - 20);
          p
            ..strokeWidth = w * 1.5
            ..color = ui.Color(_alpha(base, alpha + 0x0A));
          _seg(c, p, horizontal, pos, s, s + CoverNoise.range(r, 8, 20));
        }
        t = end;
      }
    }

    var i = 0;
    for (var y = 0.0; y < height; y += step, i++) {
      thread(true, y, i.isEven);
    }
    i = 0;
    for (var x = 0.0; x < width; x += step, i++) {
      thread(false, x, i.isEven);
    }
  }

  static void _seg(ui.Canvas c, ui.Paint p, bool horizontal, double pos,
      double a, double b) {
    c.drawLine(horizontal ? ui.Offset(a, pos) : ui.Offset(pos, a),
        horizontal ? ui.Offset(b, pos) : ui.Offset(pos, b), p);
  }

  static void _leather(ui.Canvas c, math.Random r, double d) {
    final cells = (3900 * d).round();
    final p = ui.Paint();
    for (var i = 0; i < cells; i++) {
      final x = r.nextDouble() * width;
      final y = r.nextDouble() * height;
      final rad = CoverNoise.range(r, 1.5, 4);
      p.color = ui.Color(r.nextBool() ? 0x14000000 : 0x0AFFFFFF);
      c.drawOval(
          ui.Rect.fromCenter(
              center: ui.Offset(x, y), width: rad * 2, height: rad * 1.4),
          p);
    }
    final crease = _stroke(0x0C000000, 1)..strokeCap = ui.StrokeCap.butt;
    final creases = 3 + r.nextInt(3);
    for (var i = 0; i < creases; i++) {
      final a = ui.Offset(r.nextDouble() * width, r.nextDouble() * height);
      final b = a +
          ui.Offset(
              CoverNoise.range(r, -260, 260), CoverNoise.range(r, -260, 260));
      final mid = ui.Offset.lerp(a, b, 0.5)! +
          ui.Offset(CoverNoise.range(r, -30, 30), CoverNoise.range(r, -30, 30));
      c.drawPath(
          ui.Path()
            ..moveTo(a.dx, a.dy)
            ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy),
          crease);
    }
    final vignette = ui.Paint()
      ..shader = ui.Gradient.radial(const ui.Offset(width / 2, height / 2),
          height * 0.75, const [ui.Color(0x00000000), ui.Color(0x26000000)]);
    c.drawRect(const ui.Rect.fromLTWH(0, 0, width, height), vignette);
    _stitches(c, d >= 1 ? 2.5 : 5.0);
  }

  static void _stitches(ui.Canvas c, double w) {
    const inset = 32.0;
    final p = _stroke(0x55FFFFFF, w);
    const dash = 12.0;
    const gap = 8.0;
    for (var x = inset; x < width - inset; x += dash + gap) {
      final x2 = math.min(x + dash, width - inset);
      c.drawLine(ui.Offset(x, inset), ui.Offset(x2, inset), p);
      c.drawLine(
          ui.Offset(x, height - inset), ui.Offset(x2, height - inset), p);
    }
    for (var y = inset; y < height - inset; y += dash + gap) {
      final y2 = math.min(y + dash, height - inset);
      c.drawLine(ui.Offset(inset, y), ui.Offset(inset, y2), p);
      c.drawLine(ui.Offset(width - inset, y), ui.Offset(width - inset, y2), p);
    }
  }

  static void _kraft(ui.Canvas c, math.Random r, double d, ui.Color base) {
    final light = base.computeLuminance() > 0.35;
    final hi = light ? 0x22FFFFFF : 0x10FFFFFF;
    final fibres = (1400 * d).round();
    for (var i = 0; i < fibres; i++) {
      final x = r.nextDouble() * width;
      final y = r.nextDouble() * height;
      final len =
          light ? CoverNoise.range(r, 8, 26) : CoverNoise.range(r, 6, 16);
      final a =
          CoverNoise.range(r, -0.5, 0.5) + (r.nextBool() ? 0 : math.pi / 2);
      c.drawLine(
          ui.Offset(x, y),
          ui.Offset(x + math.cos(a) * len, y + math.sin(a) * len),
          _stroke(r.nextBool() ? 0x1E000000 : hi, 1.2));
    }
    final fleck = ui.Paint()..color = const ui.Color(0x38000000);
    final specks = (260 * d).round();
    for (var i = 0; i < specks; i++) {
      c.drawCircle(ui.Offset(r.nextDouble() * width, r.nextDouble() * height),
          CoverNoise.range(r, 0.8, 2), fleck);
    }
  }

  /// Felt: soft cloudy mottle under fine specks (mottle only at low detail).
  static void _felt(ui.Canvas c, math.Random r, double d) {
    // Only 2-3 large, faint patches; the fibre grain carries the texture.
    final blobs = 2 + r.nextInt(2);
    final cloud = ui.Paint()
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 50);
    for (var i = 0; i < blobs; i++) {
      cloud.color = ui.Color(i.isEven ? 0x07FFFFFF : 0x07000000);
      c.drawCircle(ui.Offset(r.nextDouble() * width, r.nextDouble() * height),
          CoverNoise.range(r, 110, 190), cloud);
    }
    if (d < 1) return;
    final specks = (9000 * d).round();
    final p = ui.Paint();
    for (var i = 0; i < specks; i++) {
      p.color = ui.Color(r.nextBool() ? 0x1CFFFFFF : 0x18000000);
      c.drawCircle(ui.Offset(r.nextDouble() * width, r.nextDouble() * height),
          CoverNoise.range(r, 0.8, 2.2), p);
    }
  }
}
