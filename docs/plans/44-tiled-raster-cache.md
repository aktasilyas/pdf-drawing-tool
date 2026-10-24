# Plan: tiled raster cache for committed content (#44)

Milestone M1 Ink engine v2. Builds on #43 (live stroke geometry). Scope: `packages/drawing_ui` only.

## 1. Problem and acceptance criteria
The active layer's committed content is one `UnifiedElementPainter` (`drawing_canvas.dart` ~997-1038).
Any change (pen-up, undo, erase, eraser preview) re-records every stroke, shape, image and text as
vectors, so the cost is O(page). On a full page this causes a hitch at pen-up. Zoom re-tessellates
everything on every frame.

AC (checkable):
- A1 Committed content is drawn from per-page `ui.Image` tiles (fixed device-pixel size). The tile
  cache belongs to one (page, layer) and is disposed when the page changes.
- A2 Pen-up appends the stroke into the intersecting tiles only (composite old image + new stroke).
  Test hook: `debugLastRecordedElements <= 1` at pen-up, independent of page size (n = 10/100/1000).
- A3 Undo, stroke erase, pixel erase, selection move/transform and eraser previews re-rasterize only
  the tiles whose rect intersects the inflated bounds of the removed/changed/added elements. Other
  tiles keep the same `ui.Image` instance (identity test).
- A4 During a pinch the cached tiles are only scaled (no re-raster, `debugRasterCount` unchanged).
  About 120 ms after `isZoomingProvider` goes false, visible tiles are re-rasterized at
  `zoom * devicePixelRatio`, progressively within a per-frame budget. Until a new tile is ready, the
  old-scale images are drawn, clipped to that tile, never stacked.
- A5 Parity: after any sequence of add/undo/erase/zoom, the tiled render matches a fresh vector
  render of the same scene (<0.5% of pixels differ by more than 8/255) at scale 1 and 2.
- A6 Headless benchmark, 1,000-stroke page: no pen-up frame (cache update + `paint()` recorded +
  `toImageSync` handles) takes longer than 16 ms. Worst and p95 are reported next to the legacy
  full re-record.
- A7 `./scripts/check.sh analyze` and `test` pass. Every new or touched file is <= 300 lines.

## 2. Affected files (all in packages/drawing_ui)
- `lib/src/rendering/element_scene_renderer.dart` (new): ordered element painting pulled out of
  `UnifiedElementPainter` (stroke, shape, image, text, z-order, backward-compat ordering) plus
  `paintRegion(canvas, Rect cull)` with a bounding-box pre-filter.
- `lib/src/canvas/unified_element_painter.dart`: delegates to the renderer. This brings it under 300
  lines and changes no behaviour (passive layers and the secondary view keep using it).
- `lib/src/rendering/tiles/element_bounds.dart` (new): inflated page-space bounds per element (stroke
  bbox + thickness/2 + AA/glow margin, rotated image rect, text via a one-time paragraph layout
  cached in an `Expando`).
- `lib/src/rendering/tiles/element_scene.dart` (new): immutable `ElementScene` (lists, elementOrder,
  excluded ids, eraser previews) and `SceneDiff`.
- `lib/src/rendering/tiles/tile_grid.dart` (new): `TileKey`, tile rects for a scale, `keysIn(Rect)`.
- `lib/src/rendering/tiles/tile_rasterizer.dart` (new): record a tile to `toImageSync`, composite on top.
- `lib/src/rendering/tiles/page_tile_cache.dart` (new, ChangeNotifier): tiles, invalidation, eviction.
- `lib/src/rendering/tiles/tile_raster_scheduler.dart` (new): progressive re-raster after zoom.
- `lib/src/rendering/tiles/tiles.dart` (barrel), plus an export in `rendering/rendering.dart`.
- `lib/src/canvas/tiled_element_painter.dart` (new): draws tiles, with a vector fallback for missing tiles.
- `lib/src/canvas/element_preview_painter.dart` (new): activeShape/activeText previews (not cached).
- `lib/src/canvas/active_layer_content.dart` (new widget): owns the cache, debounces zoom settle.
- `lib/src/canvas/drawing_canvas.dart`: replace the active-layer committed block with
  `ActiveLayerContent` (the file gets smaller).
