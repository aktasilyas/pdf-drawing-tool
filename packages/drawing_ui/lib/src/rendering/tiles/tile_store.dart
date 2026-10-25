import 'dart:ui' as ui;

import 'package:drawing_ui/src/rendering/tiles/cached_tile.dart';
import 'package:drawing_ui/src/rendering/tiles/tile_grid.dart';

/// Tiles of one grid scale: rasterized images plus keys known to be empty.
/// Owns the images and disposes them on [drop], [clear] and eviction.
class TileStore {
  final Map<TileKey, CachedTile> tiles = {};

  /// Visible tiles that were rasterized but hold no content.
  final Set<TileKey> empty = {};

  /// Visible tiles drawn as vectors because they hold non-normal blend
  /// elements (a transparent tile cannot multiply against the page).
  final Set<TileKey> vector = {};

  bool has(TileKey key) =>
      tiles.containsKey(key) || empty.contains(key) || vector.contains(key);

  /// Bytes held by tile images.
  int get bytes => tiles.values.fold(0, (sum, t) => sum + t.bytes);

  void drop(TileKey key) {
    tiles.remove(key)?.image.dispose();
    empty.remove(key);
    vector.remove(key);
  }

  /// Drops every tile of [grid] that intersects one of [rects].
  void dropIn(TileGrid grid, Iterable<ui.Rect> rects) {
    for (final rect in rects) {
      grid.keysIn(rect).forEach(drop);
    }
  }

  void clear() {
    for (final t in tiles.values) {
      t.image.dispose();
    }
    tiles.clear();
    empty.clear();
    vector.clear();
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
    vector.clear();
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
