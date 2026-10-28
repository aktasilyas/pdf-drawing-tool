# Plan: #401 orphaned managed-file sweep

## Goal
Reclaim disk space of images (`elyanotes_images/`) and copied PDFs (`pdfs/`) that
no notebook references (image elements deleted in the editor, cancelled
placements, older leaks). Follows #384 (`ManagedFileCleanup`).

## Acceptance criteria (as implemented)
- AC1: once per app start, after the first frame (+3 s), at most once per 24h;
  lists only direct children of `<docs>/pdfs/` and `<docs>/elyanotes_images/`;
  deletes a file only when no `document_contents.data`, `trashed_pages.page_data`,
  `documents.thumbnail_path` or `ai_messages_local.image_path` mentions it;
  deletes through `ManagedFileCleanup.deleteFiles`.
- AC2: candidate only when `max(stat.modified, stat.changed)` is older than
  `now - 10 min` (ctime covers copies that keep the source mtime).
- AC3: nothing else is touched: docs root, other dirs, subdirectories, symlinks
  (`list(followLinks: false)`, `File` entities only). Passthrough resolver → no-op.
- AC4: real-Drift tests: referenced, orphaned, recent, outside-dir, legacy paths.
- AC5: never blocks UI, never throws to the caller, failures are logged; the
  last-run time is stored only on success.

## Design
- `managed_file_paths.dart`: `managedFileRefsIn(String text)` — regex
  `(?:^|[/\\"])(pdfs|elyanotes_images)[/\\]+([^/\\"]+)` → `'<dir>/<name>'`;
  matches relative, absolute Unix and JSON-escaped Windows paths (same
  parent-directory rule as `PdfPathResolver.resolve`).
- `ManagedFileCleanup`: `_anyRowContains(needle)` shared by `_isReferenced` and
  new `isMentioned(name)` (LIKE on both content tables; wildcards only widen,
  so they only keep files).
- New `OrphanFileSweeper` (`managed_file_sweep.dart`, data layer):
  candidates → referenced set (row by row, ids first; large texts scanned in
  `Isolate.run`) → orphans → recheck `isMentioned(basename)` right before
  delete (covers an autosave between scan and delete) → `deleteFiles` → count.
- `DocumentLocalDatasource.sweepOrphanedFiles({required DateTime olderThan})`
  → `DocumentRepository.sweepOrphanedFiles` (`Either`, via `guard`).
- Domain: `MaintenanceSchedule` (last sweep time) + `SweepOrphanedFilesUseCase`
  (24h throttle, 10 min grace, clock that went back → run).
  Data: `PrefsMaintenanceSchedule` (SharedPreferences, key
  `maintenance.orphan_file_sweep_ms`).
- DI: one manual line in `lib/core/di/injection.dart` (manual GetIt, no codegen).
- Trigger: `core/bootstrap/orphan_file_sweep_startup.dart`
  `sweepOrphanedFilesAfterFirstFrame(...)`, called `unawaited` from `main.dart`
  after `runApp` when startup succeeded (first frame = library on the happy
  path). Not hooked into `DocumentsScreen` (would fire on every rebuild and
  leak timers into existing widget/golden tests).

## Tests
- `managed_file_refs_test.dart` (pure regex).
- `orphan_file_sweep_test.dart` (real Drift via `LibraryFixture`): orphan
  deleted + count, content-referenced kept, trashed-page-referenced kept, PDFs,
  legacy absolute / Windows-escaped kept, recent kept, outside dirs /
  subdirectory / symlink untouched, basename-only mention kept, missing dirs,
  passthrough resolver.
- Repository Left on datasource throw; use case throttle (mocktail);
  prefs schedule round-trip; startup helper (waits for first frame, swallows
  errors).

## Risks / out of scope
- Undo of an image deletion after the sweep removed its file within the first
  seconds of a session: window is tiny (recheck right before delete); revisit
  if reported.
- Out of scope: immediate delete in the editor, render/thumbnail caches,
  settings UI, the legacy `Documents.content` blob (unused since schema v6).
