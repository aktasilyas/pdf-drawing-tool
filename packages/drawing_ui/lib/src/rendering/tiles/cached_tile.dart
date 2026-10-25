import 'dart:ui' as ui;

import 'package:drawing_ui/src/rendering/tiles/tile_grid.dart';

/// A rasterized tile: [image] covers [rect] in page space.
///
/// A plain tile is drawn with src-over. A blend tile (multiply/screen content)
/// holds an opaque image pair: the page below is multiplied by
/// [multiplyImage] (`A`), then [image] (`K`) is added (`A*B + K`). Normal
/// content appended on top of a blend tile lands in [overlayImage] (src-over,
/// drawn last); a later blend append folds it back into the pair.
class CachedTile {
  CachedTile(
    this.key,
    this.rect,
    this.image, {
    this.multiplyImage,
    this.overlayImage,
  })  : bytes = image.width *
            image.height *
            4 *
            (1 +
                (multiplyImage == null ? 0 : 1) +
                (overlayImage == null ? 0 : 1)),
        src = ui.Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );

  final TileKey key;
  final ui.Rect rect;

  /// Tile content (plain tile) or the additive term `K` (blend tile).
  final ui.Image image;

  /// The multiplicative term `A` of a blend tile; null for a plain tile.
  final ui.Image? multiplyImage;

  /// Normal content drawn over a blend tile; null when there is none.
  final ui.Image? overlayImage;
  final int bytes;

  /// Source rect covering the whole [image], computed once so painters
  /// allocate nothing per frame.
  final ui.Rect src;

  /// Cache clock value of the last frame this tile was visible (LRU).
  int lastUsed = 0;

  bool get isBlend => multiplyImage != null;

  void dispose() => disposeExcept(null);

  /// Disposes the images that [next] does not reuse.
  void disposeExcept(CachedTile? next) {
    for (final i in [image, multiplyImage, overlayImage]) {
      if (i == null) continue;
      if (next != null &&
          (identical(i, next.image) ||
              identical(i, next.multiplyImage) ||
              identical(i, next.overlayImage))) {
        continue;
      }
      i.dispose();
    }
  }
}
