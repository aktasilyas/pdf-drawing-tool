# Plan #163: editor error, canvas theme follow, library polish

Branch `claude/163-editor-error-theme-polish`. No Flutter SDK in the session: CI is the verifier.

## 1. Problem and acceptance criteria
Four small gaps found in the audit. Done means all of these hold:
- AC1 Editor load error: fixed Turkish copy (no raw `Exception: ...`), **Tekrar dene** re-runs the
  load, **Geri dön** works with or without a back stack (`go('/documents')` fallback), colours come
  from `context.palette`, spacing from `AppSpacing`, buttons >= 48dp.
- AC2 `EditorBody` is not built until `documentProvider` holds the loaded document (same id).
- AC3 Canvas `followSystem` mode uses `Theme.of(context).brightness`. Test: app dark + platform
  light -> dark canvas scheme.
- AC4 Favourites with no items shows `FavoritesEmptyState`. `DocumentsErrorView` has a Retry
  button that invalidates the failed provider.
- AC5 Sidebar "Yeni Klasör" while inside a root folder creates a subfolder of it. Inside a subfolder
  (depth 2, the max) it shows `Alt klasörlerin altına klasör oluşturulamaz` and opens no dialog.

## 2. Affected files
drawing_ui:
- `lib/src/providers/canvas_dark_mode_provider.dart`: rename `platformBrightnessProvider` ->
  `appBrightnessProvider`, update doc comments ("follow app theme"). Keep enum value `followSystem`:
  it is persisted by name in SharedPreferences.
- `lib/src/screens/canvas_brightness_sync.dart` (new, ~40 lines): `CanvasBrightnessSync` widget.
- `lib/src/screens/drawing_screen.dart`: delete `didChangeDependencies` (l.78-87); wrap the
  `DrawingThemeProvider` returned at l.327 in `CanvasBrightnessSync(child: ...)` (file shrinks).
- `test/canvas_dark_mode_test.dart`: rename the two overrides (l.50, l.71).
- `test/screens/canvas_brightness_sync_test.dart` (new).
The rename has 5 references (the definition, `canvasColorSchemeProvider` l.70, `drawing_screen.dart`
l.84, test l.50/l.71). example_app does not reference it. It is exported through `providers.dart`,
so the analyzer will flag any missed reference.

example_app:
- `features/editor/presentation/widgets/editor_load_error_view.dart` (new, ~70 lines).
- `features/editor/presentation/screens/editor_screen.dart`: use the error view; add the "applied" gate.
- `features/editor/editor.dart`: export the new widget.
- `features/documents/presentation/widgets/documents_error_views.dart`: add `VoidCallback? onRetry`.
- `features/documents/presentation/widgets/documents_content_view.dart` (288 lines): pass `onRetry` at
  l.107/111/191/195; l.198 -> `const FavoritesEmptyState()`. Must stay <= 300 lines.
- `features/documents/presentation/widgets/trash_content_view.dart` l.30: `onRetry` -> `trashItemsProvider`.
- `features/documents/presentation/widgets/move_to_folder_dialog.dart` (366 lines, already over the
  limit): add `parentFolderId`; move `_buildInlineColorPicker` out to a new file
  `inline_folder_color_row.dart` (`InlineFolderColorRow`) so the dialog ends up shorter than today.
- `features/documents/presentation/screens/documents_screen_helpers.dart`: add
  `resolveNewFolderParent`; `showCreateFolderDialog` uses it.
- `features/documents/presentation/constants/documents_strings.dart`: add `folderDepthError`.

## 3. Design
**Canvas follow (AC3).** `appBrightnessProvider` stays a `StateProvider<Brightness>` (default light).
`CanvasBrightnessSync extends ConsumerStatefulWidget { final Widget child; }`. In
`didChangeDependencies` it reads `Theme.of(context).brightness`, which also subscribes it to theme
changes. If the value differs from the last one written, it schedules a post-frame write to
`appBrightnessProvider.notifier` (guarded by `mounted`), the same pattern as today. Providers cannot
be written during build, which is why the write is post-frame. `build` returns `child`.
`canvasColorSchemeProvider` stays as it is. Settings label "Sistem" stays unchanged (out of scope).

