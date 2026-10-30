# Plan: #520 Library tiles show first-page ink thumbnails

Branch `claude/520-library-ink-thumbnails`. No local SDK in the authoring
session: every step is verified in CI. No codegen (DI is registered by hand in
`example_app/lib/core/di/injection.dart`).

## Acceptance criteria (from the issue)
- AC1 page-0 ink visible on the tile after leaving the editor (golden).
- AC2 thumbnail width ≥ tile width × DPR (unit test).
- AC3 a tile with a thumbnail makes 0 content reads (mocktail).
- AC4 edits only on page 2+ do not rewrite the thumbnail.
- AC5 permanent delete removes the thumbnail file.
- AC6 analyze + tests green.

## Key facts
- Save: `AutoSaveNotifier._write` (`editor/presentation/providers/editor_provider.dart`)
  → `SaveDocumentUseCase` → `DocumentRepository.saveDocumentContent`. Autosave
  is debounced 3 s; leaving the editor flushes it and invalidates `autoSaveProvider`,
  so the thumbnail writer lives in its own provider and is read before the first await.
- Page 0 changed ⇔ `!identical(doc.pages.first, lastRendered)` (pages are
  immutable; `PageJsonCache` relies on the same identity rule).
- Rasterizer: `ThumbnailGenerator.generate(page, width:, height:, pdfPaths:)`
  (`drawing_ui/lib/src/services/thumbnail_generator.dart`) draws background + ink.
- `managedFileRefsIn` only recognises `pdfs/` and `elyanotes_images/`, so the
  thumbnail is stored as `elyanotes_images/thumb_<docId>_<micros>.png`
  (unique per write, so the image cache never shows a stale picture).
- `DocumentRepository.updateDocument` bumps `updatedAt` and resets the folder
  when `folderId` is null — not used. A new `saveThumbnail` writes the column
  via `guard` + datasource `getDocument`/`updateDocument(copyWith)`.
- `duplicateDocument` copies `thumbnailPath`, so deletes go through
  `deleteUnreferencedFiles`, whose `_isReferenced` also checks `documents.thumbnailPath`.

## Design
1. **Domain**: `DocumentRepository.saveThumbnail(String id, Uint8List png) → Either<Failure, String>`.
2. **Data**: mixin `DocumentThumbnails` (`documents/data/repositories/document_thumbnails.dart`)
   writes the file, updates the row in a transaction, deletes the previous file if
   unreferenced. `ManagedFileCleanup.pathsOfDocument` includes the row's thumbnail;
   `_isReferenced` counts `documents.thumbnailPath`.
3. **Writer**: `editor/presentation/providers/library_thumbnail_writer.dart`:
   `libraryThumbnailPixels` (240 dp × DPR 3 = 720 px wide), `LibraryThumbnailWriter`
   (`baseline`, `request`, coalescing, never throws), `libraryThumbnailWriterProvider`
   (disabled with the passthrough resolver; invalidates library lists on write).
4. **Hooks**: `startEditorSession` → `baseline(document)`; `_write` → `request(document)` after a successful save.
   The render waits for 20 s without new requests, or runs when the editor
   closes (`closeEditorSession` → `flush()`, not awaited), so drawing on
   page 0 does not re-render after every autosave (review finding). The
   writer remembers the first page of at most 8 documents.
5. **Tile**: `LibraryPageThumbnail` shows `_InkThumbnail` (ResizeImage at tile
   width × DPR, falls back to today's preview on error) when `thumbnailPath` is set.
   `libraryThumbnailImageProvider` resolves stored paths; tests override it.

## Steps
1. Data layer + tests (`document_thumbnails_test.dart`): file written, row
   updated without `updatedAt`/folder change, previous file deleted, shared
   file kept after duplicate, permanent delete removes the file, passthrough → Left.
2. Writer + hooks + tests (`library_thumbnail_writer_test.dart`, autosave test):
   page-2-only edit → no render (AC4), size ≥ tile × DPR for phone/tablet (AC2),
   cover skipped, null render not saved, coalescing.
3. Tile + tests (`library_ink_thumbnail_test.dart`: 0 content reads (AC3),
   fallback on bad bytes) + golden (`library_ink_thumbnail_golden_test.dart`, AC1).
4. Render goldens with the `update-goldens` workflow, review PNGs (design-loop).

## Follow-ups (out of scope)
- Backfill thumbnails for documents not edited since this change (they keep
  today's preview); thumbnail on import.
- Raise the 100–120 px PDF fallback render (`pdf_render_provider.dart`).
- Include thumbnails in backup/export.

## Reference check
GoodNotes, StarNote and Flexcil show the first page including handwriting as the
document thumbnail, and the cover when one is set → we do the same. Deviation:
documents not edited since this change keep the background preview until their
first page-0 edit (v1.0 scope, small PR).
