# 391 — PDF import on a full disk reports storage full

Issue: #391. Size S.

## Reference check
Not verified against GoodNotes/Flexcil/StarNote in this run: this is error
copy, not a product or UX decision. Export already reports a full disk as its
own message (`ExportFailure.storageFull`); import now does the same.

## Steps
1. `storage_errors.dart` (drawing_ui services): `isStorageFullError` — errno
   28 or "no space left"; `exportFailureFor` reuses it.
2. `PdfImportError.storageFull`; `pdfImportFailureFor` checks it first for a
   `FileSystemException`, other file-system errors stay `fileAccess`.
3. Copy: `ErrorStrings.pdfStorageFull` (TR default), `error_labels.dart`
   case, `AppErrorStrings` → new `editorErrorPdfStorageFull` (TR + EN).
4. Tests: mapping (errno, message only, other errno → fileAccess) and an
   `importFromFile` run under `IOOverrides` whose copy writes part of the
   file then throws ENOSPC → `storageFull`, `pdfs/` empty (cleanup already
   done by `storePdfAndImport`).
