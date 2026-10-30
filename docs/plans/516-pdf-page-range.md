# Plan #516: a PDF over 500 pages offers a page range instead of a dead-end error

## Problem and acceptance criteria
A PDF with more than `PDFImportService.maxPageCount` (500) pages fails with a SnackBar on
every entry point: library import, Open with/Share (both go through `importPdfFile`), and
Add page → PDF. The user must be able to import part of it. Done when:
- AC1: if the service reports 640 pages, the default option re-imports with
  `PDFImportConfig.pageRange(startPage: 1, endPage: 500)`.
- AC2: the range sheet rejects start < 1, start > end, end > page count, and ranges longer
  than 500. In each case Import is disabled and an error is shown. Targets are ≥48dp and
  labelled.
- AC3: Cancel creates no document and leaves no stored copy of the PDF.
- AC4: Add page → PDF with a 640-page PDF inserts the chosen range at the insertion index.
- AC5: a PDF with 500 pages or fewer imports exactly as it does today, with no sheet and one
  service call.
- AC6: light and dark goldens of the sheet, reviewed per `design-loop`.

## Design decision: import first, then re-import (not count first)
The issue suggests reading the count with `PdfxPageCounter`. We keep the caller's design
instead:
- `PdfxPageCounter` lives in `example_app/.../data`. Add page lives in `drawing_ui` and cannot
  import it (layer rule). Counting first would need a second counter in `drawing_ui`.
- `_importLazily` already returns `PdfImportFailure(tooManyPages, pageCount: total,
  maxPages: 500)` (`pageNumbers.length` equals the total for `all()`), and
  `storePdfAndImport` deletes the stored copy on that failure. So the cancel path already
  leaves no file behind.
- Count-first opens the document twice on every import, including the common ≤500-page
  case. Re-import only costs extra on the rare >500-page file: one more copy (≤200 MB,
  capped by the size check) and one more open. With re-import, AC5 is unchanged by design.
- AC1 says "fake counter". We prove it with a fake import function that returns
  `tooManyPages(640)`. That is the same contract with a different seam.
- Use a fresh `PDFImportService` for each attempt. Do not reuse the service: its state stays
  `loadingPDF` after the tooManyPages return, which works today but only by accident.

## Types (all in drawing_ui, exported from `lib/drawing_ui.dart`)
- `services/pdf_page_range.dart` (pure Dart, no Flutter):
  - `class PdfPageRange { final int start, end; }` is immutable, with `==`/`hashCode` and
    `toConfig()` returning `PDFImportConfig.pageRange(...)`.
  - `enum PdfPageRangeError { startBelowOne, startAfterEnd, endAfterTotal, tooLong }`
  - `PdfPageRangeError? validatePdfPageRange(int start, int end, {required int total, int max = PDFImportService.maxPageCount})`
