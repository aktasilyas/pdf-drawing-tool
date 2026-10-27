# Plan: split floating_pen_box.dart (#266)

Pure refactor + tests; rendering and public API unchanged.

1. **Baseline golden first** — `test/golden/floating_pen_box_golden_test.dart`
   (column + row layout, light + dark) rendered in CI against the *old* widget,
   so the refactor is proven pixel-identical by the same golden.
2. **Decisions out of the widget** — `providers/pen_box_actions.dart`:
   `penBoxEditorPanelFor` (highlighter kinds share a panel),
   `penBoxOpensHorizontally` (row near the top, away from edges) and
   `PenBoxActions` (`selectPreset`, `openEditor`, `deletePreset`) behind
   `penBoxActionsProvider`, following `pageStructureActionsProvider`.
   Unit tests in `test/providers/pen_box_actions_test.dart`.
3. **Split the widget** (each < 300 lines):
   - `floating_pen_box.dart` — shell: decoration, expand/edit state, drag.
   - `floating_pen_box_slot.dart` — one `FloatingPenBoxSlot` parameterised by
     the box axis (replaces the duplicated vertical/horizontal slot classes).
   - `floating_pen_box_controls.dart` — collapsed badge + edit/collapse bar.
   Literals that sit on the grid become `ChromeSpacing`/`ChromeRadius`/
   `ChromeDurations` tokens; existing `Colors.white` badge glyphs move as-is.
4. **Widget tests** — `test/widgets/floating_pen_box_test.dart`: tap activates,
   double-tap opens the editor, edit mode deletes and ignores taps, column and
   row layouts, ≥ 48dp slots, collapse/expand, drag of the collapsed box.
5. Verify in CI (no local SDK): goldens unchanged, analyze + tests green.