**Editor error (AC1).** `EditorLoadErrorView({required VoidCallback onRetry, required VoidCallback onBack})`
is a `Scaffold`, background `palette.background`. It shows a centred Column: `Icons.error_outline`
(`AppIconSize.emptyState`, `palette.danger`); title `Belge açılamadı` (`AppTypography.headlineSmall`,
`textPrimary`); body `Belge bulunamadı ya da okunamadı.` (`bodyMedium`, `textMuted`); then a Row with
`AppButton('Geri dön', variant: outline)` and `AppButton('Tekrar dene', variant: primary)`, separated by
`AppSpacing.md`. In `EditorScreen` the error branch logs with `logger.w('Editor load failed: $error')`
(`core/utils/logger.dart`) and returns the view with:
- `onRetry: () => ref.invalidate(documentLoaderProvider(documentId))`
- `onBack: () => context.canPop() ? context.pop() : context.go('/documents')`
No session was started yet, so the back action does no cleanup (unlike `_handleBack`).

**Applied gate (AC2).** In the data branch, keep the post-frame `startEditorSession` block and the
`ref.listen` as they are. After them add:
```dart
final appliedId = ref.watch(documentProvider.select((d) => d.id));
if (appliedId != document.id) return const Scaffold(body: Center(child: CircularProgressIndicator()));
```
`DocumentNotifier` starts with a fresh `emptyMultiPage` id, and `_handleBack` invalidates it, so ids
never collide. After `startEditorSession` the select fires and the widget rebuilds into `EditorBody`.
The loading Scaffold can be shared with the loading branch through a private const.

**Retry (AC4).** `DocumentsErrorView({required error, this.onRetry})`. The icon colour becomes
`context.palette.danger`; size stays 48 (an existing test asserts it). The `Hata: $error` text is
unchanged (existing test). When `onRetry != null`, add `AppSpacing.lg` and then
`AppButton(label: 'Tekrar dene', variant: AppButtonVariant.outline, onPressed: onRetry)`. Invalidate:
`foldersProvider` / `documentsProvider(parentFolderId)` (l.107/111), `favoriteFoldersProvider` /
`favoriteDocumentsProvider` (l.191/195), `trashItemsProvider` (trash).

**Subfolder (AC5).** The only caller is the sidebar `onCreateFolder` -> `showCreateFolderDialog()`
(documents_screen.dart l.247-250). The folder you are in is `currentFolderIdProvider`, which is set
by `_navigateToFolder` and cleared on section change. Domain rule: `Folder.canHaveSubfolders`
(`parentId == null`). The repository enforces the same rule with `ValidationFailure('Alt klasörlerin
altına klasör oluşturulamaz')` (folder_repository_impl.dart l.82-89). That stays as the backstop and
is surfaced by `LibraryErrorListener`. New top-level pure function in the helpers file:
```dart
typedef NewFolderTarget = ({String? parentId, bool depthExceeded});
NewFolderTarget resolveNewFolderParent(String? currentFolderId, List<Folder> folders)
```
- null id, or id not found in the list -> `(parentId: null, depthExceeded: false)`
- parent has `canHaveSubfolders` -> `(parentId: id, depthExceeded: false)`
- otherwise -> `(parentId: null, depthExceeded: true)`

`showCreateFolderDialog` reads `ref.read(currentFolderIdProvider)` and
`ref.read(foldersProvider).valueOrNull ?? const []`. If `depthExceeded`, it calls
`AppToast.error(context, DocumentsStrings.folderDepthError)` and returns. Otherwise it opens
`MoveToFolderDialog(documentIds: const [], parentFolderId: t.parentId)`. `_handleCreateFolder` passes
`parentId: widget.parentFolderId` to `createFolder`. The move flows keep `parentFolderId` null.

## 4. Test plan
- `packages/drawing_ui/test/screens/canvas_brightness_sync_test.dart` (new). Use
  `ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(null)])` with
  `tester.platformDispatcher.platformBrightnessTestValue = Brightness.light` (reset with
  `addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue)`). Mount
  `MaterialApp(theme: ThemeData(brightness: Brightness.dark), home: CanvasBrightnessSync(child: SizedBox()))`.
  Get the container with `ProviderScope.containerOf(tester.element(find.byType(SizedBox)))`, then
  `setMode(followSystem)` and `pump()` twice.
  (a) `app_dark_platform_light_gives_dark_canvas`: `canvasColorSchemeProvider.background == Color(0xFF2C2C2C)`.
  (b) `theme_switch_to_light_updates_canvas`: re-pump with a light theme -> `0xFFFFFFFF`.
