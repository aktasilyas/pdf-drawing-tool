import 'dart:ui' as ui;

import 'package:drawing_ui/src/rendering/tiles/tile_grid.dart';

/// A rasterized tile: [image] covers [rect] in page space.
class CachedTile {
  CachedTile(this.key, this.rect, this.image)
      : bytes = image.width * image.height * 4;

  final TileKey key;
  final ui.Rect rect;
  final ui.Image image;
  final int bytes;

  /// Cache clock value of the last frame this tile was visible (LRU).
  int lastUsed = 0;
}
