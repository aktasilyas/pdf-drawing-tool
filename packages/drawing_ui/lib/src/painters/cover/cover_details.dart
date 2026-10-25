import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/painting.dart' show HSLColor;
import 'package:drawing_ui/src/painters/cover/cover_geometry.dart';
import 'package:drawing_ui/src/painters/cover/cover_layers.dart';
import 'package:drawing_ui/src/painters/cover/cover_material_style.dart';

/// Sparse per-family details. Not every cover gets one, and the fine ones are
/// dropped at small sizes where they would only add noise.
class CoverDetails {
  CoverDetails._();

  static const _stitched = {'leather_oxblood'};
  static const _elastic = {'leather_navy'};
  static const _ribbon = {
    'leather_oxblood': ui.Color(0xFFC8A25A),
    'leather_navy': ui.Color(0xFF8C2F39),
  };

  /// Warm paper tone of the kraft label plate.
  static const _paper = ui.Color(0xFFEFE3C8);

  /// Whether this cover carries a paper label plate (kraft only).
  static bool hasLabelPlate(Cover cover) =>
      cover.material == CoverMaterial.kraft;

  /// Details drawn on the board (inside the cover clip).
  static void onBoard(ui.Canvas c, CoverGeometry g, Cover cover) {
    if (_stitched.contains(cover.id) && !g.compact) {
      _stitching(c, g, ui.Color(cover.primaryColor));
    }
    if (_elastic.contains(cover.id) && !g.compact) _elasticBand(c, g);
    if (hasLabelPlate(cover)) _labelPlate(c, g, cover);
  }

  /// Details that stick out past the board (drawn before the board).
  static void behindBoard(ui.Canvas c, CoverGeometry g, Cover cover) {
    final color = _ribbon[cover.id];
    if (color != null && !g.compact) _ribbonTail(c, g, color);
  }

