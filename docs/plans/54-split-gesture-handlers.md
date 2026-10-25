# Plan #54: split `drawing_canvas_gesture_handlers.dart`

## 1. Problem and acceptance criteria
`packages/drawing_ui/lib/src/canvas/drawing_canvas_gesture_handlers.dart` is 2267 lines: one mixin
holding every pointer, tool and scale handler. Split it by tool/gesture responsibility, behaviour-preserving.
- AC1: every resulting file is < 300 lines (`wc -l`); no method body changes other than the
  extract-method steps listed below (pure moves, plus call sites for the extracted helpers).
- AC2: no private member is renamed or made public; `DrawingCanvasState`'s public members unchanged.
- AC3: `./scripts/check.sh analyze` clean; `./scripts/check.sh test packages/drawing_ui` green,
  including the new characterization tests (step 0), which pass before and after the split.
- AC4: no `../` URIs; imports stay `package:`; no new `setState` in pointer paths (ink-engine rule).

## 2. Affected files
- `lib/src/canvas/drawing_canvas_gesture_handlers.dart`: becomes the library root: imports, `part`
  directives, the shared-state mixin `_GestureState`, and `abstract class DrawingCanvasGestureHandlers`.
- `lib/src/canvas/gestures/*.dart` (new, 13 `part of` files): one private mixin each (table in section 3).
- `lib/src/canvas/drawing_canvas.dart`: line 115-116 `extends ConsumerState<DrawingCanvas> with
  DrawingCanvasHelpers, DrawingCanvasGestureHandlers` becomes `extends DrawingCanvasGestureHandlers<DrawingCanvas>`;
  drop the helpers import if it is now unused.
- `test/canvas/drawing_canvas_gestures_test.dart` (new): characterization tests.

## 3. Design
**Decision: `part`/`part of` + private mixins, composed by one public abstract class.**
A mixin body cannot span files, so the split always means several mixins. Options:
- (a) Separate libraries with public mixins: about 20 shared private members (`_swipeDragActive`,
  `_longPressTimer`, `_longPressScreenPos`, `_isPointOnRuler`, `_snapToRuler`, `_clampToNote`,
  `_detectDrawingInsideNote`, `_add{Stroke,Shape}ToStickyNote`, `_minimizeAndDeselectNote`, `_selectText`,
  `_commitNoteErasures`, `_eraseInsideStickyNotes`, ...) would have to become public on the exported
  `DrawingCanvasState`. That widens the API, risks name clashes with the 1.5k-line state class, and puts
  12+ mixins in its `with` list.
- (b) Parts (chosen): library privacy covers all parts, so bodies move verbatim with zero renames.
  The private mixins are not visible from `drawing_canvas.dart`, so the library composes them itself:
```dart
abstract class DrawingCanvasGestureHandlers<T extends ConsumerStatefulWidget>
    extends ConsumerState<T>
    with DrawingCanvasHelpers<T>, _GestureState<T>, _RulerSnapping<T>, _StickyNoteGestures<T>,
        _TextGestures<T>, _PlacementGestures<T>, _SelectionGestures<T>, _ShapeGestures<T>,
        _StraightLineGestures<T>, _LaserGestures<T>, _NoteEraserGestures<T>, _PixelEraserGestures<T>,
        _EraserGestures<T>, _ScaleGestures<T>, _PointerDownGestures<T>, _PointerMoveUpGestures<T> {
  /// Minimum distance between points to avoid excessive point creation.
  static const double minPointDistance = 1.0;
}
```
Keeping the existing name means a one-line change in `drawing_canvas.dart`. Every private mixin is
`on ConsumerState<T>, DrawingCanvasHelpers<T>, _GestureState<T>` plus the mixins it calls (dependency
DAG below). The `with` order above is a valid topological order.
- `_GestureState` gets the abstract contract (lines 22-74, verbatim) and the shared fields
  `_swipeDragActive` (75), `_longPressTimer`, `_longPressScreenPos` (80-82).
- Static members are not inherited. `minPointDistance` moves to the abstract class and its two uses
  (lines 687, 1063) become `DrawingCanvasGestureHandlers.minPointDistance`. Its public qualified name does
  not change, and nothing outside the file references it. `_rulerSnapThreshold` stays in `_RulerSnapping`.
- Part URIs: root has `part 'gestures/<file>.dart';`; each part has
  `part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';` (no `../`). Parts
  hold no imports; the root keeps all imports. Fallback if the package-URI `part of` fails to resolve:
  flat files `lib/src/canvas/gesture_<x>.dart` with `part of 'drawing_canvas_gesture_handlers.dart';`.
- No change to state ownership or data flow: providers, `drawingController` and the history commands
  are touched exactly as before.

