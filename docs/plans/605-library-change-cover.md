# Plan #605: change a notebook's cover from its library menu

## 1. Problem and acceptance criteria
Covers can only be changed inside the editor (page options, `_applyCoverChange`).
Add a library entry point.
- AC1 "Change cover" tile in `showNormalDocumentMenu` only when
  `document.hasCover && document.coverId != null`; it opens a sheet with the existing
  `CoverGridView`, the current cover selected.
- AC2 `ChangeCoverUseCase` writes the cover page background and the row's `coverId`
  in one Drift transaction; layers/strokes/text on the cover page are untouched (#423).
- AC3 Unit tests for the use case; widget test: picking a cover refreshes the tile.
- AC4 `./scripts/check.sh analyze` and the affected tests are green (CI).
- AC5 The editor entry point is unchanged; both build the same background:
  `PageBackground(type: BackgroundType.cover, coverId: cover.id, color: cover.primaryColor)`.

## 2. Affected files (all under `example_app/`)
- `lib/features/documents/domain/repositories/document_repository.dart`: add `updateCover`.
- `lib/features/documents/data/repositories/document_repository_impl.dart`: implement it via `_modify` (file is 286 lines, stays under 300).
- `lib/features/documents/domain/usecases/change_cover_usecase.dart` (new): the use case.
- `lib/features/documents/documents.dart`: export the use case.
- `lib/features/documents/presentation/providers/documents_controller_cover.dart` (new): use-case provider + `DocumentsCoverOperation` mixin.
- `lib/features/documents/presentation/providers/documents_controller.dart`: add the mixin to `with` (one line + import).
- `lib/features/documents/presentation/providers/library_error.dart`: `LibraryAction.changeCover`.
- `lib/features/documents/presentation/l10n/library_labels.dart`: map it to `libraryErrorChangeCover`.
- `lib/features/documents/presentation/providers/document_menu_actions.dart`: `changeCover(document, cover)`.
- `lib/features/documents/presentation/widgets/change_cover_sheet.dart` (new): sheet around `CoverGridView`.
- `lib/features/documents/presentation/widgets/document_normal_menu.dart`: conditional tile.
- `lib/l10n/app_en.arb`, `app_tr.arb`, `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_tr.dart`: 2 keys, hand-edited.
- Tests: see section 4.

## 3. Design
Repository (domain), row-only update for notebooks with no stored content yet:
```dart
/// Sets the cover of [id] (hasCover = true) and bumps updatedAt; content untouched.
Future<Either<Failure, void>> updateCover(String id, String coverId);
```
Impl: `_modify(id, 'update cover', (d) => d.copyWith(updatedAt: DateTime.now()).withCover(coverId)).map((_) {})`.
All `DocumentRepository` test doubles are `extends Mock implements` (checked), so no fake breaks.

Use case (`documents/domain/usecases/change_cover_usecase.dart`), plain class, no `@injectable`:
```dart
class ChangeCoverUseCase {
  ChangeCoverUseCase(this._repository, {DocumentJsonSlicer slicer = const DocumentJsonSlicer()});
  Future<Either<Failure, void>> call(String documentId, String coverId);
}
```
Flow:
1. `CoverRegistry.byId(coverId) == null` -> `Left(ValidationFailure('Unknown cover: $coverId'))`.
2. `getDocument(id)`; if `!hasCover` -> `Left(ValidationFailure('Document has no cover'))`.
3. `getDrawingDocument(id)`:
   - `null` (never opened): `updateCover(id, coverId)`. `LoadDocumentUseCase` builds the
     cover page from `docInfo.coverId` on first open.
   - cover page at index `i`: `pages[i].copyWith(background: bg)` (layers kept), then `replacePages`.
   - no cover page (legacy/inconsistent): insert one at 0, as the editor does:
     `Page.createCover(index: 0, size: doc.pages.first.size, background: bg)` via `replacePages([cover, ...pages])`.
4. `content = await _slicer.toJson(updated)`, then `saveDocumentContent(id:, content:,
   pageCount: updated.pageCount, updatedAt: DateTime.now(), coverId: coverId, updateCover: true)`.
   This already runs content + row in one `guard` (Drift transaction) and needs no repo change.
5. Exceptions -> `Left(CacheFailure('Failed to change cover: $e'))`.
`bg` is built exactly as in AC5. Importing `DocumentJsonSlicer` from `editor/domain` is
domain-to-domain. `documents` already imports `editor`, so the cycle is not new.

DI and codegen: no `injection.config.dart` edit and no build_runner. The use case is built in a
Riverpod provider, the same way premium use cases are (`subscription_provider.dart`):
`final changeCoverUseCaseProvider = Provider((ref) => ChangeCoverUseCase(ref.watch(documentRepositoryProvider)));`

State and refresh: the `DocumentsCoverOperation` mixin (same pattern as `documents_controller_page_trash.dart`)
adds `Future<bool> changeCover(String documentId, String coverId)`:
- failure: `reportLibraryFailure(ref, f, LibraryAction.changeCover)`, return false.
- success: `invalidateDocumentLists(ref, documents: true, favorites: true, recent: true)`, return true.

Tiles render the cover from `DocumentInfo.coverId` through `CoverRegistry` (`document_card.dart:78`,
`document_list_tile.dart:48`), so invalidating the lists repaints them. No thumbnail
cache to clear: `thumbnailPath` and `documentPreviewBackgroundProvider` are used only for
coverless tiles, and the latter is keyed by `updatedAt`.

UI: `Future<Cover?> showChangeCoverSheet(BuildContext context, {required Cover current, required String title})`
- Uses the same sheet chrome as `showMenuSheet` (surface colour, `AppRadius.bottomSheet`,
  `isScrollControlled`, `useSafeArea`).
- Header: `l10n.libraryCover` text and a 48dp close `IconButton`.
- Body: `SizedBox(height: MediaQuery.sizeOf(ctx).height * 0.6, child: CoverGridView(...))`.
- Tapping a cover pops with it. Tapping the current cover pops `null` (no write).
Menu tile: `Icons.style_outlined`, `l10n.libraryChangeCover`. It pops the menu, then
`current = CoverRegistry.byId(document.coverId!) ?? CoverRegistry.defaultCover`, awaits the sheet,
and calls `actions.changeCover(document, picked)` if the result is non-null. Failures are shown
by LibraryErrorListener, like the other actions. No success snackbar: the tile change is the feedback.
Place it after "Rename". No business logic in widgets.

l10n (no SDK): hand-edit all 5 files, as #543 did. The `update-goldens` workflow runs
`flutter gen-l10n` and commits the result, so formatting drift self-heals there.
- `libraryChangeCover`: "Change cover" / "Kapağı değiştir"
- `libraryErrorChangeCover`: "Couldn't change the cover" / "Kapak değiştirilemedi"
Mirror the getter and doc-comment layout of `libraryExportAsPdf` in the 3 Dart files.

Layer rules: none bent.

## 4. Test plan (mocktail)
- `test/features/documents/domain/usecases/change_cover_usecase_test.dart` (new):
  (a) Stored doc with cover page + one stroke on it: saved content's page 0 has the new
  `coverId` and `color`, and the stroke is still there. `saveDocumentContent` is called once with
  `coverId: new, updateCover: true`, `pageCount` unchanged. (b) The non-cover pages' JSON is
  equal before and after. (c) Content null: only `updateCover(id, coverId)`, no
  `saveDocumentContent`. (d) No cover page: a cover is inserted at 0 and pageCount is +1.
  (e) Unknown coverId -> Left(ValidationFailure), no writes. (f) `hasCover == false` -> Left.
  (g) Repository Left is propagated.
  Capture the content map, then `DrawingDocument.fromJson` to assert.
- `test/features/documents/data/repositories/document_repository_impl_test.dart`: add
  "updateCover sets coverId, hasCover and updatedAt" using the existing harness of that file.
- `test/features/documents/presentation/providers/document_menu_actions_test.dart`: changeCover
  success invalidates lists (use the `DocumentsHarness.rebuiltBy` pattern: documents/favorites/recent);
  failure publishes `LibraryError` with `LibraryAction.changeCover`.
- `test/features/documents/presentation/widgets/documents_menus_test.dart`:
  - The tile is absent for `testDocument` (no cover). Existing tests keep that fixture, so they
    are unaffected.
  - The tile is present for `testDocument.copyWith(coverId: 'linen_sage', hasCover: true)` and is >=48dp.
  - Opening it shows `CoverGridView` with the current cover `selected`. Check through Semantics,
    as `cover_grid_test.dart` does.
- `test/features/documents/presentation/widgets/change_cover_refresh_test.dart` (new; AC3):
  - `ProviderScope` overrides `documentRepositoryProvider`. A `Consumer` renders a
    `DocumentCard` from `documentsProvider`.
  - `getDocuments` returns cover A first, then cover B after the write. Use
    `CoverRegistry.pickable[0]` and `[1]` so B is visible in the grid.
  - Stub `getDocument` (hasCover) and `getDrawingDocument` (content with a cover page).
  - Steps: open the menu, tap "Kapağı değiştir", tap B, then `pumpAndSettle`.
  - Expect `find.byWidgetPredicate((w) => w is CoverPreviewWidget && w.cover.id == B.id)`
    inside the card, and `saveDocumentContent(... coverId: B.id, updateCover: true)` called once.
- Golden `change_cover_sheet_golden_test.dart`: phone + tablet, light. Rendered via the
  `update-goldens` workflow and reviewed by `ui-designer` (design-loop).

## 5. Steps (one implementer run each)
1. **Domain + data.** Goal: `updateCover`, `ChangeCoverUseCase`, barrel export, and the use-case and
   repo tests. Verify: `cd example_app && flutter test test/features/documents/domain/usecases/change_cover_usecase_test.dart test/features/documents/data/repositories/document_repository_impl_test.dart` + `./scripts/check.sh analyze`.
2. **State + strings.** Goal: the 5 l10n files, `LibraryAction.changeCover` + label,
   `documents_controller_cover.dart` (provider + mixin), the controller `with`, `DocumentMenuActions.changeCover`,
   and the actions test. Verify: `flutter test test/features/documents/presentation/providers/document_menu_actions_test.dart test/features/documents/presentation/widgets/library_error_listener_test.dart` + analyze.
3. **UI.** Goal: `change_cover_sheet.dart`, the conditional menu tile, the menu tests and the
   refresh widget test. Verify: `flutter test test/features/documents/presentation/widgets/documents_menus_test.dart test/features/documents/presentation/widgets/change_cover_refresh_test.dart` + analyze.
4. **Golden + e2e smoke.** Goal: the sheet golden. Dispatch `update-goldens` for the branch, read
   the PNGs, and fix spacing/tokens if needed. Push to trigger the e2e workflow: the menu change
   touches `example_app/lib`, so e2e runs on the PR. Verify: CI green, including the `tablet` shard
   (the menu sheet now has 7 tiles for cover notebooks).
No Flutter SDK in session: steps run analyze/tests in CI on the pushed `claude/605-library-change-cover` branch.

## 6. Risks and left out
- Race with a late editor save: `SaveDocumentUseCase._tail` may still be writing this doc
  right after leaving the editor, and could overwrite the new cover. This is unlikely, since a
  user needs seconds to reach the menu. Not mitigated; if it shows up, expose a static
  `SaveDocumentUseCase.idle` future and await it.
- Read-modify-write: the content read happens outside the write transaction. Acceptable,
  because the library is the only writer while the editor is closed.
- Large notebooks: the slicer keeps serialization off long UI stalls. The write cost is the
  same as one editor save.
- Hand-edited gen-l10n files may differ in formatting. `gen-l10n` in CI rewrites them.
- Left out (YAGNI): adding/removing a cover from the library (`hasCover` toggle), custom/photo
  covers, premium gating of covers (premium is frozen; the creation flow does not gate either),
  bulk cover change, undo, and a success snackbar.

## 7. Reference check
- GoodNotes: "Change Cover" is in the document's context menu in the library (per issue). The
  help center also documents changing it in the editor (page 1 > Change Template > Cover > Apply).
  Content on other pages is unaffected.
- StarNote, Flexcil: not verified. A quick search found no official docs.
- Elyanotes follows GoodNotes: a library menu action plus the existing editor route, and ink on
  the cover is kept.
- Deviation: tap applies immediately (no Apply button). The sheet is single-purpose with no
  size/orientation options, so a confirm step adds nothing, and picking again reverts.
