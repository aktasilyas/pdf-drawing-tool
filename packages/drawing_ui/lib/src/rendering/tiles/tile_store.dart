import 'dart:ui' as ui;

import 'package:drawing_ui/src/rendering/tiles/cached_tile.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_grid.dart';

/// Tiles of one grid scale: rasterized images plus keys known to be empty.
/// Owns the images and disposes them on [drop], [clear] and eviction.
class TileStore {
  final Map<TileKey, CachedTile> tiles = {};

  /// Visible tiles that were rasterized but hold no content.
  final Set<TileKey> empty = {};

  bool has(TileKey key) => tiles.containsKey(key) || empty.contains(key);

  /// Bytes held by tile images.
  int get bytes => tiles.values.fold(0, (sum, t) => sum + t.bytes);

  void drop(TileKey key) {
    tiles.remove(key)?.image.dispose();
    empty.remove(key);
  }

  void clear() {
    for (final t in tiles.values) {
      t.image.dispose();
    }
    tiles.clear();
    empty.clear();
  }

  /// Removes all tiles without disposing those overlapping [keepIn]; returns
  /// the kept ones (the caller takes ownership). The rest are disposed.
  List<CachedTile> takeOverlapping(ui.Rect keepIn) {
    final keep = <CachedTile>[];
    for (final t in tiles.values) {
      if (t.rect.overlaps(keepIn)) {
        keep.add(t);
      } else {
        t.image.dispose();
      }
    }
    tiles.clear();
    empty.clear();
    return keep;
  }

  /// Drops least recently used tiles outside [visible] until within
  /// [budgetBytes].
  void evict(Set<TileKey> visible, int budgetBytes) {
    var total = bytes;
    if (total <= budgetBytes) return;
    final candidates = [
      for (final t in tiles.values)
        if (!visible.contains(t.key)) t,
    ]..sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
    for (final t in candidates) {
      if (total <= budgetBytes) break;
      total -= t.bytes;
      drop(t.key);
    }
  }
}