- Tests: `test/rendering/tiles/*_test.dart`, `test/canvas/active_layer_content_test.dart`,
  golden `test/golden/tiled_layer_reference.png`, a new section in `test/benchmark/ink_benchmark_test.dart`,
  and `scripts/ink_benchmark.sh`.

## 3. Design
### 3.1 Types
```dart
class ElementScene { strokes, shapes, images, texts, elementOrder, excludedIds,
  pixelEraserPreview, strokeEraserPreview; }            // built in drawing_canvas, immutable
class SceneDiff { List<String> appendedOnTop; List<Rect> dirty; bool full; }
SceneDiff diffScenes(ElementScene? prev, ElementScene next);   // O(n) id/identity compare
class TileKey { final int col, row; }                 // grid of 512x512 device px, scale-dependent
class PageTileCache extends ChangeNotifier {
  PageTileCache({required ElementSceneRenderer renderer, int budgetBytes = 64 << 20});
  void update(ElementScene scene);                    // diff -> composite or re-raster dirty
  void setViewport(Rect visiblePageRect, double targetScale, {required bool interacting});
  Iterable<CachedTile> get visibleTiles;              // precomputed; painter iterates only
  int get debugRasterCount; int get debugLastRecordedElements;
  @override void dispose();                           // disposes every ui.Image
}
```
### 3.2 Data flow and state ownership
`provider change -> DrawingCanvas.build -> ActiveLayerContent(scene, transform, viewport, dpr,
isZooming)`. In `didUpdateWidget` the state calls `cache.update(scene)` and `cache.setViewport(...)`,
which notify, and `TiledElementPainter(cache, repaint: cache)` repaints. `shouldRepaint` compares the
cache identity, never a constant `true`. The `State` owns the cache, keyed by `ValueKey(pageId/layerId)`,
so a page switch disposes it. There is no Riverpod state, because the cache is a render-side
resource, the same way the controller owns the geometry in #43.
- Diff rules: if only new ids form a suffix of the effective order, use the fast path and draw the new
  elements on top of each intersecting tile's image (record one image + k elements, then `toImageSync`).
  Removed, changed (non-identical object) or excluded-set changes add old and new bounds to `dirty`.
  A survivor reorder (bring to front) sets `full`. Image-cache loads (`cacheManager` notifies)
  dirty the bounds of all image elements.
- Visible dirty tiles are re-recorded synchronously in `update`, so undo never shows stale ink for a
  frame. Dirty tiles that are off-screen are evicted. LRU eviction is held to `budgetBytes`.
- Zoom: while `interacting`, tiles are drawn with `drawImageRect` into their page rect, and the parent
  `Transform` scales them (FilterQuality.medium). On settle, the grid is rebuilt at the exact
  `zoom*dpr` (capped at 8). The scheduler re-rasterizes visible tiles nearest-first, up to about 6 ms
  per frame (`SchedulerBinding.scheduleFrameCallback`). A missing new tile draws the old images
  clipped to its rect, or vectors via `paintRegion` if there are none (first open, pan into an
  uncached area).
- Previews (activeShape, activeText) move to `ElementPreviewPainter` above the tiles. Layer
  opacity stays in `_wrapOpacity`.
