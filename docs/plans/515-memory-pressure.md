# #515 — Release editor caches on memory pressure

**Reference check:** not user-visible. GoodNotes, StarNote and Flexcil resume
where the user left off after an app switch; freeing rebuildable caches when
Android asks makes that more likely for us too.

## Steps
1. `EditorMemoryPressureObserver` (drawing_ui/canvas): a `WidgetsBindingObserver`
   registered on construction, unregistered on `dispose()`; calls a callback on
   `didHaveMemoryPressure`.
2. `PageTileCache.trimToVisible()`: `TileStore.evict(visibleKeys, 0)`; evicted
   tiles are rebuilt by `_ensureVisible` on the next viewport/scene update.
3. `ImageCacheManager.trim()`: evicts every image not read through `get` within
   `protectWindow`; painters reload missing images on their next paint.
4. Owners hold one observer each (created in `initState`, disposed first in
   `dispose`): `DrawingCanvasState` (clears `clearPdfCacheProvider` + trims its
   image cache), `ActiveLayerContentState` (trims its tile cache — one per
   canvas, so dual-page mode is covered), `SecondaryCanvasView` (trims its
   image cache). No work in pointer handlers or `paint()`.
5. Tests: `drawing_ui/test/canvas/memory_pressure_test.dart`.
