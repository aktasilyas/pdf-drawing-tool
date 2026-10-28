# Plan: #371 page trash frees PDFs, unique ids, Either API, tests

## Design
1. `DocumentLocalDatasource.deleteUnreferencedPdfs(paths)`: reuses the
   private `_isPdfReferenced` check (document contents + trashed pages) and
   `_deleteFile` (resolves relative paths). No duplicated reference logic.
2. `PageTrashRepositoryImpl`:
   - trash ids are `trashed_page_<uuid v4>` (optional `Uuid` ctor arg, like
     `DocumentRepositoryImpl`).
   - `permanentlyDeletePage`, `emptyTrash`, `purgeExpired` go through one
     `_remove(pages)`: delete the rows in one transaction, then
     `deleteUnreferencedPdfs` for the pages' `background.pdfFilePath`.
   - every public method returns `Either<Failure, T>` via a `_guard` that maps
     exceptions to `CacheFailure`.
3. Callers: documents controller page-trash and empty-trash mixins,
   `trashedPagesProvider`, `PurgeExpiredTrashUseCase` fold the Either; the
   controller API (`String?`, `bool`, `void`) is unchanged, so the editor
   screen and menus need no change.

## Tests
- New `test/features/documents/data/repositories/page_trash_repository_impl_test.dart`
  (in-memory Drift): distinct ids for two pages trashed at once; move stores
  source and position; restore (insert, re-index, page count, index clamp,
  missing source, rollback → Left); permanent delete / empty / purge delete an
  unreferenced PDF and keep one referenced by a document or another trashed page.
- The page-trash group moved out of `library_repositories_test.dart`; mocks
  and real-impl tests updated to the Either API.

No UX change; Reference check not needed (issue).
