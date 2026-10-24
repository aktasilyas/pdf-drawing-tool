import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:drawing_ui/src/rendering/tiles/page_tile_cache.dart';

/// Draws the committed content of a page from a [PageTileCache].
///
/// Paints in page space (the parent transform scales it). Ready tiles are
/// drawn as images. A tile that is not ready yet shows the old-scale images
/// clipped to its rect (never stacked), or vectors when there are none.
class TiledElementPainter extends CustomPainter {
  TiledElementPainter({required this.cache}) : super(repaint: cache);

  final PageTileCache cache;

  static final ui.Paint _paint = ui.Paint()
    ..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    for (final tile in cache.visibleTiles) {
      _drawImage(canvas, tile.image, tile.rect);
    }
    for (final rect in cache.pendingRects) {
      canvas
        ..save()
        ..clipRect(rect);
      var drewLegacy = false;
      for (final old in cache.legacyTiles) {
        if (!old.rect.overlaps(rect)) continue;
        _drawImage(canvas, old.image, old.rect);
        drewLegacy = true;
      }
      if (!drewLegacy) cache.paintVectorRegion(canvas, rect);
      canvas.restore();
    }
  }

  void _drawImage(Canvas canvas, ui.Image image, Rect dst) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      _paint,
    );
  }

  @override
  bool shouldRepaint(TiledElementPainter oldDelegate) =>
      oldDelegate.cache != cache;
}
