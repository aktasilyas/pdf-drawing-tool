# Plan #449: Re-link a missing source PDF

## 1. Problem and acceptance criteria
After an Android backup restore or a device move, a PDF notebook can come back
without its file in `<docs>/pdfs/`. Its pages then show "Source PDF not found"
for good. The user must be able to pick the PDF again and keep every annotation.
- AC1: The placeholder shows a "Locate PDF…" button (>=48dp, TR + EN) only when
  `pdfSourceMissingProvider(path)` is true and `pdfSourceRelinkProvider` is set.
- AC2: Use case unit tests: success installs at the stored path; fewer pages
  gives `pageCountMismatch` and nothing is written; an encrypted file gives
  `passwordProtected`; an existing target is never overwritten.
- AC3: Widget test: the button shows, tapping it calls the handler, and after
  success the placeholder is gone (fake rasterizer returns bytes).
- AC4: No file over ~300 lines. `./scripts/check.sh analyze` and the affected
  tests pass.

Facts checked: `pdfPageIndex` is **1-based** (`pdf_to_page_converter.dart:202`
stores `pageNumber`, and `rasterizePdfPage` calls `getPage(pageNumber)`), so
the required page count is the largest referenced index. Cache keys are
`'<stored>|<pdfPageIndex>'`, with HQ variants `'<key>@<q>x'`. Thumbnail keys
use the same base key. A `null` render result is not cached, but it stays
alive while `pdf_background.dart` watches `pdfPageRenderProvider(key)`, so it
must be invalidated explicitly.

## 2. Affected files
drawing_ui (`packages/drawing_ui/lib/src/...`):
- `providers/pdf_source_relink_provider.dart` (new): handler typedef + provider + `evictPdfSource`.
- `providers/providers.dart` (barrel): export the new file.
- `canvas/pdf_page_placeholder.dart`: optional "Locate PDF…" button; calls handler, then evicts.
- `l10n/error_strings.dart`: `pdfLocateSource` (abstract + TR + `toMap`).
example_app (`example_app/lib/...`):
- `features/documents/domain/entities/pdf_relink_failure.dart` (new): `PdfRelinkError` enum + `PdfRelinkFailure extends Failure`.
- `features/documents/domain/repositories/pdf_source_files.dart` (new): ports `PdfPageCounter`, `PdfSourceFiles`.
- `features/documents/domain/usecases/relink_pdf_source_usecase.dart` (new).
- `features/documents/data/datasources/pdfx_page_counter.dart` (new): `PDFLoader` + `pdfFileLooksEncrypted` + `pdfImportFailureFor`.
- `features/documents/data/datasources/local_pdf_source_files.dart` (new): temp copy + rename, never overwrites.
- `features/documents/documents.dart`: export the new domain/data files.
- `core/di/injection.dart`: register the use case (lazy singleton, `getIt<PdfPathResolver>()`).
- `features/editor/presentation/providers/pdf_relink_handler.dart` (new): `pdfRelinkHandlerFor(...)` picks the file, runs the use case, shows a snackbar.
- `features/editor/presentation/screens/editor_screen.dart`: set the handler next to `pageTrashCallbackProvider`; clear it on leave.
- `features/editor/presentation/l10n/app_error_strings.dart`: `pdfLocateSource`.
- `l10n/app_en.arb`, `l10n/app_tr.arb` (+ regenerated `app_localizations*.dart`): 4 keys (below).

## 3. Design
**drawing_ui.** It follows the existing `pageTrashCallbackProvider` pattern
(a host-set `StateProvider`, `null` = feature off):
```dart
/// Returns true once the source is back at [storedPath]; the host does the
/// picking and shows its own feedback.
typedef PdfSourceRelinkHandler = Future<bool> Function(String storedPath);
final pdfSourceRelinkProvider = StateProvider<PdfSourceRelinkHandler?>((_) => null);

/// Drops every cached render of [stored] so its pages render again.
void evictPdfSource(ProviderContainer c, String stored);
```
`evictPdfSource` removes the keys starting with `'$stored|'` from
`pdfPageCacheProvider` and `pdfThumbnailCacheProvider`. It invalidates
`pdfSourceMissingProvider(stored)` and, for every page in
`documentProvider.pages` with `background.pdfFilePath == stored`, also
`pdfPageRenderProvider('$stored|${pdfPageIndex}')`. Placeholder: after the
message it adds a `FilledButton.tonal` (`minimumSize: Size(0, 48)`, spacing from
`ChromeSpacing`, colours from `colorScheme`) labelled `errors.pdfLocateSource`,
shown only when `missing && handler != null`. `onPressed` captures
`ProviderScope.containerOf(context)` before the await, then
`if (await handler(path)) evictPdfSource(container, path)`. No business logic
lives in the widget.

