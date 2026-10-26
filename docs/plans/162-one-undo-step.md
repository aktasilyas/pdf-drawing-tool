# Plan: one undo step per eraser gesture and per paste (#162)

## Problem
- One stroke-eraser gesture pushes 1 + N + M commands (strokes, each shape,
  each sticky-note update); pixel and lasso gestures likewise
  (`eraser_gestures.dart`, `pixel_eraser_gestures.dart`, `note_eraser_gestures.dart`).
- Pasting N elements pushes N commands (`selection_actions_provider.dart`).
- No composite command exists in `drawing_core/lib/src/history/`.
- Pasted shape ids come from `microsecondsSinceEpoch` in a tight loop and can
  collide (so can the other `*.create` factories).

## Design
1. `CompositeCommand` (drawing_core): runs commands in order, undoes them in
   reverse order.
2. `HistoryManager.beginGroup()` / `endGroup()`: commands still execute
   immediately (later eraser commands read the state the earlier ones left,
   e.g. successive sticky-note updates), but are recorded as one
   `CompositeCommand` entry on the page of the first command. Nested groups
   record at the outermost end; empty groups record nothing; a single
   command is recorded as itself. `HistoryNotifier.runBatch(body)` wraps it.
3. The eraser pointer-up commit (all three modes) runs inside `runBatch`.
4. Paste moves to `providers/selection_paste.dart` (shrinks the 651-line
   `selection_actions_provider.dart`): `buildPasteCommand` returns one
   `CompositeCommand` for the whole clipboard.
5. `ElementIds.next()` (drawing_core): the same numeric timestamp format (so
   sorting by id keeps creation order), but strictly increasing, so ids made
   in the same microsecond never collide. Used by the `Stroke`, `Shape`,
   `ImageElement`, `TextElement` and `StickyNote` factories and by paste.

## Tests
- `drawing_core/test/history/composite_command_test.dart`: composite
  order, grouped eraser-like gesture = one step (undo + redo), empty/single/
  nested groups, grouped step undone on its page after navigation,
  `ElementIds` uniqueness.
- `drawing_ui/test/canvas/pixel_eraser_gestures_test.dart`: a real pixel
  eraser gesture over a stroke and a shape raises `undoCount` by exactly 1.
- `drawing_ui/test/providers/selection_paste_test.dart`: paste of 41
  elements = one step, unique ids, offset applied.

## Reference check
GoodNotes, Flexcil and StarNote undo an erase gesture or a paste in one step
→ same.