### 3.3 Rules
`drawing_core` is untouched. `paint()` draws only images and precomputed rects. The vector fallback
for missing tiles does allocate through the renderer. This bends the "no allocation in paint()" rule,
but only on a cold or uncached tile (today's behaviour, now bounded to one tile) and never in steady
state. `drawing_canvas.dart` only shrinks; a full split stays out of scope.

## 4. Test plan
- `element_bounds_test`: stroke inflation per pen/glow, rotated image, text bounds.
- `element_scene_diff_test`: append on top leads to the fast path; undo of the last stroke, erase in
  the middle, pixel-erase split (new ids not a suffix), move, excluded set on/off, reorder (`full`).
- `tile_grid_test`: `keysIn` at scale 1/2.6/8, tile rects cover the page with no gaps.
- `page_tile_cache_test` (real images, `toByteData`): A2 recorded count; A3 undo/erase identity and
  scope (`debugRasterizedKeys`); A5 parity vs vector after add/undo/stroke-erase/pixel-erase.
- `tile_raster_scheduler_test` (fake clock/frames): A4, with no raster while interacting, progressive
  re-raster after settle within budget, old images disposed, parity at the new scale.
- `active_layer_content_test` + golden `tiled_layer_reference.png`: pen, highlighter (multiply) and
  brush over a tinted background. Its pixel diff vs `UnifiedElementPainter` is within the A5 tolerance.
- Benchmark A6: 1,000-stroke page with tiles warmed, then 50 scripted pen-ups. Report worst/p95 for
  `tiled` and `legacy` and assert tiled worst < 16 ms. A2 is the deterministic, CI-safe guard.
- The existing `drawing_canvas_test`, `stroke_painter_test` and renderer goldens stay green.

## 5. Task breakdown (one implementer run each)
1. Extract `ElementSceneRenderer` (+ `paintRegion`) and `element_bounds.dart`. Verify with
   `cd packages/drawing_ui && flutter test test/canvas test/rendering`.
2. `ElementScene`, `SceneDiff`, `TileGrid` (pure geometry, TDD). Verify with
   `flutter test test/rendering/tiles`.
3. `TileRasterizer` + `PageTileCache` (update, fast path, dirty re-raster, eviction, dispose), with
   the A2/A3/A5 tests first. Verify with `flutter test test/rendering/tiles`.
   Steps 1-3 are a mergeable partial PR: no UI wiring, so behaviour is unchanged.
4. Zoom: `setViewport`, `TileRasterScheduler`, clipped old-scale fallback, `TiledElementPainter`.
   Verify with `flutter test test/rendering/tiles test/canvas`.
5. `ActiveLayerContent` + `ElementPreviewPainter`, wired into `drawing_canvas.dart`, plus the widget
   test and golden. Verify with `flutter test test/canvas test/golden && ./scripts/check.sh analyze`.
6. Benchmark section + `ink_benchmark.sh` greps. Record the numbers in the PR. Verify with
   `./scripts/ink_benchmark.sh && ./scripts/check.sh test`.

## 6. Risks and what is left out
- Multiply highlighter: inside a transparent tile, multiply against the paper/PDF becomes srcOver.
  Step 5's golden over a tinted background decides. If it differs from today's output, tiles holding
  non-normal blend elements fall back to `paintRegion` (vectors), and a follow-up issue is filed.
- Seams between tiles at fractional scales while pinching. At rest, scale is exactly `zoom*dpr` and
  tile rects are pixel-snapped. A small seam during the gesture is accepted.
- Memory: 64 MB budget (~64 tiles at 512^2 RGBA). The page at fit zoom fits. At 500% only the
  viewport (+1 ring) is kept.
- The raster thread rasterizes `toImageSync` work. Headless timing covers the UI thread. The
  composite path keeps raster work O(new stroke), but device numbers on a mid-range Android tablet
  should still be posted in the PR.
- Undo on a dense tile re-records about 100+ strokes. That is not covered by the 16 ms AC and is reported only.
- Left out (YAGNI): tiles for passive layers, the secondary/dual-page view, thumbnails and export
  (they keep `UnifiedElementPainter`); isolate/background rasterization; persisting tiles to disk;
  multi-level (mipmap) pyramids; caching sticky notes (they have their own painter).

## 7. Reference check
GoodNotes, StarNote and Flexcil publish no rendering internals. Visible behaviour converges: pen-up
does not hitch on full pages, and zooming in shows briefly soft ink that sharpens once the gesture
ends. GoodNotes users report exactly this blur-then-sharpen on zoom (feedback forum). All three keep
ink crisp at rest at any zoom level. We follow that pattern: scale cached tiles during the gesture,
then re-rasterize at the settled scale. The tile technique itself comes from map/PDF viewers and
the ink-engine skill. There is no user-visible deviation. Ink at rest stays as sharp as vector
rendering (A5).
