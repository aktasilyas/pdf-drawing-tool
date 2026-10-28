# Plan: #384 Image pages reference stored files instead of inline bytes

Branch `claude/384-image-file-refs`. Size M. No UX change apart from one new error string.

## Problem
Image pages are `BackgroundType.pdf` with `pdfData` (PNG/JPEG bytes) and no `pdfFilePath`.
`PageBackground.toJson` writes them as `pdfDataBase64`, so every autosave re-encodes megabytes.
Insert paths leave an unused copy in `elyanotes_images/` (add-page panel, in-editor import) or make
no copy (library import). Permanent delete only cleans `pdfFilePath` files. `_addImagePage` throws on
decode failure and never disposes `frame.image`.

## Acceptance
- AC1: new image page stores `imageFilePath: "elyanotes_images/<ts>.<ext>"` (container-relative via
  `PdfPathResolver.toStored`) and no `pdfDataBase64`. Legacy `pdfDataBase64`-only JSON still decodes and round-trips.
- AC2: each insert path writes exactly one file and the page references it; decode failure / too large writes none.
- AC3: permanent delete, empty trash, retention purge and trash-page removal delete an `elyanotes_images`
  file only when no document content row and no trashed page mentions its stored path (covers
  `imageFilePath` and `ImageElement.filePath`).
- AC4: decode failure shows a localized snackbar, the panel closes, nothing throws; codec and image disposed.
- AC5: opening a document, library thumbnail and trash thumbnail still show the image (bytes loaded from file).

## Design
- **Model.** `PageBackground` gains `String? imageFilePath` (keeps `type: pdf`, `pdfPageIndex: 1`).
  `pdfData` becomes a runtime cache for image pages and is not serialized next to `imageFilePath`.
  JSON read precedence: `pdfFilePath` → `imageFilePath` → `pdfDataBase64`. No migration of legacy docs.
- **Helper (drawing_ui)** `importImagePage(sourcePath, documentsRoot:, paths:, maxDimension:)`:
  read bytes → decode size (dispose in `finally`) → throw `ImagePageImportException(unreadable|tooLarge)`
  → only then `storeImportedImage` → return background with `imageFilePath` + `pdfData`.
  Single hook for #383's downscale.
- **Load (data layer).** `loadImageBackgrounds` fills `pdfData` from `imageFilePath` after decode in
  `getDrawingDocument` / `getFirstPageBackground`; missing file → logged, stays null (placeholder).
  `PageRasterizer` falls back to reading the file when `pdfData` is null.
- **Cleanup.** `managedFilePathsOfPage(Map page)` collects `pdfFilePath`, `imageFilePath` and
  `layers[*].images[*].filePath`; the existing `contains(json.encode(path))` reference probe against
  `documentContents` and `trashedPages` decides deletion (`deleteUnreferencedPdfs` → `deleteUnreferencedFiles`).

## Steps
1. Model field + JSON split into `page_background_json.dart` (drawing_core) + tests.
2. `image_page_import.dart` helper, rasterizer fallback, `ErrorStrings.imageReadFailed` (tr/en) + tests.
3. Editor insert paths (`add_page_panel.dart`, `add_page_import_helper.dart`) use the helper with snackbar.
4. Load hydration (`image_background_loader.dart`) + tests.
5. Cleanup generalisation (`managed_file_paths.dart`, `managed_file_cleanup.dart`, trash repo) + Drift tests.
6. Library import (`new_document_importers.dart`, `withData: false`, `maxDimension: 4096`).

## Left out
Orphans from image elements deleted inside the editor, cancelled image placement, pages deleted without
trash (follow-up periodic sweep). Loading straight from file in renderers (memory) is #383/follow-up.

## Reference check
- GoodNotes: document package keeps imported images/PDFs as separate attachments referenced by id.
- Flexcil: `.flex` packages bundle PDF/image resources next to annotation data.
- StarNote: no public format docs found.
- We: same pattern — binaries as separate files referenced from the page model and freed with the
  document. Files are shared across documents and freed by reference check (reuses #370's PDF mechanism).