  /// Blind-stitched border: inset 8 dp, follows the fore-edge corner radius
  /// and is square at the spine; short thread segments with needle holes.
  static void _stitching(ui.Canvas c, CoverGeometry g, ui.Color base) {
    final dp = g.dp;
    final inset = dp * 8;
    final rect = g.face.deflate(inset);
    final rr = ui.RRect.fromRectAndCorners(
      rect,
      topRight: ui.Radius.circular(math.max(g.radius - inset * 0.6, dp)),
      bottomRight: ui.Radius.circular(math.max(g.radius - inset * 0.6, dp)),
    );
    final path = ui.Path()..addRRect(rr);
    final hsl = HSLColor.fromColor(base);
    final threadColor = hsl
        .withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0))
        .withSaturation(hsl.saturation * 0.55)
        .toColor();
    final thread = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = dp * 1.6
      ..strokeCap = ui.StrokeCap.round
      ..color = threadColor;
    final shadow = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = dp * 1.4
      ..strokeCap = ui.StrokeCap.round
      ..color = const ui.Color(0x66000000);
    final hole = ui.Paint()..color = const ui.Color(0x59000000);
    final dash = dp * 3;
    final gap = dp * 1.5;
    var i = 0;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += dash + gap, i++) {
        // Deterministic +/-0.3 dp jitter so the line is not machine-perfect.
        final j = (((i * 37) % 7) - 3) / 3 * dp * 0.3;
        final seg = m
            .extractPath(d, (d + dash).clamp(0, m.length))
            .shift(ui.Offset(j, -j));
        c.drawPath(seg.shift(ui.Offset(0, dp * 0.5)), shadow);
        c.drawPath(seg, thread);
        final t = m.getTangentForOffset(d);
        if (t != null) c.drawCircle(t.position, dp * 0.45, hole);
      }
    }
  }

  static void _elasticBand(ui.Canvas c, CoverGeometry g) {
    final w = g.dp * 7;
    final x = g.cover.right - g.dp * 18 - w / 2;
    final band = ui.Rect.fromLTWH(x, g.cover.top - 1, w, g.cover.height + 2);
    c.drawRect(
        band.shift(ui.Offset(g.dp * 1.2, g.dp * 0.6)),
        ui.Paint()
          ..color = const ui.Color(0x99000000)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, g.dp * 1.2));
    // Round, shaded cord: dark edges, soft highlight just left of centre.
    c.drawRect(
        band,
        ui.Paint()
          ..shader =
              ui.Gradient.linear(band.centerLeft, band.centerRight, const [
            ui.Color(0xFF07080B),
            ui.Color(0xFF30333C),
            ui.Color(0xFF16181E),
            ui.Color(0xFF07080B),
          ], const [
            0,
            0.38,
            0.7,
            1
          ]));
  }

  /// Ribbon bookmark: 5 dp wide, V-cut tail, shaded fold.
  static void _ribbonTail(ui.Canvas c, CoverGeometry g, ui.Color color) {
    final w = g.dp * 5;
    final x = g.face.left + g.face.width * 0.66;
    final top = g.cover.bottom - g.dp * 4;
    final bottom = g.pageLayer(g.pageLayers).outerRect.bottom + g.dp * 8;
    final mid = bottom - w * 0.9;
    final path = ui.Path()
      ..moveTo(x, top)
      ..lineTo(x + w, top)
      ..lineTo(x + w, bottom)
      ..lineTo(x + w / 2, mid)
      ..lineTo(x, bottom)
      ..close();
    c.drawPath(
        path.shift(ui.Offset(g.dp, g.dp)),
        ui.Paint()
          ..color = const ui.Color(0x80000000)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, g.dp));
    c.drawPath(
        path,
        ui.Paint()
          ..shader = ui.Gradient.linear(ui.Offset(x, 0), ui.Offset(x + w, 0), [
            CoverLayers.mix(color, const ui.Color(0xFF000000), 0.3),
            CoverLayers.mix(color, const ui.Color(0xFFFFFFFF), 0.18),
            CoverLayers.mix(color, const ui.Color(0xFF000000), 0.25),
          ], const [
            0,
            0.5,
            1
          ]));
    // Darker where the ribbon tucks under the page block.
    c.drawRect(
        ui.Rect.fromLTRB(x, g.pageLayer(g.pageLayers).outerRect.bottom - g.dp,
            x + w, g.pageLayer(g.pageLayers).outerRect.bottom + g.dp * 2.5),
        ui.Paint()
          ..shader = ui.Gradient.linear(
              ui.Offset(0, g.pageLayer(g.pageLayers).outerRect.bottom - g.dp),
              ui.Offset(
                  0, g.pageLayer(g.pageLayers).outerRect.bottom + g.dp * 2.5),
              const [ui.Color(0x66000000), ui.Color(0x00000000)]));
  }

  /// Warm paper label plate: own fibre texture, 2 dp radius, darker kraft
  /// hairline, 1 dp contact + 3 dp soft shadow. No white box.
  static void _labelPlate(ui.Canvas c, CoverGeometry g, Cover cover) {
    final rect = g.plateRect;
    final dp = g.dp;
    final rr = ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(dp * 2));
    c.drawRRect(
        rr.shift(ui.Offset(0, dp * 2)),
        ui.Paint()
          ..color = const ui.Color(0x4D000000)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, dp * 1.5));
    c.drawRRect(
        rr.shift(ui.Offset(0, dp)),
        ui.Paint()
          ..color = const ui.Color(0x73000000)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, dp * 0.4));
    c.drawRRect(rr, ui.Paint()..color = _paper);
    c.save();
    c.clipRRect(rr);
    final paints = CoverMaterialStyle.paints(CoverMaterial.kraft, _paper,
        g.unit * 0.6, const ui.Color(0xFFFFFFFF), const ui.Color(0xFF6B5A3E),
        scale: 1.0);
    if (paints != null) {
      for (final p in paints) {
        c.drawRect(rect, p);
      }
    }
    c.restore();
    c.drawRRect(
        rr,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 0.75
          ..color = CoverLayers.mix(
              ui.Color(cover.primaryColor), const ui.Color(0xFF000000), 0.4));
  }
}