**Domain (no dart:io, no drawing_ui, same as the current domain):**
```dart
enum PdfRelinkError { openFailed, passwordProtected, fileAccess, storageFull,
  pageCountMismatch, targetExists }
class PdfRelinkFailure extends Failure { // props: message, code, error, found, required
  const PdfRelinkFailure(this.error, {this.found = 0, this.required = 0}); }
abstract interface class PdfPageCounter {
  Future<Either<PdfRelinkFailure, int>> pageCount(String path); }
abstract interface class PdfSourceFiles {
  Future<bool> exists(String stored);
  /// Copies [sourcePath] to a temp file beside resolve(stored), then renames it.
  /// Left(targetExists) if the target appeared; the temp file is always removed.
  Future<Either<PdfRelinkFailure, Unit>> install(String sourcePath, String stored); }
class RelinkPdfSourceUseCase {
  RelinkPdfSourceUseCase(this._counter, this._files);
  Future<Either<Failure, Unit>> call({required String storedPath,
      required String pickedPath, required int requiredPages});
  /// Highest pdfPageIndex (1-based) of [pages] referencing [stored].
  static int requiredPagesFor(Iterable<Page> pages, String stored); }
```
The domain may import `drawing_core` because it is pure Dart. Order of checks:
`exists` → Left(targetExists); `pageCount` → Left(passthrough); `count <
requiredPages` → Left(pageCountMismatch, found, required); then `install`.

**Data.** `PdfxPageCounter` opens the file with `PDFLoader.loadFromFile` and
returns `pagesCount`, disposing in `finally`. It maps errors through
`pdfImportFailureFor`, and if that says `openFailed` while
`pdfFileLooksEncrypted(path)` is true, it returns `passwordProtected`.
`LocalPdfSourceFiles(PdfPathResolver)` creates the parent directory
recursively, copies to `'$target.relink-<micros>.tmp'`, checks `exists(target)`
again and only then calls `rename`. On `FileSystemException` it returns
`storageFull` (via `isStorageFullError`) or `fileAccess`, and deletes the temp
file in `finally`.

**Presentation (example_app).** `pdfRelinkHandlerFor(ProviderReader read,
BuildContext context)` returns a handler. The handler calls
`FilePicker.platform.pickFiles(type: custom, ['pdf'], withData: false)` and
returns false on cancel. It computes `requiredPagesFor(read(documentProvider).pages, stored)`
and runs `getIt<RelinkPdfSourceUseCase>()`. On success it shows a snackbar and
returns true. On Left it shows the mapped copy: password/open/fileAccess/
storageFull use the existing `ErrorStrings`, and the new keys cover the rest.
`targetExists` returns true, because the file is back, so evicting is correct.
A local `busy` flag ignores a second tap while running. State ownership: the
handler belongs to the editor session; the caches stay in drawing_ui.

New ARB keys (EN / TR):
- `editorErrorPdfLocateSource`: "Locate PDF…" / "PDF'yi bul…"
- `editorPdfRelinkDone`: "PDF re-linked" / "PDF yeniden bağlandı"
- `editorPdfRelinkPageCountMismatch(found, required)`: "This PDF has {found} pages; the notebook needs {required}." / "Bu PDF {found} sayfa; defter {required} sayfa gerektiriyor."
- `editorPdfRelinkFailed`: "Couldn't re-link the PDF" / "PDF yeniden bağlanamadı"

## 4. Test plan
- `example_app/test/features/documents/domain/usecases/relink_pdf_source_usecase_test.dart`
  (mocktail fakes). Cases: success → `install(picked, stored)` called and Right(unit);
  3 pages vs required 5 → Left(pageCountMismatch, 3, 5) and `verifyNever(install)`;
  counter Left(passwordProtected) → propagated, no install; target exists →
  Left(targetExists), counter and install never called; `requiredPagesFor`
  ignores other paths and pages with a null index, and returns 0 for none.
