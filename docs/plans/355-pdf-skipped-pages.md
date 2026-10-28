# Plan #355: report skipped PDF pages and missing PDF backgrounds

Issue: https://github.com/aktasilyas/pdf-drawing-tool/issues/355

## Problem
- Import: `buildLazyPdfPages` logs and drops unreadable pages; immediate mode drops
  `null` pages. A 10-page PDF can import as 7 pages with no warning.
- Export: `PageRasterizer._loadPdfBackground` swallows every error
  (`catch (_) => null`) and `PDFExporter._embedPdfBackground` returns early when the
  PDF background cannot be loaded. The page is exported without its PDF, silently.

## Design
- `PDFImportServiceResult.skippedPages` (`List<int>`, 1-based PDF page numbers,
  default `const []`). A list costs the same as a count and makes tests precise.
- `buildLazyPdfPages` / `convertPdfPagesImmediately` return
  `PdfPagesBuild = ({List<Page> pages, List<int> skippedPages})`.
- One message for both import paths: `DrawingStrings.errors.pdfPagesSkipped(count)`
  (ARB `editorErrorPdfPagesSkipped`). Library import replaces the "Opening…"
  SnackBar with the warning (queuing two would show the warning late, in the
  editor). The in-editor add-page import shows the same SnackBar.
- `PageRasterizer` logs a missing/unreadable PDF background with `DrawingLog.w`
  and reports it through a record: `renderPngWithStatus` →
  `PageRasterPng = ({Uint8List bytes, bool pdfBackgroundMissing})`. `render` /
  `renderPng` keep their signatures, so thumbnails only get the log.
- `PDFExportResult.missingBackgroundPages` (1-based positions in the exported list).
- `ExportProgressState.pagesMissingBackground` set by
  `ExportProgressNotifier.complete(size, pagesMissingBackground: n)`; the overlay
  shows a warning line and stays up longer. `start()` resets it.
- "Missing" = PDF background page with `pdfPageIndex != null` where nothing was drawn.
- Layer rules: nothing added to `drawing_core`; `drawing_ui` does not import `example_app`.

## l10n keys
| key | EN | TR |
|---|---|---|
| `editorErrorPdfPagesSkipped` | `{count, plural, =1{1 page could not be read and was skipped} other{{count} pages could not be read and were skipped}}` | `{count} sayfa okunamadı ve atlandı` |
| `editorExportPagesWithoutPdfBackground` | `{count, plural, =1{1 page was exported without its PDF background} other{{count} pages were exported without their PDF background}}` | `{count} sayfa PDF arka planı olmadan dışa aktarıldı` |

## Steps (test first in each)
1. Move the duplicated page-limit check out of `pdf_import_service.dart` (300-line cap).
2. AC1: skipped pages in `pdf_import_pages.dart`, `pdf_import_models.dart`,
   `pdf_import_service.dart`. Test: loader fake failing on pages 2 and 4 of 5.
3. Strings: `ErrorStrings.pdfPagesSkipped`, `ExportStrings.pagesWithoutPdfBackground`
   (TR defaults + `toMap`), ARB keys, `AppErrorStrings` / `AppExportStrings`.
4. AC2 library: `pdf_import_feedback.dart` helper used by `pdf_file_importer.dart`; widget test.
5. AC2 editor: `importPdfAsPages` in `add_page_import_helper.dart` with `onPagesSkipped`;
   SnackBar in the add-page panel; unit test.
6. AC3 rasterizer + PNG export: `page_rasterizer.dart`, `page_png_exporter.dart`,
   `png_export_action.dart`, `export_progress_provider.dart`; tests with a missing PDF path.
7. AC3 PDF export: `pdf_export_models.dart`, `pdf_exporter.dart`, `pdf_export_action.dart`.
8. AC3 overlay: completed body shows the warning; widget test.

## Left out
Thumbnail "missing" badge, listing page numbers in the UI, retries or placeholder
pages, turning a throwing `pdfData` decode in PDF export into a warning.

## Reference check
GoodNotes' help center treats unreadable imported pages as a source-file problem
and its forum has reports of users discovering empty pages only after import;
StarNote and Flexcil document nothing on partial import failures. No converged
pattern → follow the platform norm for a recoverable partial success: finish the
import and show one non-blocking toast with the count; same for export warnings.
