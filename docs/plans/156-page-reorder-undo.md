# Plan: #156 Page reorder by drag + undoable page delete

Depends on #150 (page-aware history, merged in 1cb4ca2).

## 1. Problem and acceptance criteria
The sidebar grid has no drag. `PageManagerNotifier.reorderPage` has no callers and
only touches `pageManagerProvider`, never `documentProvider`, so nothing would be saved.
Page delete removes the page straight away and cannot be undone.

- AC1: Long-press + drag a thumbnail (docked tablet sidebar and phone drawer) moves the
  page. The order goes into `documentProvider`, so autosave keeps it after reopening.
  The page that was current stays current (tracked by id, not index).
- AC2: Deleting a page shows a SnackBar ("Sayfa silindi", action "Geri al"). Undo puts
  the same `Page` (same id and layers) back at the same index. The page-trash entry
  written on delete is removed again, so the page is not also left in the trash.
- AC3: Reorder, add and delete do not break #150 history. Entries are keyed by page id.
  After a reorder, undo still applies to the right page. After delete + "Geri al", that
  page's history entries work again.
- AC4: Widget tests: drag thumbnail 3 to position 1; delete then undo.
- Every new or touched file is 300 lines or less.

## 2. Affected files
- `packages/drawing_core/lib/src/models/document_page_ops.dart` (new): extension
  `DocumentPageOps on DrawingDocument` with `movePage(from, to)` and
  `insertPageAt(index, page)`. Both re-number `Page.index` and keep the current page id.
  It goes in an extension file because `document.dart` is already 866 lines.
- `packages/drawing_core/lib/src/models/models.dart`: export the new file.
- `packages/drawing_ui/lib/src/providers/page_structure_actions.dart` (new):
  `PageStructureActions` + `pageStructureActionsProvider`, which owns move/delete/restore.
- `packages/drawing_ui/lib/src/providers/page_trash_callback_provider.dart`:
  `PageTrashCallback` now returns `Future<String?>` (the trash entry id). Add a
  `PageTrashDiscardCallback` and its provider.
- `packages/drawing_ui/lib/src/providers/providers.dart`: export the new provider.
- `packages/drawing_ui/lib/src/screens/page_sidebar_reorder.dart` (new):
  `ReorderablePageCell` (`LongPressDraggable<int>` + `DragTarget<int>` around `PageGridItem`).
- `packages/drawing_ui/lib/src/screens/page_sidebar.dart`: when the filter is
  `allPages`, wrap page cells in `ReorderablePageCell`. Add edge auto-scroll while dragging.
- `packages/drawing_ui/lib/src/panels/page_options_panel.dart` (531 lines): `_deletePage`
  delegates to the actions class and shows the undo SnackBar. Move the action handlers
  into `page_options_actions.dart` (new, a mixin on the State) so both files stay <= 300.
- `packages/drawing_ui/lib/src/providers/page_provider.dart`: delete the unused
  `reorderPage`, or mark it `@Deprecated`. `pageManager` is synced from the document.
- `example_app/lib/features/documents/domain/repositories/page_trash_repository.dart`
  and `.../data/repositories/page_trash_repository_impl.dart`: `movePageToTrash`
  returns the new trash id (`Future<String>`).
- `example_app/.../providers/documents_controller_page_trash.dart`: returns `String?`
  (null on failure).
- `example_app/.../editor/presentation/screens/editor_screen.dart`: the trash callback
  returns the id. Register a discard callback that calls `permanentlyDeletePage`, and
  invalidate it on dispose (line 148).

## 3. Design
Pure ops (drawing_core, no Flutter):
```dart
extension DocumentPageOps on DrawingDocument {
  DrawingDocument movePage(int from, int to);        // clamps; no-op if equal/out of range
  DrawingDocument insertPageAt(int index, Page page); // clamps index to [0, length]
}
```
Both keep `currentPageIndex` pointing at the same page id and re-number `index` with
`copyWith(index: i)`. `page_thumbnail.dart:191` shows `page.index + 1`, so stale
indexes would show up on screen. Also re-number inside `removePage` (small fix in
`document.dart`, a few lines).

State ownership: `documentProvider` is the single source of truth.
`pageManagerProvider` is synced afterwards with `initializeFromDocument`, the same way
existing panel code does it. The data flow:
`ReorderablePageCell.onAccept(from,to)` -> `PageStructureActions.movePage` ->
`documentNotifier.updateDocument(doc.movePage)` -> pageManager sync -> the editor's
`documentProvider` listener -> autosave (persistence costs nothing extra).

```dart
class DeletedPage { final Page page; final int index; final bool wasCurrent; final String? trashId; }
class PageStructureActions {
  void movePage(int from, int to);
  Future<DeletedPage?> deletePage(int index);   // null when it's the last page
  Future<void> restorePage(DeletedPage d);      // insertPageAt + select if wasCurrent + discard(trashId)
}
```
Undo is a SnackBar action only. It is not a `HistoryManager` command (see section 6).
The panel grabs `ScaffoldMessenger.of(context)` before `onClose()`, because the popover
context goes away. It calls `hideCurrentSnackBar()` first: a second delete makes the
first one final. Restore keeps the original page id, so #150's `_onPage` lookup finds
the page again and the skipped entries come back by themselves.

Drag UX (spec from `ui-designer`; tokens only, no hardcoded colors):
- Uses `LongPressDraggable` with `hapticFeedbackOnStart`.
- The drag feedback is the thumbnail at cell size with the chrome shadow.
- The source cell is shown at reduced opacity.
- The hovered target gets an accent ring.
- Drop means "take the target's slot" (move semantics, as in `List.removeAt` + `insert`).
- Drag is off under the bookmarks filter (the indexes there are not contiguous).
- The add cell is not a drop target.
- Tap, bookmark and "..." keep working: they are tap gestures and do not clash with
  long-press.
