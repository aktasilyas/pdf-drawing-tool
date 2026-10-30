# 509 - Page thumbnails share one PDF document

Issue: #509. Goal: sidebar thumbnails of a long PDF open the file once and
decode the PDF at the cell size; export output unchanged.

**Reference check:** GoodNotes, StarNote and Flexcil scroll the thumbnail grid
of large PDFs smoothly → thumbnails must be cheap; we keep the document open
while the editor is open and render at the thumbnail size.

## Steps
1. `services/pdf_document_pool.dart`: `PdfDocumentPool` keeps up to `maxOpen`
   (2) documents open per resolved path (LRU), serialises renders per document
   (the native renderer allows one open page per document), `close()` waits for
   running renders. Injectable `PdfDocumentOpener`; default backed by pdfx.
   The export's open-render-close path moves here as `renderPdfPageAtScale`.
2. `PageRasterizer`: optional `pdfDocuments`. With it, the PDF background is
   rendered at the page's size in the output image (ceil, 1..2048 px) through
   the pool; without it (PNG/PDF export) nothing changes.
3. `ThumbnailGenerator.generate(pdfDocuments:)`; without a pool it uses a
   one-shot pool, so thumbnails always decode at thumbnail size.
4. `pdfThumbnailDocumentsProvider` (autoDispose, closes the pool on dispose);
   `DrawingScreen` watches it so it lives exactly as long as the editor;
   `PageThumbnail` passes it for PDF pages.
5. Tests: pool unit tests with a fake opener (open once, LRU close,
   serialisation, close, missing file, errors); thumbnail tests (open once for
   N pages, requested render size, provider dispose closes documents).

`PdfRenderSlots` was considered: it gates page/zoom renders by key and does not
hold documents, so thumbnails use the pool's per-document serialisation.
