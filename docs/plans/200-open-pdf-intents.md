# Plan: #200 Open PDFs from other apps (ACTION_VIEW / ACTION_SEND)

## Acceptance criteria
- AC1: MainActivity intent filters for `VIEW` and `SEND` with `application/pdf` (category DEFAULT).
- AC2: The incoming URI is copied to the cache by Kotlin, then `PDFImportService.importFromFile`
  copies it to app storage. No persistable URI permission. The cache copy is deleted afterwards.
- AC3: Cold start and warm start (singleTop `onNewIntent`) both work: Dart tests for both
  delivery paths plus a documented adb check.
- AC4: Reference check in the PR.

## Alternatives
- `receive_sharing_intent`: text/media sharing focus, iOS setup we don't need, maintenance gaps. Rejected.
- `app_links` / `uni_links`: deep links, not `content://` + MIME. Rejected.
- **Chosen:** MethodChannel `elyanotes/incoming_pdf` in MainActivity (~100 lines Kotlin, no plugin).

## Design
**Kotlin (`MainActivity.kt`)**: `configureFlutterEngine` creates the channel. `onCreate` handles the
intent only when `savedInstanceState == null` and not launched from history; `onNewIntent` calls
`setIntent` and handles it. VIEW → `intent.data`, SEND → `EXTRA_STREAM`. A single-thread executor
copies the stream to `cacheDir/incoming/<millis>/<sanitized display name>.pdf` and posts
`{path, name, size}` to the main thread. Delivery: a `pending` list until Dart calls `ready`
(returns and clears it), then `invokeMethod("onPdf", map)`.

**Dart domain** (`features/documents/domain`): `IncomingPdf {path, name, size}`;
`IncomingPdfSource { Stream<IncomingPdf> watch(); }`.

**Dart data**: `MethodChannelIncomingPdfSource` — on first listen sets the handler (`onPdf`), calls
`ready`, emits the returned items; `MissingPluginException` → empty stream; malformed maps skipped.

**Dart presentation**: `incomingPdfSourceProvider`, a queue Notifier, and `IncomingPdfListener`
mounted in `DocumentsScreen` (the `MaterialApp.router` builder context is above the Navigator, so
dialogs/push fail there). Items are processed serially: quota check (`ensureDocumentQuota`,
extracted from `showNewDocumentDropdown`; unrestricted with flags off) → `importPdfFile(...)`
(extracted from `importPdf`, new file `pdf_file_importer.dart`) → delete the cache copy in `finally`.
`pdfTitleFromFileName` strips only a trailing `.pdf` (case-insensitive).

## Tests
1. MethodChannel source: cold (`ready` returns items), warm (platform `onPdf`), both,
   `MissingPluginException`, malformed map.
2. Queue: FIFO, remove, cancel on dispose.
3. Listener (fake source, injected importer/quota): cold, warm, serial, quota blocked, temp file
   deleted on success and failure.
4. `pdfTitleFromFileName` cases.
5. Kotlin compiles in CI (android-manifest.yml release APK). `check-android-manifest.sh` asserts the
   VIEW/SEND + application/pdf filters survive in both merged manifests.

Manual check (PR): cold — `adb shell am force-stop com.aktasilyas.elyanotes`, push a PDF to
Download, open it from Files → Open with → Elyanotes; warm — repeat with the editor open and via
Share → Elyanotes; rotating after import must not re-import.

## Left out (YAGNI)
`SEND_MULTIPLE`, location / "add to current document" chooser, iOS, other MIME types, `file://` URIs.

## Reference check
- GoodNotes (iOS help center): Share → "Open in Goodnotes" → New Document (pick location) or
  Current Document. Android: share-to-import listed as missing on their feedback forum.
- Flexcil (Android, unverified): Open with / share imports as a new document and opens it.
- StarNote (unverified): store listing says PDFs can be imported from other apps as new documents.
- Converged: incoming PDF → new document in the library, opened for annotation.
- We do: new document in the currently selected folder (root on cold start), opened in the editor,
  no prompt. Deviation: no location/current-document chooser in v1.0 (scope).