- Auto-scroll: `EdgeDraggingAutoScroller` on the grid's `Scrollable`.

Layer rules: none bent. drawing_ui still does not import example_app. The trash link
still goes through the callback providers.
Public API change: the `PageTrashCallback` return type. It has one caller
(example_app), which is updated in the same PR.

## 4. Test plan
- drawing_core `test/models/document_page_ops_test.dart`:
  - `movePage` 2->0 gives ids [p2,p0,p1,p3]; indexes re-numbered; current id kept.
  - Out-of-range calls are a no-op.
  - `insertPageAt` clamps the index.
  - `toJson`/`fromJson` round-trip keeps the new order (AC1 persistence).
- drawing_core `test/history/history_manager_test.dart` (extend):
  - A stroke on p2, then `movePage(2,0)`, then undo: the stroke is removed from p2,
    which is now at index 0.
  - Delete p2, then undo: skipped. `insertPageAt` p2, then redo/undo works on p2 (AC3).
- drawing_ui `test/screens/page_sidebar_reorder_test.dart`:
  - 4 pages, current = p1. Long-press thumbnail "3" (`startGesture`, pump
    `kLongPressTimeout`), move to cell "1", release. Expect doc + pageManager order
    [p2,p0,p1,p3], current page id p1, labels 1..4.
  - The same test for `PageSidebarVariant.drawer`.
  - Under the bookmarks filter no draggable exists.
  - A tap still navigates.
- drawing_ui `test/panels/page_options_panel_delete_test.dart`:
  - 3 pages: delete index 1 -> 2 pages and SnackBar "Geri al".
  - Tap "Geri al" -> 3 pages, same id at index 1, layers equal, current restored.
  - Trash callback called once; discard called with the returned id.
  - The last-page guard snackbar is unchanged.
- drawing_ui `test/providers/page_structure_actions_test.dart`: actions plus #150
  history (execute stroke via `historyManagerProvider` on p2, move, undo).
- example_app `documents_controller_page_trash_test.dart`: `movePageToTrash` returns
  the id; null on a repo failure.
- Golden (design-loop): sidebar during drag (lifted cell + target ring), light/dark,
  rendered in CI and reviewed by `ui-designer`.

## 5. Task breakdown (one implementer run each)
1. Core page ops (TDD): `document_page_ops.dart`, `removePage` re-numbering, export,
   tests. Verify: `./scripts/check.sh analyze && cd packages/drawing_core && dart test test/models test/history`.
2. Trash id plumbing:
   - typedef change and discard provider in drawing_ui;
   - repo/controller return the id;
   - editor wiring and its test.
   Verify: `./scripts/check.sh analyze && ./scripts/check.sh test example_app`.
3. `PageStructureActions` + provider test (including the history case).
   Verify: `cd packages/drawing_ui && flutter test test/providers/page_structure_actions_test.dart`.
4. Split `page_options_panel.dart` (move handlers into a mixin, no behaviour change),
   then the delete + "Geri al" SnackBar and its test.
   Verify: `flutter test test/panels/` (the existing clear test must still pass).
5. `ui-designer` writes a short spec for the drag states (feedback, source, target ring).
6. `ReorderablePageCell` + sidebar wiring + auto-scroll + reorder widget tests;
   `page_sidebar.dart` stays <= 300.
   Verify: `flutter test test/screens/page_sidebar_reorder_test.dart test/screens/page_sidebar_test.dart test/screens/drawing_screen_sidebar_host_test.dart`.
7. Golden for the drag state, CI render, review, fixes.
   Verify: the update-goldens workflow, then `./scripts/check.sh test drawing_ui`.

## 6. Risks and left out (YAGNI)
- Phone drawer: a long-press drag inside the drawer could be read as a dismiss swipe.
  Covered by the drawer test; if it clashes, block drawer dismiss while dragging.
- `ThumbnailCache` keys: check that they are page-id based. Index-keyed caches would
  show stale images after a reorder (step 6, read `thumbnail_cache.dart`).
- The app could be killed while the SnackBar is showing. The page is already in the
  trash and the doc is autosaved, so nothing is lost. Undo is gone, but the trash still
  works as recovery.
- PDF-backed pages: the move keeps the `Page` object (including its PDF background
  reference), so PDF export follows the new order. Add one assertion in step 1.
- Left out:
  - page structure ops as `HistoryManager` commands (toolbar undo for reorder/add/delete);
  - multi-select move;
  - reorder in a full-screen page overview;
  - showing the sidebar for 1-page docs (`drawing_screen.dart:311`; reorder needs >= 2
    pages);
  - adding history to add/duplicate/paste (they keep new ids, so #150 history is not
    affected).

## 7. Reference check
- GoodNotes: in the side menu, long-press a page thumbnail and drag it to a new spot.
  Multi-page moves go through Select Pages (support.goodnotes.com). Deleted pages go to
  a trash.
- Flexcil and StarNote: the issue author says both reorder by dragging thumbnails in
  the page overview and allow undoing a page delete. My search found no official docs
  to confirm the exact undo surface.
- What we do: long-press drag in the existing thumbnail sidebar/drawer (the shared
  pattern). Delete undo is an immediate SnackBar "Geri al", on top of our existing page
  trash.
- Deviation: undo for structural edits is not on the toolbar undo stack in v1.0. Mixing
  page-structure commands into the per-page #150 history is a new design and outside
  v1.0 scope. The SnackBar plus the trash cover recovery.
