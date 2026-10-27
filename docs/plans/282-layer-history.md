# Plan: #282 Undoable layer add / remove / reorder / duplicate

## Problem
`DocumentNotifier.addLayer/removeLayer/reorderLayers/duplicateLayer` set `state`
directly and bypass `HistoryManager`, so a mis-tap on the layer trash button loses
a layer for good. The only callers are in `screens/layers_list.dart` (352 lines,
no tests).

## Design
### drawing_core commands (`history/layer_commands.dart`)
They work on the current page's layers. `HistoryManager` records the page id and
makes that page current before undo/redo. `setCurrentPage` resets
`activeLayerIndex` to 0, so each command saves the active index and sets it
explicitly in both `execute` and `undo`. Inverses find layers by id. Snapshots are
not used, because a snapshot would revert rename/visibility/lock/opacity edits,
which stay outside history.

- `AddLayerCommand({layer, int? index})`: inserts at `index ?? length` and makes
  the new layer active; undo removes it by id and restores the active index.
  Duplicate uses this command with a pre-built copy (`description: 'Duplicate layer'`).
- `RemoveLayerCommand({layerIndex})`: no-op for the last layer or a bad index.
  Saves the layer (all content), its index and the active index; undo re-inserts it.
- `ReorderLayersCommand({oldIndex, newIndex})`: remove-then-insert semantics. The
  active index follows the active layer's id, both ways.
- Helper `DrawingDocument.withLayers(layers, activeLayerIndex:)` in
  `document_layer_ops.dart`, which hides the V1/V2 branching.

### drawing_ui routing
- `LayerActions(Ref)` + `layerActionsProvider` (same pattern as
  `PageStructureActions`): `add`, `remove`, `reorder`, `duplicate`.
- Each method validates first, so a no-op records no history entry. It then calls
  `historyManagerProvider.notifier.execute`.
- The four direct `DocumentNotifier` methods are deleted, so nothing can bypass
  history. This replaces the AC wording "DocumentNotifier methods execute through
  history" with the same intent and no provider cycle.
- Rename, visibility, lock, opacity and active layer stay on `DocumentNotifier`
  and are not undoable. This is view/meta state, the same as in paint apps.

### Split of `layers_list.dart`
- `layers_list.dart`: list + reorder.
- `layers/layer_list_header.dart`: header, 48dp.
- `layers/layer_row.dart`: row, rename field, icon toggles.
- `layers/layer_footer.dart`: opacity slider, delete/duplicate; the slider row
  becomes 48dp.

Spacing comes from `AppSpacing`. Stable `ValueKey`s are added for tests.

## Tests
- `drawing_core/test/history/layer_commands_test.dart`: execute/undo/redo on V1 and
  V2, active index, content restored, last layer kept, page switch between
  execute and undo.
- `drawing_ui/test/providers/layer_actions_test.dart`: one undo step per action, no
  entry for a no-op, duplicate active at index + 1.
- `drawing_ui/test/screens/layers_list_test.dart`: tap activates, delete + undo
  restores, visibility toggle, rename submit, controls ≥ 48dp.

## Reference check
GoodNotes has no user layers, and we could not confirm a layers panel in Flexcil or
StarNote. All three make destructive and structural edits undoable with the global
undo instead of confirm dialogs, so we do the same, with no new dialog.
