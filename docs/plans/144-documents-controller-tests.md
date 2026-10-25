# Plan: #144 DocumentsController tests + documents_provider split

Goal: no behaviour change; make the documents feature testable and layered.

1. Domain: add abstract `PageTrashRepository` in
   `domain/repositories/page_trash_repository.dart`; the data class becomes
   `PageTrashRepositoryImpl implements PageTrashRepository`.
2. DI: register `TrashedPageLocalDatasource` and `PageTrashRepository` in
   `core/di/injection.dart`; `pageTrashRepositoryProvider` reads GetIt. No
   presentation file imports `features/documents/data/`.
3. Split `documents_provider.dart` (682 lines) into:
   - `document_view_preferences_providers.dart` (view mode, sort, pin favourites)
   - `document_list_providers.dart` (repository, selection, list/search providers)
   - `trash_providers.dart` (trash providers, `TrashItem`)
   - `documents_invalidation.dart` (shared invalidation helpers)
   - `imported_document_content.dart` (V2 content map for PDF import)
   - `documents_controller.dart` + mixins `documents_controller_bulk.dart`,
     `documents_controller_page_trash.dart`
   `documents_provider.dart` re-exports all of them, so call sites are unchanged.
4. Tests (mocktail, `ProviderContainer` overrides): every public controller
   method, success + `Left(Failure)` path, and which providers are rebuilt
   (counted via overridden list providers).
5. Verify in CI (no Flutter SDK in the session): analyze + example_app tests.
