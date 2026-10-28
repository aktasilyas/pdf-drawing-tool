# Plan: #370 — container-relative image paths

## Problem
Inserted images store an absolute path under `<docs>/elyanotes_images/`. After a backup
restore or device transfer the documents root changes and every image shows a placeholder.
PDF backgrounds already solved this with `PdfPathResolver` (#209); images bypass it.

## Acceptance
- AC1: an image inserted via the image panel stores `elyanotes_images/<name>`.
- AC2: canvas, PNG export, thumbnails, PDF export (vector and raster path) and selection
  capture load images through the resolver; tests use a *different* documents root.
- AC3: a legacy absolute path (`/data/user/0/old.pkg/app_flutter/elyanotes_images/a.png`)
  re-roots to `<newRoot>/elyanotes_images/a.png`; JSON with such a path round-trips unchanged.
- AC4: `drawing_core` stays Flutter-free; barrel imports; every touched file ≤ 300 lines.

## Findings that shape the design
- Every image *read* goes through `ImageCacheManager.loadImage(path)`
  (`drawing_ui/lib/src/canvas/image_painter.dart`) except one: `PdfContentPainter._paintImage`
  (`File(img.filePath)`, vector PDF export). Selection capture reuses the canvas cache.
- Only `image_panel.dart` persists an image path (via `imagePlacementProvider` →
  `placement_gestures.dart` → `ImageElement.filePath`). `add_page_import_helper.dart`
  `_importImage` and `add_page_panel.dart` `_addImagePage` copy into `elyanotes_images/` but
  store `pdfData: bytes`, never the path — no change needed for this issue (see Left out).
- `PdfPathResolver` is already plumbed (`pdfPaths`) into PageRasterizer, PagePngExporter,
  ThumbnailGenerator, PDFExporter, BackgroundThumbnailQueue and overridden in example_app
  (`core/di/injection.dart`, `core/bootstrap/app_overrides.dart`). Reusing that instance means
  zero example_app changes.

## Design
1. `drawing_core` — generalise `PdfPathResolver` (keep the name; renaming ~40 call sites is
   churn with no behaviour gain):
   - `static const imagesDir = 'elyanotes_images';`
   - `static const managedDirs = {pdfDir, imagesDir};` (private set is fine)
   - `toStored(abs)`: `<dir>/<name>` when abs is directly under `<root>/<dir>/` for any
     managed dir; otherwise unchanged.
   - `resolve(stored)`: relative → `<root>/<stored>` (unchanged); absolute whose parent
     segment is a managed dir → `<root>/<dir>/<name>`; else unchanged.
   - Update class doc ("PDFs and inserted images"). `pdfPathResolverProvider` doc likewise.
2. `ImageCacheManager({PdfPathResolver paths = PdfPathResolver.passthrough})`, public
   `final PdfPathResolver paths`. Cache key stays the **stored** path (painters keep calling
   `get(element.filePath)` unchanged); `loadImage` opens `File(paths.resolve(stored))`.
   No allocation added to `paint()`; painters untouched.
3. Owners of an `ImageCacheManager` pass the resolver:
   - `canvas_fields.dart`: `late final ImageCacheManager _imageCacheManager =
     ImageCacheManager(paths: ref.read(pdfPathResolverProvider));` plus
     `@visibleForTesting ImageCacheManager get debugImageCacheManager`.
   - `secondary_canvas_view.dart`: same `late final` with `ref.read`.
   - `page_rasterizer.dart` `_render`: `ImageCacheManager(paths: pdfPaths)`.
   - `pdf_raster_layer_renderer.dart` `renderLayer(..., {PdfPathResolver paths = passthrough})`.
4. `pdf_content_painter.dart`: `paintLayerContent(..., {PdfPathResolver paths = passthrough})`
   → `_paintImage` opens `File(paths.resolve(img.filePath))`. `pdf_exporter.dart` `_renderLayer`
   passes its `pdfPaths` to both renderers.
5. `page_thumbnail.dart`: pass the provider resolver when the page has a PDF background **or**
   any layer has images (`_needsResolver(page)`), keeping the "no ProviderScope needed for
   plain pages" property.
6. Write side: new `drawing_ui/lib/src/services/image_import_storage.dart`
   `Future<String> storeImportedImage(String sourcePath, {required String documentsRoot,
   PdfPathResolver paths = PdfPathResolver.passthrough})` — copies into
   `<root>/elyanotes_images/<micros>.<ext>`, returns `paths.toStored(dest)`; deletes the
   copy if it throws mid-way. `image_panel.dart` calls it with
   `ref.read(pdfPathResolverProvider)` and passes the stored path to `selectImagePath`.
   Export from `services/services.dart`.
State ownership unchanged: resolver = Riverpod provider (host-overridden), caches = their
current owners. No DB/JSON migration: legacy paths are resolved on read.

## Test plan
- `drawing_core/test/models/pdf_path_resolver_test.dart` (extend): image toStored (direct
  child, nested → unchanged, outside root → unchanged), resolve relative image, legacy
  absolute re-root to new root, Windows `C:\...\elyanotes_images\a.png`, passthrough, PDF
  cases still green.
- `drawing_core/test/models/image_element_path_compat_test.dart` (new): fromJson/toJson
  round-trip of legacy absolute and relative `filePath`; resolver maps legacy → new root.
- `drawing_ui/test/canvas/image_cache_manager_test.dart` (new, `tester.runAsync`, temp dir,
  1×1 PNG from `PictureRecorder`): relative + legacy-absolute keys load under resolver root;
  passthrough + relative → `get` null; key is the stored string.
- `drawing_ui/test/services/page_rasterizer_image_paths_test.dart` (new): page with a red
  image at a relative path, resolver = temp root → pixel at image centre is red;
  same via `PagePngExporter` status call (covers PNG export + thumbnails).
- `drawing_ui/test/services/pdf_exporter_image_paths_test.dart` (new): vector layer (image
  only) and raster layer (image + text) with legacy absolute path → output contains an
  image XObject (`/Subtype /Image`) / raster render non-blank at image; passthrough → absent.
- `drawing_ui/test/services/selection_capture_service_test.dart` (extend): cache built with
  resolver + relative image → captured PNG contains the image colour.
- `drawing_ui/test/canvas/drawing_canvas_test.dart` (extend): override
  `pdfPathResolverProvider` with `PdfPathResolver('/new/root')` → `debugImageCacheManager
  .paths.documentsRoot == '/new/root'`.
- `drawing_ui/test/services/image_import_storage_test.dart` (new): returns
  `elyanotes_images/<n>.png`, file exists under root; passthrough → absolute path.

## Steps (one implementer run each; test first)
1. Resolver generalisation — files: `pdf_path_resolver.dart`, its test.
   Verify: `cd packages/drawing_core && dart test test/models/pdf_path_resolver_test.dart`
2. JSON compat test (test-only) — Verify: `dart test test/models/image_element_path_compat_test.dart`
3. `ImageCacheManager(paths:)` — files: `image_painter.dart`, new cache test.
   Verify: `cd packages/drawing_ui && flutter test test/canvas/image_cache_manager_test.dart`
4. Rasterizer/PNG/thumbnail — files: `page_rasterizer.dart`, `page_thumbnail.dart`, new test.
   Verify: `flutter test test/services/page_rasterizer_image_paths_test.dart test/services/page_png_exporter_test.dart`
5. PDF export — files: `pdf_raster_layer_renderer.dart`, `pdf_content_painter.dart`,
   `pdf_exporter.dart`, new test. Verify: `flutter test test/services/pdf_exporter_image_paths_test.dart test/services/pdf_exporter_test.dart test/services/pdf_raster_layer_renderer_test.dart`
6. Canvas + selection capture wiring — files: `canvas_fields.dart`,
   `secondary_canvas_view.dart`, tests in step-3/plan list.
   Verify: `flutter test test/canvas/drawing_canvas_test.dart test/services/selection_capture_service_test.dart`
7. Write side — files: new `image_import_storage.dart`, `services.dart`, `image_panel.dart`, test.
   Verify: `flutter test test/services/image_import_storage_test.dart`
8. Full gate: `./scripts/check.sh analyze && ./scripts/check.sh test drawing_core && ./scripts/check.sh test drawing_ui`

## Risks
- `ref.read` in a `late final` field initialiser: first access must be after `initState`
  (true for build/paint). Disposal stays in existing `dispose()`.
- Resolver is read once per canvas; it is set at bootstrap and never changes.
- Reusing `pdfPaths` naming for images is slightly misleading; mitigated by docs. A rename
  to a neutral name can be a separate refactor.
- `pdf_content_painter.dart` is 269 lines; keep the change to a parameter + one line.

## Left out (YAGNI)
- Deleting unreferenced image files on permanent delete (follow-up named in the issue).
- The orphan copies made by `_importImage` / `_addImagePage` (they persist `pdfData` bytes,
  not the path); suggest a follow-up: read the picked file directly, skip the copy.
- DB rewrite of legacy absolute paths; missing-image UI state; renaming `PdfPathResolver`.

## Reference check
Issue marks it "no UX change, not needed"; the storage decision follows #209's check:
GoodNotes, StarNote and Flexcil keep attachments inside the app container/document package
and reference them relative to it, so content survives restore/transfer → same here.
