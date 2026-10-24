import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/painters/cover/cover_textures.dart';

/// Paints the procedural "material" cover family.
///
/// Rendering is synchronous and asset-free so it can be shared by the
/// preview widget, the editor cover page and the thumbnail generator.
class CoverRenderer {
  CoverRenderer._();

  /// Widths below this use the low-detail texture LOD.
  static const double detailThreshold = 200;

  static final Map<String, ui.Picture> _cache = {};
  static final ui.Paint _base = ui.Paint();
  static final ui.Paint _hinge = ui.Paint();
  static final ui.Paint _edgeHighlight = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const ui.Color(0x26FFFFFF);
  static final ui.Paint _plateFill = ui.Paint();
  static final ui.Paint _plateEdge = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const ui.Color(0x33000000);
  static final ui.Paint _plateShadow = ui.Paint()
    ..color = const ui.Color(0x26FFFFFF)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1;

  /// Label plate rect for a cover of [size]: upper third, 64% wide, 3:1.
  static ui.Rect labelPlateRect(ui.Size size) {
    final w = size.width * 0.64;
    final h = w / 3;
    return ui.Rect.fromLTWH((size.width - w) / 2, size.height * 0.14, w, h);
  }

  /// Draws [cover] into [size] on [canvas]. Draws a blank label plate.
  static void paint(ui.Canvas canvas, ui.Size size, Cover cover) {
    final rect = ui.Offset.zero & size;
    _base.color = ui.Color(cover.primaryColor);
    canvas.drawRect(rect, _base);

    final picture = _pictureFor(cover, size.width);
    canvas.save();
    canvas.clipRect(rect);
    canvas.scale(
        size.width / CoverTextures.width, size.height / CoverTextures.height);
    canvas.drawPicture(picture);
    canvas.restore();

    _paintHinge(canvas, size);
    _paintPlate(canvas, size);
  }

  /// Whether a repaint is needed between two covers.
  static bool needsRepaint(Cover a, Cover b) => a.id != b.id;

  static ui.Picture _pictureFor(Cover cover, double width) {
    final detailed = width >= detailThreshold;
    return _cache.putIfAbsent('${cover.id}:${detailed ? 'hi' : 'lo'}',
        () => CoverTextures.build(cover, detailed: detailed));
  }

  static double _hingeShaderWidth = -1;

  static void _paintHinge(ui.Canvas canvas, ui.Size size) {
    final hingeW = size.width * 0.08;
    if (hingeW != _hingeShaderWidth) {
      // Rebuilt only when the hinge width changes, never per paint.
      _hingeShaderWidth = hingeW;
      _hinge.shader = ui.Gradient.linear(
        ui.Offset.zero,
        ui.Offset(hingeW, 0),
        const [
          ui.Color(0x30000000),
          ui.Color(0x16000000),
          ui.Color(0x00000000),
        ],
        const [0.0, 0.5, 1.0],
      );
    }
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, hingeW, size.height), _hinge);
    // 1 device-px inner highlight keeps the cover edge visible on dark UI.
    canvas.drawRect((ui.Offset.zero & size).deflate(0.5), _edgeHighlight);
  }

  static void _paintPlate(ui.Canvas canvas, ui.Size size) {
    final rect = labelPlateRect(size);
    final rrect = ui.RRect.fromRectAndRadius(
        rect, ui.Radius.circular(size.width * 0.01 + 1));
    _plateFill.color = const ui.Color(CoverFamily.labelPlateColor);
    canvas.drawRRect(rrect, _plateFill);
    canvas.drawRRect(rrect, _plateEdge);
    canvas.drawRRect(rrect.deflate(1), _plateShadow);
  }
}
