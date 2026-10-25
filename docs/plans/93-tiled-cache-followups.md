# #93 Tiled cache follow-ups

Follow-ups from the #44 review. Three independent tasks; shipped in two slices.

Reference check: not applicable (internal rendering performance; no product,
UX or format change).

## Slice 1 (this PR)

### Task 2: no allocation in `TiledElementPainter.paint()`
- `CachedTile` computes `src` (full-image source rect) once in its constructor.
- `TiledElementPainter._drawTile` draws `tile.image` from `tile.src` to
  `tile.rect` with the static paint, for visible and legacy tiles.

### Task 3: image load re-rasters only intersecting tiles
- `PageTileCache.invalidate(Iterable<Rect>)`: drops tiles of the current grid
  that intersect the rects (`TileStore.dropIn`, shared with the dirty path of
  `update`), releases legacy tiles, re-rasterizes visible ones.
- `ActiveLayerContentState` records the file paths of applied scene images that
  are not loaded yet (`_unloaded`, refreshed whenever a scene is applied). On an
  `ImageCacheManager` notification it invalidates only `imageBounds` of the
  images that loaded since. No cache rebuild, no `setState` (the painter
  repaints through the cache listenable).
- Test hook: `ImageCacheManager.debugPut` (`@visibleForTesting`).

Tests: `test/rendering/tiles/tile_invalidation_test.dart`.

## Slice 2 (next): cache multiply-blend tiles

Today tiles with non-normal blend strokes stay vectors. Proposed design (exact
for any z-order of normal and multiply/screen elements):

- Over an opaque destination `B`, every op the renderer emits is affine per
  channel: src-over `X -> (1-a)X + c`, multiply `X -> X(1 - Sa + Sc)`, screen
  `X -> X(1 - S) + S`, AA coverage lerps. A composition of affine maps is
  affine, so a tile's result is `A*B + K` per channel.
- Store two images per blend tile: `K` = tile content rendered over black,
  `A` = (content over white) minus `K` (draw `K` with `BlendMode.difference`
  onto the white render).
- Paint: `A` with `BlendMode.multiply`, then `K` with `BlendMode.plus`.
- Pen-up composite stays incremental: new `K` = ops over old `K`; new white
  render = ops over (`A` plus `K`).
- Overlay, darken, lighten are not affine: those tiles stay vectors.
- `page_tile_cache.dart` is at the size limit; move tile building
  (`_rasterizeTile`, `_composite`) into a `TileBuilder` in the same slice.
- The existing golden `tiled_layer_reference.png` covers a multiply
  highlighter, so it must be regenerated; this needs a session with a working
  Flutter SDK.
- The pen-up benchmark already uses 25% highlighter strokes (most tiles are
  vectors today); it should draw blend tiles the same way as the painter.
