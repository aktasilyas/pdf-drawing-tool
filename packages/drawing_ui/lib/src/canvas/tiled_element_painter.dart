import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:drawing_ui/src/rendering/tiles/cached_tile.dart';
import 'package:drawing_ui/src/rendering/tiles/page_tile_cache.dart';

/// Draws the committed content of a page from a [PageTileCache].
///
/// Paints in page space (the parent transform scales it). Ready tiles are
/// drawn as images. A tile that is not ready yet shows the old-scale images
/// clipped to its rect (never stacked), or vectors when there are none.
/// Tiles with non-normal blend content (multiply highlighter) are always
/// vectors so the blend sees the page below.
class TiledElementPainter extends CustomPainter {
  TiledElementPainter({required this.cache}) : super(repaint: cache);

  final PageTileCache cache;

  static final ui.Paint _paint = ui.Paint()
    ..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    for (final tile in cache.visibleTiles) {
      _drawTile(canvas, tile);
    }
    for (final rect in cache.vectorRects) {
      canvas
        ..save()
        ..clipRect(rect);
      cache.paintVectorRegion(canvas, rect);
      canvas.restore();
    }
    for (final rect in cache.pendingRects) {
      canvas
        ..save()
        ..clipRect(rect);
      var drewLegacy = false;
      for (final old in cache.legacyTiles) {
        if (!old.rect.overlaps(rect)) continue;
        _drawTile(canvas, old);
        drewLegacy = true;
      }
      if (!drewLegacy) cache.paintVectorRegion(canvas, rect);
      canvas.restore();
    }
  }

  /// Uses the tile's precomputed source rect: no allocation per frame.
  void _drawTile(Canvas canvas, CachedTile tile) {
    canvas.drawImageRect(tile.image, tile.src, tile.rect, _paint);
  }

  @override
  bool shouldRepaint(TiledElementPainter oldDelegate) =>
      oldDelegate.cache != cache;
}
