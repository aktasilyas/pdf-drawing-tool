# #432 — Selection follows undo/redo and page changes

Reference check (from the issue): GoodNotes, StarNote and Flexcil keep the lasso
tied to the selected objects through undo and drop it when leaving the page → same.

## Steps
1. `providers/selection_sync.dart`: `reconcileSelection(before, after, selection)`
   returns the same selection when nothing it points at changed, a rectangle
   selection of the surviving elements with fresh bounds otherwise, or `null`
   (no element left, page or layer changed). `liveSelection(doc, s)` is the
   same check against one document.
2. `HistoryNotifier.undo/redo` run the reconcile and set/clear the selection.
3. `selectionProvider` clears itself when the current page id changes in the
   page manager or the document; `selectionUiProvider` resets when the
   selection is cleared (menu/live transform never outlive it).
4. Delete / duplicate / reorder / colour and the handles' move/rotate/scale
   commit go through `liveSelection` and record nothing for a stale selection.
5. Widget tests in `test/widgets/selection_history_sync_test.dart`.
