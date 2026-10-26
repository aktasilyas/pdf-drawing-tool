# Plan: surface save and library write failures (#151)

## Goal
No write failure is silent: the editor keeps unsaved state and offers Retry,
and every library mutation tells the user when it failed.

## Design
1. **Datasources** (`document_local_datasource`, `folder_local_datasource`,
   `trashed_page_local_datasource`, `page_trash_repository_impl`): a
   `SharedPreferences.setString` that returns `false` throws `CacheException`
   (restore-page returns `false`). Repositories already map it to `CacheFailure`.
2. **Editor save path** (`editor_provider.dart`): `saveFailureProvider`
   (`StateProvider<Failure?>`) holds the last save failure. A failed save sets it
   and keeps `hasUnsavedChangesProvider`; a successful save clears it.
   `AutoSaveNotifier.retry()` re-saves the newest document.
   `SaveFailureBanner` (editor widget, palette `danger`/`onDanger`, 48dp Retry)
   is stacked over the canvas in `EditorBody`. Leaving the editor after a failed
   save is blocked so in-memory changes are not dropped.
3. **Library mutations**: `libraryErrorProvider` + `reportLibraryFailure(ref,
   failure, fallback)`. `DocumentsController`, its bulk/page-trash mixins and
   `FoldersController` report every failure. `LibraryErrorListener` (mounted in
   `MaterialApp.builder`) shows one `AppToast.error` per failure on any screen.
   Call sites drop their own failure snackbars (no duplicates) and show
   success messages only on success; Manage Folders stops reporting success
   for failed deletes/sort saves.
4. **Messages**: `ValidationFailure` messages are shown verbatim (written for
   users, Turkish). Storage failures carry English diagnostics, so the user sees
   a Turkish action message ("Belge çöpe taşınamadı") and the diagnostic is
   logged.

## Tests
- Datasource: rejected writes throw; repository returns `Left`.
- `AutoSaveNotifier`: failure kept + unsaved flag kept; retry clears.
- `SaveFailureBanner`: hidden/visible, Retry re-saves, 48dp, no overflow at
  380dp / textScaler 1.3.
- `LibraryErrorListener` over real datasources with rejecting prefs: snackbar
  for trash, rename (dialog), folder create, validation message verbatim.

## Reference check
(from the issue) GoodNotes, Flexcil and StarNote show an explicit error when
a notebook cannot be saved → same: a persistent banner with Retry; we also keep
the editor open after a failed save so unsaved changes are not discarded.