- `typedef ChoosePdfPageRange = Future<PdfPageRange?> Function(int pageCount, int maxPages);`
- `services/pdf_import_with_limit.dart`:
  `Future<PDFImportServiceResult?> importPdfWithPageLimit({required Future<PDFImportServiceResult> Function(PDFImportConfig) importWith, ChoosePdfPageRange? chooseRange})`.
  - It calls `importWith(all())`.
  - If the result is not `tooManyPages`, or `chooseRange` is null, it returns that result
    (today's behaviour).
  - Otherwise it awaits `chooseRange(pageCount, maxPages)`. `null` means cancel, and the
    function returns `null`. A range is re-imported with `importWith(range.toConfig())`.
  - Both entry points use this one orchestrator.
- `widgets/pdf_page_range_sheet.dart`:
  - `showPdfPageRangeSheet(BuildContext, {required int pageCount, required int maxPages})`
    returns `Future<PdfPageRange?>`.
  - Content: a title ("This PDF has N pages") and a hint about the 500-page limit.
  - Primary `FilledButton` "Import pages 1–500" (key `pdf-range-first`).
  - Secondary "Choose range" (key `pdf-range-choose`) shows two numeric fields (keys
    `pdf-range-start`, `pdf-range-end`), prefilled 1 and 500. Validation runs live; the
    error text appears under the fields and Import (key `pdf-range-import`) is disabled.
  - Cancel (key `pdf-range-cancel`) or dismissing the sheet returns `null`.
  - The widget has no logic: validation calls the pure function. Field styling follows
    `export_options_section.dart`. Colours come from the theme, spacing from `AppSpacing`,
    targets are ≥48dp, keys are used for robots.
  - If the file grows past ~300 lines, split it into `pdf_page_range_fields.dart`.
- Strings: add 9 abstract members to `PageStrings` (`l10n/page_strings.dart`, 183 lines)
  with TR in `PageStringsTr` and entries in `toMap()`. Members: `pdfRangeTitle(count)`,
  `pdfRangeLimitHint(max)`, `pdfRangeImportFirst(max)`, `pdfRangeChoose`, `pdfRangeStart`,
  `pdfRangeEnd`, `pdfRangeImport`, `pdfRangeCancel`, `pdfRangeError(PdfPageRangeError, total, max)`.
  The last one is a switch in a helper so it stays a single member. In example_app,
  `AppPageStrings` maps them to new `app_en.arb`/`app_tr.arb` keys `editorPdfRange*`.

## How each entry point gets a context
- Library and Open-with: `importPdfFile(context, …)` gets two optional parameters,
  `PDFImportService Function()? createService` and `ChoosePdfPageRange? chooseRange`
  (default: `showPdfPageRangeSheet(context, …)`). Close the loading dialog before the sheet
  and reopen it for the re-import; move the dialog into `pdf_import_loading_dialog.dart`
  (the file is 179 lines and will grow). If `!context.mounted` after the first import,
  treat it as a cancel.
- Add page (callback injection):
  - `PageFileImporter`, `pickAndImportFile`, `importPickedFile` and `importPdfAsPages` gain
    `ChoosePdfPageRange? chooseRange`. When it is null, the behaviour is today's error.
  - `AddPagePanel._handleImport` calls `widget.onClose()` before the import, which unmounts
    the panel's context. So capture `final navigator = Navigator.of(context, rootNavigator: true)`
    before `onClose`, and pass `chooseRange: (n, max) => showPdfPageRangeSheet(navigator.context, pageCount: n, maxPages: max)`.
  - `Navigator.of(navigatorContext)` resolves to the navigator itself. Theme, Localizations
    and `DrawingStringsScope` (main.dart `builder`) sit above the root navigator.
  - `withPickedFile` cleans up the picker copy after the sheet and the re-import finish.
- Layers: everything new lives in `drawing_ui`. Nothing in `drawing_core` changes, and
  example_app uses only the barrel. No rule is bent.

## Steps (one implementer run each)
1. Pure logic + orchestrator (TDD), for AC1, AC2-logic, AC3-file, AC5.
   - Files: `services/pdf_page_range.dart`, `services/pdf_import_with_limit.dart`, the barrel.
   - Tests: `test/services/pdf_page_range_test.dart` covers all four errors plus the
     boundaries (1–500 ok, 141–640 ok, 1–501 tooLong, 0, end 641).
   - Tests: `test/services/pdf_import_with_limit_test.dart` covers:
     - fake import returns `tooManyPages(640)` and choose returns `PdfPageRange(1,500)`:
       the second call gets `pageRange(1,500)` (AC1);
     - cancel returns null and makes one call (AC3);
     - a success makes one call and never calls choose (AC5);
     - null `chooseRange` returns the error (today's behaviour).
   - Tests: `pdf_import_service_test.dart` gets a case with a fake `PDFLoader` that has
     640 pages: tooManyPages and no file left in the pdf dir (AC3 copy).
   - Verify: `cd packages/drawing_ui && flutter test test/services/`
2. Strings, for AC2 labels.
   - Files: `l10n/page_strings.dart`, `app_en.arb`, `app_tr.arb`,
     `example_app/.../l10n/app_page_strings.dart`; run gen-l10n.
   - Tests: the existing `drawing_strings_test.dart` and `hardcoded_strings_guard_test.dart`,
     plus the example_app strings drift test.
   - Verify: `./scripts/check.sh analyze && ./scripts/check.sh test drawing_ui`
3. Sheet + widget test + goldens, for AC2 and AC6.
   - Files: `widgets/pdf_page_range_sheet.dart`, the barrel.
   - Test: `test/widgets/pdf_page_range_sheet_test.dart`:
     - "first" returns `PdfPageRange(1,500)`; Cancel returns null;
     - enter 10/5, 1/641 (count 640) and 1/600: Import is disabled and the matching error
       text is shown;
     - every action is at least 48×48 and has a semantics label.
   - Golden: `test/golden/pdf_page_range_sheet_golden_test.dart` uses `chromeTheme(brightness)`
     with scenarios `light`, `dark`, `light_range_invalid`, `dark_range_invalid` and
     `phone_light`. Render with the `update-goldens` workflow, then have `ui-designer`
     review the PNGs.
   - Verify: `flutter test test/widgets/pdf_page_range_sheet_test.dart test/golden/pdf_page_range_sheet_golden_test.dart`
4. Add page wiring, for AC4 and AC5.
   - Files: `panels/add_page_import_helper.dart` (thread `chooseRange` through and call
     `importPdfWithPageLimit` with `createService` for each attempt), `panels/add_page_panel.dart`
     (capture the navigator), and the fakes in `add_page_panel_import_test.dart` and
     `add_page_panel_page_size_test.dart` (new typedef parameter).
   - Tests: `add_page_import_helper_test.dart` uses a fake service that returns
     tooManyPages(640) on `all()` and 140 pages on `pageRange(501,640)`; with
     `insertIndex: 3` the pages get indexes 3..142 (AC4). A ≤500 PDF gives one call and no
     choose (AC5). `add_page_panel_import_test.dart` checks the panel passes a non-null
     `chooseRange`.
   - Verify: `flutter test test/panels/`
5. Library / Open-with wiring, for AC1-AC3 end to end and AC5.
   - Files: `pdf_file_importer.dart` (seams, orchestrator, reopen the dialog),
     a new `pdf_import_loading_dialog.dart`.
   - Tests: `pdf_file_importer_test.dart` (widget):
     - a fake service with 640 pages and choose returning first-500 creates a document with
       500 pages;
     - choose returning null means `createDocumentWithPages` is never called (fake
       `documentsControllerProvider`), no error SnackBar, and the loading dialog is closed;
     - a ≤500 PDF gives no sheet.
     The existing `incoming_pdf_listener_test.dart` must still pass.
   - Verify: `./scripts/check.sh analyze && cd example_app && flutter test test/features/documents/`;
     E2E runs in CI because the PR touches `example_app/lib`.

## Risks
- Peak disk use is two copies of up to 200 MB in a row, never at the same time: the first
  copy is deleted before the second is made.
- If the user leaves the screen while the sheet is open, the sheet is popped with the route
  and that counts as cancel.
- Add page: the root navigator context must sit under `DrawingStringsScope`. A widget test
  covers this so the TR fallback cannot slip through silently.
- Changing the typedef breaks custom `PageFileImporter` fakes. Fix them in step 4.

## Left out (YAGNI)
- No raising or configuring the 500 limit.
- No multi-range or "selected pages" picker; `PDFImportConfig.selectedPages` stays unused.
- No page thumbnails in the sheet.
- No E2E with a 640-page fixture: the fixture is too large for the repo, and the widget and
  unit tests cover the flow.

## Reference check
GoodNotes, StarNote and Flexcil import 1000+ page PDFs in one go. GoodNotes also lets the
user pick pages when importing into an existing notebook. All three converge on "never a
dead end". We keep the 500-page cap for v1.0 (memory and performance) and follow that
pattern: a one-tap default (first 500) plus a range choice. The same sheet serves the new
notebook and the add-page flow, the way GoodNotes uses page selection when inserting.
