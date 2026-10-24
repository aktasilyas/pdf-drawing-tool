import 'dart:ui' as ui;

/// Records tile content and turns it into a [ui.Image] with `toImageSync`.
class TileRasterizer {
  const TileRasterizer({this.tilePixels = 512});

  /// Edge length of the produced image in device pixels.
  final int tilePixels;

  /// Rasterizes the page-space [pageRect] at [scale] (device px per page unit).
  ///
  /// When [base] is given it is drawn first at 1:1 (it must come from the same
  /// grid and scale), so [paint] only has to draw what changed on top.
  /// [paint] receives a canvas in page space, already clipped to [pageRect].
  ui.Image rasterize({
    required ui.Rect pageRect,
    required double scale,
    required void Function(ui.Canvas canvas) paint,
    ui.Image? base,
  }) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, tilePixels.toDouble(), tilePixels.toDouble()),
    );
    if (base != null) canvas.drawImage(base, ui.Offset.zero, ui.Paint());
    canvas
      ..save()
      ..scale(scale)
      ..translate(-pageRect.left, -pageRect.top)
      ..clipRect(pageRect);
    paint(canvas);
    canvas.restore();

    final picture = recorder.endRecording();
    final image = picture.toImageSync(tilePixels, tilePixels);
    picture.dispose();
    return image;
  }
}
