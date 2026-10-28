# 391 — PDF import on a full disk reports storage full

Issue: #391. Size S.

## Reference check
GoodNotes, Flexcil and StarNote surface the platform's "not enough storage"
condition as its own message rather than a generic import error → same.

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