**Method to file mapping** (line ranges are in the current file; every path is under `lib/src/canvas/gestures/`):
| File (mixin) | Contents (current lines) | Calls into | ~lines |
|---|---|---|---|
| root `drawing_canvas_gesture_handlers.dart` | imports 1-16, parts, `_GestureState` 20-82, abstract class | - | 110 |
| `ruler_snapping.dart` (`_RulerSnapping`) | `_rulerSnapThreshold`, `_isPointOnRuler`, `_snapToRuler` 112-190 | - | 90 |
| `sticky_note_gestures.dart` (`_StickyNoteGestures`) | `_detectDrawingInsideNote`, `_clampToNote` 84-110; `_addStrokeToStickyNote`, `_addShapeToStickyNote` 192-267; `_minimizeAndDeselectNote` 1528-1540; NEW `_handleStickyNoteToolDown` (body 447-489) | - | 185 |
| `text_gestures.dart` (`_TextGestures`) | 1743-1873: `handleTextDown`, `finishTextEditing`, `cancelTextEditing`, `_selectText`, `handleTextStyleChanged`; NEW `bool _trySelectTextAt(PointerDownEvent)` (from 520-529 / 575-584) | - | 160 |
| `placement_gestures.dart` (`_PlacementGestures`) | `_handleStickerPlacement` 1875-1941, `_handleImagePlacement` 1943-2003; NEW `_handleImageToolDown` (body 495-515) | Text | 170 |
| `selection_gestures.dart` (`_SelectionGestures`) | 808-975: `handleSelection{Down,Move,Up}`, `_hitTestElementsAtPoint`; NEW `_handleSelectionToolDown` (body 380-415, long-press timer) | - | 220 |
| `shape_gestures.dart` (`_ShapeGestures`) | 1635-1741 `handleShape{Down,Move,Up}` | Sticky | 115 |
| `straight_line_gestures.dart` (`_StraightLineGestures`) | 977-1036 | Sticky, Ruler | 70 |
| `laser_gestures.dart` (`_LaserGestures`) | 1038-1080 | - | 55 |
| `note_eraser_gestures.dart` (`_NoteEraserGestures`) | `_eraseInsideStickyNotes`, `_pixelEraseNoteStrokes`, `_strokeEraseNoteStrokes` 1421-1526; `_commitNoteErasures` 1542-1627 (move the stray doc line 1527 with it); `_pointDist` 1629-1633 | - | 215 |
| `pixel_eraser_gestures.dart` (`_PixelEraserGestures`) | `handlePixelEraseAt` 1229-1292, `commitPixelErase` 1294-1333 | NoteEraser | 115 |
| `eraser_gestures.dart` (`_EraserGestures`) | `handleEraser{Down,Move,Up}` 1082-1227, `commitLassoErase` 1335-1364, `eraseAtPoint` 1366-1419 | Pixel, NoteEraser | 245 |
| `scale_gestures.dart` (`_ScaleGestures`) | 2009-2266: `handleScale{Start,Update,End}`, `_detectPageSwipe` (delete the empty header 2005-2008) | Text | 270 |
| `pointer_down_gestures.dart` (`_PointerDownGestures`) | `handlePointerDown` 273-613 minus the extracted blocks; NEW `_startFreehandStroke(event, toolType)` (587-612) | all | 220 |
| `pointer_move_up_gestures.dart` (`_PointerMoveUpGestures`) | `handlePointerMove`/`Up`/`Cancel` 615-806 | all | 200 |

**Extract-method rules** (the only edits that are not moves). Each extracted block is replaced by a
call, followed by the same `return` the inline code had:
- 379-416 becomes `if (isSelectionTool) { _handleSelectionToolDown(event); return; }`.
- 446-490 becomes `if (toolType == ToolType.stickyNote) { _handleStickyNoteToolDown(event); return; }`.
- 494-516 becomes `if (toolType == ToolType.image) { _handleImageToolDown(event); return; }`.
- 519-531 becomes `if (toolType == ToolType.sticker) { _trySelectTextAt(event); return; }`.
- 574-585 becomes `if (_trySelectTextAt(event)) return;`.
- 587-612 becomes `_startFreehandStroke(event, toolType);`. The `_isPointOnRuler` early return stays inside it.