- `packages/drawing_ui/test/canvas_dark_mode_test.dart`: rename only.
- `example_app/test/features/editor/presentation/screens/editor_screen_test.dart`: extend.
  Add a `GoRouter` harness (`/documents` -> `Text('Library')`, `/editor/:id` -> `EditorScreen`,
  `initialLocation: '/editor/test-doc-id'`) for the back test.
  (a) Error shows `Belge açılamadı` and no `Exception` text; `Tekrar dene` and `Geri dön` are present and
  `tester.getSize(...).height >= 48`.
  (b) Tap `Tekrar dene` -> `verify(() => mockLoadUseCase(id)).called(2)`.
  (c) `Geri dön` with no stack -> `find.text('Library')`.
  (d) Gate: stub `Right(DrawingDocument.emptyMultiPage('T'))`, then `pumpWidget` + `pump()`. Expect
  `find.byType(EditorBody)` to find nothing and `CircularProgressIndicator` present, and the container's
  `documentProvider.id == doc.id`. Do not pump further: EditorBody is not test-safe (see the note in
  the file).
  Update the old `Belge yüklenemedi` / `Geri Dön` expectations.
- `.../widgets/documents_error_views_test.dart`: no button without `onRetry`; tap `Tekrar dene` calls it;
  height >= 48.
- `.../widgets/documents_content_view_test.dart`:
  (a) favourites section with `favoriteFoldersProvider` / `favoriteDocumentsProvider` overridden to `[]`
  -> `FavoritesEmptyState` shown and `DocumentsEmptyState` not shown.
  (b) `favoriteFoldersProvider` override that counts calls and throws -> tap `Tekrar dene` -> calls == 2.
- `.../screens/documents_screen_helpers_test.dart` (new, pure unit test on `libraryFolders` from
  `library_fixtures.dart`): null -> root; `f-ders` -> parent `f-ders`; `f-biyoloji` -> depthExceeded;
  unknown id -> root.
- `.../widgets/move_to_folder_dialog_test.dart` (new). `class MockFolderRepository extends Mock
  implements FolderRepository`. Override `folderRepositoryProvider` with the mock and `foldersProvider`
  with `libraryFolders`. Stub `createFolder(name: any(named:'name'), parentId: any(named:'parentId'),
  colorValue: any(named:'colorValue'))` -> `Right(folder)`. Pump
  `MoveToFolderDialog(parentFolderId: 'f-ders')`, tap `Yeni Klasör`, enter `Alt`, tap `Oluştur`.
  `verify(... parentId: 'f-ders' ...)`. Wrap in `Scaffold` so AppToast/Overlay works.

## 5. Tasks (one implementer run each)
1. Canvas follow: provider rename, CanvasBrightnessSync, drawing_screen wiring, tests.
   Verify: `cd packages/drawing_ui && flutter test test/canvas_dark_mode_test.dart test/screens/canvas_brightness_sync_test.dart`
2. Editor error view, applied gate, barrel export, editor_screen_test.
   Verify: `cd example_app && flutter test test/features/editor/presentation/screens/editor_screen_test.dart`
3. DocumentsErrorView retry, call sites, favourites empty state, tests.
   Verify: `cd example_app && flutter test test/features/documents/presentation/widgets/documents_error_views_test.dart test/features/documents/presentation/widgets/documents_content_view_test.dart`
4. Subfolder creation: helper, dialog param, colour row extraction, strings, tests.
   Verify: `cd example_app && flutter test test/features/documents/presentation/`
After every task, run `./scripts/check.sh analyze`. CI runs the full `./scripts/check.sh test`.

## 6. Risks / left out
- Risk: the gate test depends on post-frame ordering; if it is flaky, assert only "no EditorBody after the first pump".
- Risk: `documents_content_view.dart` is close to 300 lines; if needed, move `_FavoritesView` to `favorites_view.dart`.
- Left out: the "Sistem" settings label, deeper folder nesting, folder-name context in the dialog header,
  32dp colour swatches (pre-existing touch-target debt, needs a separate issue), and goldens (no visual
  restyle beyond tokens).

## 7. Reference check
- Canvas dark: GoodNotes offers dark paper/appearance tied to the app appearance, not a separate OS
  probe. Flexcil and StarNote have an in-app dark mode that the page follows. All three converge on
  "page follows the app theme", so we track the app theme.
- Load error: all three show a modal or alert with a plain message and a way back to the library,
  never a raw exception. We add Retry because local file I/O can fail transiently.
- New folder: GoodNotes (Folders & documents help), Flexcil and StarNote all create the folder in
  the folder you are viewing. We match that. Deviation: our existing 2-level limit (v1.0 scope,
  enforced in the repository), so at max depth we explain why instead of silently creating at root.