- `example_app/test/features/documents/data/datasources/local_pdf_source_files_test.dart`
  (real temp dir). Cases: copies bytes to `resolve('pdfs/a.pdf')` and creates
  `pdfs/`; existing target keeps its bytes and gives Left(targetExists); no
  `*.tmp` is left after success or failure; a legacy absolute stored path lands
  under the current root.
- `example_app/test/features/documents/data/datasources/pdfx_page_counter_test.dart`:
  inject `PDFLoader(openFile: ...)`. Cases: count is returned; a throwing open on
  a file containing `/Encrypt` gives passwordProtected; a throwing open on a
  plain file gives openFailed.
- `packages/drawing_ui/test/canvas/pdf_source_missing_test.dart` (extend, file stays <300).
  Cases: no handler → no button; missing + handler → button by key
  `pdfLocateSourceButton`, height >= 48; existing file + handler → no button;
  tap calls the handler with the stored path.
- `packages/drawing_ui/test/canvas/pdf_source_relink_test.dart` (new). Pump a
  canvas or `pdf_background` with `pdfFileRasterizerProvider` overridden by a
  fake that returns PNG bytes once the file exists. The handler writes the file
  and returns true; after pump the placeholder is gone and `Image` is shown.
  Unit test `evictPdfSource`: it removes only `'<stored>|'` keys, including the
  `@2.0x` variants and thumbnails.
- l10n drift: `drawing_strings_test.dart` and `app_drawing_strings_test.dart` pick up `toMap`.

## 5. Tasks (one implementer run each, TDD: tests first)
1. **Domain**: failure entity, ports, use case + tests and barrel exports.
   Verify: `cd example_app && flutter test test/features/documents/domain/usecases/relink_pdf_source_usecase_test.dart`.
2. **Data**: `LocalPdfSourceFiles`, `PdfxPageCounter` + tests, DI registration.
   Verify: `cd example_app && flutter test test/features/documents/data/datasources/`.
3. **drawing_ui strings + provider + evict**: `pdfLocateSource` (TR),
   `pdf_source_relink_provider.dart` with `evictPdfSource` test, barrel export.
   Verify: `cd packages/drawing_ui && flutter test test/l10n test/canvas/pdf_source_relink_test.dart`.
4. **Placeholder button** + widget tests (AC1, AC3).
   Verify: `cd packages/drawing_ui && flutter test test/canvas/`.
5. **Host wiring**: ARB keys + `flutter gen-l10n`, `AppErrorStrings`,
   `pdf_relink_handler.dart`, `editor_screen.dart` set/clear.
   Verify: `cd example_app && flutter test test/features/editor` and `./scripts/check.sh analyze`.
6. **Final**: `./scripts/check.sh analyze && ./scripts/check.sh test`, then
   `wc -l` on the touched files.

## 6. Risks and out of scope
- `rename` overwrites on POSIX. The guard is the exists check just before it,
  which leaves a tiny race window that is acceptable on a single-user device.
  This is documented in the code.
- Picking a different PDF with enough pages is accepted, and the annotations
  then sit on the wrong content. A content hash would need a stored checksum
  we do not have, so it is deferred. The user can re-link again.
- Placeholder button styling still has to pass a `ui-designer` check.
  Optional: a golden of the missing state through the design loop.
- Out of scope (YAGNI): library-level "missing PDFs" scan, batch re-link, a
  re-link entry in the page menu, shipping PDFs in backups (Auto Backup quota),
  and any change to the thumbnail renderer beyond cache eviction.

## 7. Reference check
- GoodNotes: the PDF lives inside the document package and travels with
  backups, so there is no "missing PDF" state.
- Flexcil: `.flex` backups include the PDFs together with the annotations.
- StarNote: documents are stored locally with their PDF, and export/backup
  carries the file.
- What we do: all three keep the PDF with the notebook. We deviate because of
  the Android Auto Backup quota (the whole backup is skipped above 25 MB), so we
  need a recovery path: re-link the source file in place, with a picker UX like
  PDF import.
