import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:drawing_ui/src/rendering/tiles/cached_tile.dart';
import 'package:drawing_ui/src/rendering/tiles/page_tile_cache.dart';

/// Draws the committed content of a page from a [PageTileCache].
///
/// Paints in page space (the parent transform scales it). Ready tiles are
/// drawn as images. A tile that is not ready yet shows the old-scale images
/// clipped to its rect (never stacked), or vectors when there are none.
/// Multiply/screen tiles are image pairs drawn as `A` (multiply) then `K`
/// (plus) plus an optional normal overlay, so they blend with the page below. Overlay/darken/lighten tiles are
/// always vectors.
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

  /// Multiplies the page by a blend tile's `A` image, then adds its `K`.
  static final ui.Paint _multiplyPaint = ui.Paint()
    ..filterQuality = FilterQuality.medium
    ..blendMode = BlendMode.multiply;
  static final ui.Paint _plusPaint = ui.Paint()
    ..filterQuality = FilterQuality.medium
    ..blendMode = BlendMode.plus;

  /// Uses the tile's precomputed source rect: no allocation per frame.
  void _drawTile(Canvas canvas, CachedTile tile) {
    final multiply = tile.multiplyImage;
    if (multiply == null) {
      canvas.drawImageRect(tile.image, tile.src, tile.rect, _paint);
      return;
    }
    canvas
      ..drawImageRect(multiply, tile.src, tile.rect, _multiplyPaint)
      ..drawImageRect(tile.image, tile.src, tile.rect, _plusPaint);
    final overlay = tile.overlayImage;
    if (overlay != null) {
      canvas.drawImageRect(overlay, tile.src, tile.rect, _paint);
    }
  }

  @override
  bool shouldRepaint(TiledElementPainter oldDelegate) =>
      oldDelegate.cache != cache;
}
