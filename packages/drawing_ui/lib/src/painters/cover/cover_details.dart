import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/painters/cover/cover_geometry.dart';
import 'package:drawing_ui/src/painters/cover/cover_layers.dart';
import 'package:drawing_ui/src/painters/cover/cover_material_style.dart';

/// Sparse per-family details. Not every cover gets one, and the fine ones are
/// dropped at small sizes where they would only add noise.
class CoverDetails {
  CoverDetails._();

  /// Below this render width stitching is skipped.
  static const double stitchMinWidth = 150;

  static const _stitched = {'leather_oxblood', 'leather_cognac'};
  static const _elastic = {'leather_navy'};
  static const _ribbon = {
    'leather_oxblood': ui.Color(0xFFC8A25A),
    'leather_navy': ui.Color(0xFF8C2F39),
  };

  /// Whether this cover carries a paper label plate (kraft only).
  static bool hasLabelPlate(Cover cover) =>
      cover.material == CoverMaterial.kraft;

  /// Details drawn on the board (inside the cover clip).
  static void onBoard(ui.Canvas c, CoverGeometry g, Cover cover) {
    if (_stitched.contains(cover.id) && g.unit >= stitchMinWidth) {
      _stitching(c, g, ui.Color(cover.primaryColor));
    }
    if (_elastic.contains(cover.id)) _elasticBand(c, g);
    if (hasLabelPlate(cover)) _labelPlate(c, g, cover);
  }

  /// Details that stick out past the board (drawn before the board).
  static void behindBoard(ui.Canvas c, CoverGeometry g, Cover cover) {
    final color = _ribbon[cover.id];
    if (color != null) _ribbonTail(c, g, color);
  }

  static void _stitching(ui.Canvas c, CoverGeometry g, ui.Color base) {
    final inset = g.unit * 0.05;
    final r = g.face.deflate(inset).translate(inset * 0.15, 0);
    final path = ui.Path()
      ..addRRect(
          ui.RRect.fromRectAndRadius(r, ui.Radius.circular(g.radius * 0.5)));
    final w = g.unit * 0.0065;
    final thread = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = ui.StrokeCap.round
      ..color = CoverLayers.mix(base, const ui.Color(0xFFF4E9D2), 0.45)
          .withValues(alpha: 0.85);
    final groove = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = w * 1.5
      ..strokeCap = ui.StrokeCap.round
      ..color = const ui.Color(0x59000000);
    final dash = g.unit * 0.026;
    final gap = g.unit * 0.017;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += dash + gap) {
        final seg = m.extractPath(d, (d + dash).clamp(0, m.length));
        c.drawPath(seg.shift(ui.Offset(0, w * 0.5)), groove);
        c.drawPath(seg, thread);
      }
    }
  }

  static void _elasticBand(ui.Canvas c, CoverGeometry g) {
    final w = g.unit * 0.034;
    final x = g.cover.right - g.unit * 0.075 - w / 2;
    final band = ui.Rect.fromLTWH(x, g.cover.top - 1, w, g.cover.height + 2);
    c.drawRect(
        band.shift(ui.Offset(g.unit * 0.004, g.unit * 0.002)),
        ui.Paint()
          ..color = const ui.Color(0x80000000)
          ..maskFilter =
              ui.MaskFilter.blur(ui.BlurStyle.normal, g.unit * 0.005));
    c.drawRect(
        band,
        ui.Paint()
          ..shader =
              ui.Gradient.linear(band.centerLeft, band.centerRight, const [
            ui.Color(0xFF0E0F13),
            ui.Color(0xFF2A2D35),
            ui.Color(0xFF111217),
          ], const [
            0,
            0.45,
            1
          ]));
    if (g.unit >= stitchMinWidth) {
      final rib = ui.Paint()
        ..strokeWidth = 0.6
        ..color = const ui.Color(0x1FFFFFFF);
      for (var i = 1; i < 4; i++) {
        final lx = x + w * i / 4;
        c.drawLine(ui.Offset(lx, band.top), ui.Offset(lx, band.bottom), rib);
      }
    }
  }

  static void _ribbonTail(ui.Canvas c, CoverGeometry g, ui.Color color) {
    final w = g.unit * 0.03;
    final x = g.face.left + g.face.width * 0.66;
    final top = g.cover.bottom - g.unit * 0.02;
    final bottom = g.pageLayer(3).outerRect.bottom + g.unit * 0.034;
    final mid = bottom - w * 0.55;
    final path = ui.Path()
      ..moveTo(x, top)
      ..lineTo(x + w, top)
      ..lineTo(x + w, bottom)
      ..lineTo(x + w / 2, mid)
      ..lineTo(x, bottom)
      ..close();
    c.drawPath(
        path.shift(ui.Offset(g.unit * 0.004, g.unit * 0.004)),
        ui.Paint()
          ..color = const ui.Color(0x66000000)
          ..maskFilter =
              ui.MaskFilter.blur(ui.BlurStyle.normal, g.unit * 0.004));
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
  }

  /// Paper label plate with its own fibre texture and a soft shadow.
  static void _labelPlate(ui.Canvas c, CoverGeometry g, Cover cover) {
    final rect = g.titleRect;
    final rr =
        ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(g.unit * 0.008));
    c.drawRRect(
        rr.shift(ui.Offset(g.unit * 0.002, g.unit * 0.006)),
        ui.Paint()
          ..color = const ui.Color(0x66000000)
          ..maskFilter =
              ui.MaskFilter.blur(ui.BlurStyle.normal, g.unit * 0.008));
    const paper = ui.Color(CoverFamily.labelPlateColor);
    c.drawRRect(rr, ui.Paint()..color = paper);
    c.save();
    c.clipRRect(rr);
    final paints = CoverMaterialStyle.paints(CoverMaterial.kraft, paper,
        g.unit * 0.55, const ui.Color(0xFFFFFFFF), const ui.Color(0xFF6B5A3E),
        scale: 0.35);
    if (paints != null) {
      for (final p in paints) {
        c.drawRect(rect, p);
      }
    }
    c.restore();
    c.drawRRect(
        rr.deflate(g.unit * 0.008),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = (g.unit * 0.0015).clamp(0.5, 1.0)
          ..color = const ui.Color(0x33000000));
  }
}
