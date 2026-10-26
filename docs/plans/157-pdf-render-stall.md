# #157 PDF zoom re-render stall and oversized bitmaps

Issue: https://github.com/aktasilyas/pdf-drawing-tool/issues/157

## Design
1. **Concurrency gate** (`services/pdf_render_slots.dart`): `PdfRenderSlots`
   replaces the global `_currentlyRendering` set + counter. `acquire(key)`
   claims the key and waits (LIFO, no timeout) for a slot; `release(key)` in
   `finally` frees both, so no exit path leaks a key. A duplicate key is
   refused at once. Exposed as `pdfRenderSlotsProvider` (fresh per container,
   testable).
2. **Rasteriser seam** (`providers/pdf_page_cache.dart`): one
   `rasterizePdfPage(path, page, quality)` (pdfx) behind
   `pdfPageRasterizerProvider`, used by page and zoom renders. Cache providers
   and cache management move here unchanged.
3. **Size cap** (`PDFPageRenderer.renderSizeForDisplayQuality` /
   `capRenderSize`): longest side <= 4096 px, aspect kept. A4 at 2.5x goes from
   5950x8420 (~200 MB RGBA) to 2895x4096 (~47 MB).
4. **Zoom HQ** (`providers/pdf_zoom_render_provider.dart`): waits for a slot
   instead of dropping the request; stale-quality cleanup uses the exact
   `'$cacheKey@'` prefix (`staleQualityKeys`).
5. **Page provider**: `FutureProvider.autoDispose.family` + `keepAlive()`;
   the keep-alive link is closed on a `null` result, so failures are not
   cached and the next request renders again. No 3 s give-up any more.
6. `pdf_render_provider.dart` (561 lines) is split under the 300-line rule and
   re-exports the new files, so importers do not change.

## Tests
- `test/services/pdf_render_slots_test.dart`: limit, dedupe, LIFO wait, release.
- `test/services/pdf_page_renderer_test.dart`: size at 1.5/2.0/2.5x, cap, aspect.
- `test/providers/pdf_render_provider_test.dart`: saturate -> zoom -> free ->
  zoom again renders HQ; prefix cleanup; null not cached; 12 queued pages all
  render after saturation.