## 4. Test plan
Current coverage of these handlers is close to zero. `test/canvas/drawing_canvas_test.dart`,
group 'Gesture Handling': 8 of its 10 pointer tests are `skip: true`. Only 'has Listener widget'
and 'pointer move does nothing when not drawing' run. `test/benchmark/*` drives
`DrawingController` and the painters directly, never the handlers. The other `test/canvas` files are
painter/controller unit tests.
Step 0 adds characterization tests in `test/canvas/drawing_canvas_gestures_test.dart`. They pump
`ProviderScope > MaterialApp > DrawingCanvas`, then call the public handlers on
`tester.state<DrawingCanvasState>` directly (this avoids the hit-test issue behind the skipped tests),
and assert on provider and document state:
1. Pen: down/move×3/up commits 1 stroke to the active layer; `lastPoint` is reset.
2. Cancel mid-stroke: no stroke committed, `drawingController.isDrawing == false`.
3. Stroke eraser: a stroke drawn, then erased across its path, leaves the layer empty.
4. Shape tool (rectangle): down/move/up adds 1 shape.
5. Highlighter in straight-line mode: the committed stroke has 2 points.
6. Selection tool: lasso around a stroke gives a non-null `selectionProvider`.
7. Text tool tap: `textToolProvider.isEditing` is true; `finishTextEditing()` ends it.
8. Scale: `handleScaleStart`/`Update(scale: 2)`/`End` changes `canvasTransformProvider.zoom`.
If a case cannot run headless, keep it out and record why in the test file. Do not use `skip:` to hide failures.
Commands: `cd packages/drawing_ui && flutter test test/canvas test/benchmark` (focused);
`./scripts/check.sh test packages/drawing_ui` (CI form; the benchmark-tagged tests run serially after the rest).

## 5. Task breakdown (one implementer run each; every step compiles and passes on its own)
Verify after every step (V):
`./scripts/check.sh analyze && (cd packages/drawing_ui && flutter test test/canvas test/benchmark)`.
0. **Characterization tests.** Add the test file from section 4 and confirm it passes on the unsplit
   code. Files: test only. V.
1. **Skeleton.** Turn the root into a library. Rename the current mixin body to `_PointerDownGestures`
   (the temporary remainder: everything except lines 22-82). Create `_GestureState` (22-82) and the
   abstract class (`with DrawingCanvasHelpers<T>, _GestureState<T>, _PointerDownGestures<T>`). Move
   `minPointDistance` and qualify lines 687 and 1063. Update `drawing_canvas.dart:115-116`. No new
   files yet. V.
2. **Leaves: ruler + sticky-note helpers.** Create `gestures/ruler_snapping.dart` and
   `gestures/sticky_note_gestures.dart` (without `_handleStickyNoteToolDown`). Add them to the `with`
   list before the remainder and add them to the remainder's `on` clause. V.
3. **Text + placement.** `text_gestures.dart` (add `_trySelectTextAt` and replace 519-531 and 574-585)
   and `placement_gestures.dart` (add `_handleImageToolDown` and replace 494-516). V.
4. **Selection, shape, straight line, laser.** Four files; extract `_handleSelectionToolDown`
   (379-416). V.
5. **Eraser trio.** Create note, then pixel, then eraser, in that order. V and `wc -l` on the three.
6. **Scale.** `scale_gestures.dart`; delete the empty header 2005-2008. V.
7. **Dispatch split.** Move the remainder into `pointer_down_gestures.dart` and
   `pointer_move_up_gestures.dart`. Extract `_handleStickyNoteToolDown` into the sticky file and
   `_startFreehandStroke`. The root keeps only imports, parts, `_GestureState` and the abstract class.
   V, then `wc -l lib/src/canvas/drawing_canvas_gesture_handlers.dart lib/src/canvas/gestures/*.dart`
   (all < 300).
8. **Final.** `./scripts/check.sh analyze && ./scripts/check.sh test packages/drawing_ui`. Check the
   coverage floor with `COVERAGE=1 ./scripts/check.sh test packages/drawing_ui && ./scripts/coverage.sh packages/drawing_ui`.
   Run `git diff --stat` to confirm that only the planned files changed.

## 6. Risks and deliberately left out
- Mixin linearization: the methods have no overrides or `super.` calls today, so order affects nothing
  except the `on` constraints. A wrong order is a compile error, not a silent change.
- The supertype of `DrawingCanvasState` changes from mixin to class. Nothing outside the file names
  `DrawingCanvasGestureHandlers` (grep), so there is no downstream impact.
- Package-URI `part of`: not verified in this session (the sandbox denied a scratch compile). The first part file (step 2)
  proves it; the flat-file fallback is in section 3.
- Coverage is thin. The step 0 tests cover the main dispatch paths, not every sticky-note/PDF-page edge.
  Reviewers should diff moved blocks with `git diff --color-moved=zebra`.
- Left out: splitting `drawing_canvas.dart` (1.5k, separate issue), un-skipping the 8 legacy tests,
  refactoring the logic (the `(localPosition - offset) / zoom` duplication, provider reads), Dart
  augmentations (not stable), and any ink-pipeline change.

## 7. Reference check
N/A: an internal refactor with no user-facing behaviour, data-model or file-format decision.
GoodNotes/StarNote/Flexcil were not consulted.
