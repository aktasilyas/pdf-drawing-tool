# Plan #454 — PDF export at the notebook's paper size

Notebook pages are 1024 units tall with the paper's aspect ratio
(`load_document_usecase.dart`), and `PDFExporter` treated page units as PDF
points, so an A4 notebook exported at ~255×361 mm. Architect decision: no
migration of stored units; scale at export.

## Design
- `PDFPageFormat.millimeters(w, h)` (× 72/25.4). `PDFExportOptions.pageFormat`
  (existing, unused field) carries the paper size in points.
- `pdf_export_page_geometry.dart`: `pdfPageGeometry(page, options)` returns
  media box, content area, origin and scale.
  - Infinite canvas: today's content bounds, scale 1.
  - Paper page (no PDF background, not `PageBackground.isImage`) with a
    `pageFormat`: `s = paper.width / page.width`, media `paper.width × page.height·s`.
    Height follows the page (equal to the paper height within 0.1 pt for pages
    created from the paper) so a page of another shape is never clipped; the
    transform stays a pure scale.
  - Otherwise: page units are points (unchanged).
- `PDFExporter._exportPage`: one `q s 0 0 s 0 0 cm … Q` around background,
  PDF background and layers; the watermark is drawn after it at media size.
  `_decodeToRawRgba` moved to `pdf_compressed_image.dart` (file ≤ 300 lines).
- Plumbing: `exportPageFormatProvider` (`StateProvider<PDFPageFormat?>`,
  drawing_ui, default null). `pdfExportRunnerProvider` passes it to
  `PDFExportRunner.pageFormat`; `performPDFExport` / `performPagesPDFExport`
  take `pageFormat`; document and page option menus read the provider.
- example_app: `loadExportPaperFormat(read, documentId)` clears the provider,
  reads `DocumentInfo.paperWidthMm/HeightMm` (already orientation-applied) and
  sets it if the same document is still open. The editor screen calls it after
  `startEditorSession`. (Clearing at load instead of in the leave teardown
  keeps this PR clear of #444's `closeEditorSession` change.)

Not changed: PNG export, page rasterizer, painters, stored data.

## Tests
- drawing_ui `pdf_exporter_paper_size_test.dart`: A4 → 595×842 and content
  scaled by 595.28/724; A5 → 420×595; landscape → 842×595; PDF-backed page in
  the same export keeps 600×800; image page and no-paper export keep page
  units; infinite canvas ignores the paper.
- `pdf_test_text.dart`: PDF text helpers shared with the infinite-canvas test.
- `export_panel_scope_test.dart`: `pageFormat` reaches the exporter options;
  the runner provider takes it from `exportPageFormatProvider`.
- example_app `editor_paper_format_test.dart`: A5, landscape, stale id, failure.

## Reference check
GoodNotes, Flexcil and StarNote export notebook pages at the paper size chosen
for the notebook; imported PDF pages keep their own size. → Same here. Only
internal deviation: page units are not points, so we scale at export.
