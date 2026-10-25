# Plan #55: split `drawing_canvas.dart`

## 1. Problem and acceptance criteria
`packages/drawing_ui/lib/src/canvas/drawing_canvas.dart` is 1550 lines. `DrawingCanvasState.build`
alone is 755 lines (679-1433). Split the file into part files, following the #54 pattern
(`docs/plans/54-split-gesture-handlers.md`). The split must not change behaviour.
- AC1: every resulting file is <= 300 lines (`wc -l`). Code moves verbatim. The only
  non-move edits are the ones listed in section 3 ("Allowed edits").
- AC2: public API unchanged. `DrawingCanvas` and its constructor, `DrawingCanvasState`, `drawingController`,
  `committedStrokes`, the exports in `canvas.dart` and `drawing_ui.dart`, and every public
  gesture handler stay as they are. No private member is renamed.
- AC3: the element tree is identical. The step 0 tree-dump fixtures match byte for byte before and
  after every step.
- AC4: `./scripts/check.sh analyze` is clean, and `./scripts/check.sh test packages/drawing_ui` is green
  (including `test/canvas/drawing_canvas_test.dart`, which counts RepaintBoundary/CustomPaint/Stack).
- AC5: no `../` URIs. Parts hold no imports. No new `setState`. No new allocation in any `paint()`.

## 2. Affected files (all under `packages/drawing_ui/`)
- `lib/src/canvas/drawing_canvas.dart`: becomes the library root. It keeps the imports, the `part`
  directives, `DrawingCanvas`, and a slim `DrawingCanvasState` (lifecycle plus a short `build`).
- `lib/src/canvas/drawing_canvas/*.dart` (new, 12 `part of` files): see the table in section 3.
- `test/canvas/drawing_canvas_tree_test.dart` and `test/canvas/fixtures/drawing_canvas_tree_*.txt` (new): characterization.
- Nothing else. `drawing_screen_layout.dart` and the gesture library stay untouched.

## 3. Design
**Decision: `part`/`part of` plus private mixins on `DrawingCanvasGestureHandlers<DrawingCanvas>`.**
This is the same reasoning as #54. Library privacy spans the parts, so `_renderer`, `_imageCacheManager`, `_isSelecting`
and the other private fields move with no renames. A public mixin library would force those fields onto the
exported state. Parts use `part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';`. #54 proved
this form resolves. The root holds every import, so no import is added or removed.
```dart
class DrawingCanvasState extends DrawingCanvasGestureHandlers<DrawingCanvas>
    with _CanvasFields, _GestureContract, _CanvasPageInit, _PdfBackground, _CanvasFrameReader,
        _CanvasPageLayers, _CanvasInkLayers, _CanvasSelectionLayers, _CanvasViewport,
        _StickyNoteMenu, _PlacementIndicators, _CanvasOverlays { ... }
```
Every mixin is `on DrawingCanvasGestureHandlers<DrawingCanvas>` plus the mixins it calls (listed in the
"on" column). This gives `ref`, `widget`, `context`, `mounted` and `setState` (protected access is legal from a
mixin on a State). The `with` order above is a valid topological order.

**Per-build snapshot `_CanvasFrame`.** The layer sub-trees read about 35 locals that `build` computes
(681-810). They are not passed as long parameter lists. Instead, `_readFrame()` returns one immutable
private value object, built once per `build`. Allocation in `build` is fine; the ink rule only forbids
allocation in `paint()`. Pubspec `sdk: >=3.0.0` means there is no private-field promotion, so **each helper starts
by copying the frame fields it uses into same-named locals** (`final selection = f.selection;`).
That way the moved body stays verbatim and null promotion (`selection != null` then `SelectionToolbar(selection: selection)`)
still works. Layout-time values (`size`, `effectiveTransform`) are passed as parameters.

**Contexts.** Helpers that call `Theme.of(context)` outside a nested `Builder`/`Consumer` take
`BuildContext context` as their first parameter. The caller passes the `LayoutBuilder` builder context,
so the lookup is done on the same element as today. `Builder`/`Consumer` wrappers move unchanged
(they define the element tree, so AC3 depends on it).

**Mapping** (current line numbers; files under `lib/src/canvas/drawing_canvas/`):
| File (mixin / type) | Contents | on (besides base) | ~lines |
|---|---|---|---|
| root `drawing_canvas.dart` | imports 1-40, parts, `DrawingCanvas` 52-108, `DrawingCanvasState`: doc 110-113, `committedStrokes` 245-248, `initState`/`didUpdateWidget`/`dispose` 250-274, slim `build` (see below) | - | 230 |
| `canvas_fields.dart` (`_CanvasFields`) | fields 121-130, 140-235; `_drawingInsideNote` 649, `_scaleStartFocalPoint` 656, `_scaleGestureIsZoom` 673 (with their doc lines) | - | 150 |
| `gesture_contract.dart` (`_GestureContract`) | `canvasMode` 115-117, `drawingController` 241-243, accessor overrides 559-677 minus the 3 fields above | Fields | 130 |
| `page_init.dart` (`_CanvasPageInit`) | 297-359 (`_initializeCanvasForLimitedMode`, `_isOrientationChanged`, `_isSignificantHeightChange`, `_isPageSizeChanged`); NEW `CanvasTransform _effectiveTransform(CanvasTransform transform, core.CanvasMode canvasMode, core.Page currentPage, Size size)` with body 826-853 + `return effectiveTransform;` | Fields | 105 |
| `pdf_background.dart` (`_PdfBackground`) | 361-556 (`_buildPdfBackground`, `_buildPdfLoading`, `_buildPdfPlaceholder`, `_buildPdfError`) | - | 205 |
| `canvas_frame.dart` (`class _CanvasFrame`) | final fields + const-free ctor for: allLayers, activeLayerIndex, activeLayerVisible, activeLayerOpacity, strokes, shapes, texts, images, elementOrder, transform, selection, selectionUi, textToolState, canvasMode, currentPage, colorScheme, eraserCursorPosition, lassoEraserPoints, isEraserTool, pixelEraserPreview, strokeEraserPreview, selectionPreviewPath, hasLiveTransform, excluded{Stroke,Shape,Image,Text}Ids, selected{Strokes,Shapes,Images,Texts}, previewShape, straightLinePreview{Points,Style}, stickyNotes, isTextTool, isStickyNoteTool, enablePointerEvents | - | 130 |
| `canvas_frame_reader.dart` (`_CanvasFrameReader`) | `_CanvasFrame _readFrame()`: body 681-708 + 725-810 verbatim, then `return _CanvasFrame(...)` | Fields | 160 |
| `ink_layers.dart` (`_CanvasInkLayers`) | top-level `_wrapOpacity` 46-50; `Widget _buildActiveLayerContent(f, size, effectiveTransform)` = 995-1062; `List<Widget> _buildLiveInkLayers(f, size)` = 1082-1117 (active stroke, laser, straight-line preview) | Fields | 140 |
| `page_layers.dart` (`_CanvasPageLayers`) | `List<Widget> _buildPageLayers(f)` = inner list of 899-976 | Pdf | 95 |
| `selection_layers.dart` (`_CanvasSelectionLayers`) | `List<Widget> _buildSelectionLayers(context, f, size)` = 1123-1176; `Widget _buildStickyNoteHandlesLayer(f)` = 1181-1208 | Fields | 110 |
| `canvas_viewport.dart` (`_CanvasViewport`) | `Widget _buildViewport(f, size, effectiveTransform)` = 871-1216 shell (Listener ... Transform > Stack). Children: `..._buildPageLayers`, passive-below loop 981-989 (inline), `if (activeLayerVisible) _buildActiveLayerContent(...)`, passive-above loop 1067-1075 (inline), `..._buildLiveInkLayers`, `..._buildSelectionLayers`, `_buildStickyNoteHandlesLayer` | PageLayers, Ink, Selection | 110 |
| `sticky_note_menu.dart` (`_StickyNoteMenu` + `class _StickyNoteContextMenu`) | `_handleStickyNoteDelete`/`ColorChange` 276-295; `Widget _buildStickyNoteMenu(f)` = 1241-1260; widget class 1440-1549 | - | 165 |
| `placement_indicators.dart` (`_PlacementIndicators`) | `Widget _buildStickerIndicator()` = 1294-1354; `Widget _buildImageIndicator()` = 1359-1418 | - | 135 |
| `canvas_overlays.dart` (`_CanvasOverlays`) | `List<Widget> _buildScreenOverlays(f)` in the original order: toolbar 1221-1225, paste 1230-1236, `_buildStickyNoteMenu(f)`, text input 1265-1275, style popup 1280-1289, `_buildStickerIndicator()`, `_buildImageIndicator()`, eraser cursor 1423-1428 | StickyMenu, Placement | 80 |

Root `build` after the split: `final f = _readFrame();` then `ref.listen` 710-723 unchanged (it stays in
`build`; listen and watch order has no effect in Riverpod). Locals: `canvasMode`, `currentPage`, `transform`, `enablePointerEvents`.
Then `LayoutBuilder` (size 814-819, init 821-824, `final effectiveTransform = _effectiveTransform(...)`)
returns `Stack(children: [surrounding area 863-868, _buildViewport(f, size, effectiveTransform), ..._buildScreenOverlays(f)])`.

**Allowed edits** (everything else is a move):
- Extract-method call sites as in the table. Each `if (cond) X` keeps its `cond` at the call site.
- The frame-local copy lines at the top of each helper.
- Delete the stray doc comments 136-137 ("Minimum distance...", which documents nothing) and 558
  ("Trigger high-quality render...", which sits on `pointerCount`). Delete the section banners that become empty.
- The `didUpdateWidget`/`dispose`/`initState` bodies do not change. `late final _drawingController` lives in
  `_CanvasFields` and is still assigned in `initState`.

No change to state ownership or data flow. The same providers are watched/read from the same elements.
The controllers, renderer and cache manager are still created once per State.

## 4. Test plan
Existing coverage: `drawing_canvas_test.dart` (structure counts in infinite mode, lifecycle),
`drawing_canvas_gestures_test.dart` and `pixel_eraser_gestures_test.dart` (handlers through `DrawingCanvasState`).
These do not cover limited mode, the PDF states, or the overlays. Step 0 adds
`test/canvas/drawing_canvas_tree_test.dart`. It pumps `ProviderScope > MaterialApp > Scaffold > DrawingCanvas`
(fixed 800x600 surface), walks the elements under `DrawingCanvas` (`visitChildElements`, one line per element:
indent + `widget.runtimeType`, with no keys or hashes, so it is deterministic), and compares the result with
`test/canvas/fixtures/drawing_canvas_tree_<scenario>.txt`. Run with `UPDATE_CANVAS_TREE=1` to (re)write the fixtures.
This is allowed only in step 0, on the unsplit code. Scenarios:
1. Infinite mode, default. 2. Limited mode (`CanvasMode(isInfinite: false)`), blank page.
3. Limited mode, PDF background with no data and no path (placeholder). 4. Sticker placement active.
5. Image placement active. 6. Eraser tool selected. 7. Sticky note selected with `showMenu` (menu +
handles). 8. Text editing active (`TextInputOverlay`). 9. Selection with `showMenu` (toolbar).
Set state through the notifiers after the first pump. If a scenario cannot run headless, drop it and
write the reason in the test file. Do not use `skip:`.
Commands: focused `cd packages/drawing_ui && flutter test test/canvas`; CI form
`./scripts/check.sh test packages/drawing_ui`. No golden is needed: the tree dump plus the existing
structure counts pin the output, and no pixel-level change is intended.

## 5. Task breakdown (one implementer run each; each step compiles and passes on its own)
V = `./scripts/check.sh analyze && (cd packages/drawing_ui && flutter test test/canvas)`. The fixtures
must be unchanged (`git diff --exit-code packages/drawing_ui/test/canvas/fixtures`).
0. **Characterization.** Add the tree test and fixtures (generated on the current code), plus `fixtures/README`
   (one line on regeneration). V.
1. **Library skeleton + state.** Add the `part` directives and create `canvas_fields.dart` and `gesture_contract.dart`.
   Add `with _CanvasFields, _GestureContract` and delete the stray docs. V.
2. **Init + PDF.** `page_init.dart` (including the `_effectiveTransform` extract; the LayoutBuilder calls it) and
   `pdf_background.dart`. V.
3. **Frame.** `canvas_frame.dart` and `canvas_frame_reader.dart`. The top of `build` becomes `final f = _readFrame();`
   plus local copies of every field that the rest of `build` still uses. The rest of `build` does not change. V.
4. **Ink layers.** `ink_layers.dart` (moves `_wrapOpacity`). V.
5. **Page + selection layers.** `page_layers.dart` and `selection_layers.dart`. V.
6. **Viewport.** `canvas_viewport.dart`. V.
7. **Overlays.** `sticky_note_menu.dart` (actions, builder, widget), `placement_indicators.dart`, `canvas_overlays.dart`.
   Trim the root `build` locals to the ones it still uses. V, then
   `wc -l lib/src/canvas/drawing_canvas.dart lib/src/canvas/drawing_canvas/*.dart` (all <= 300).
8. **Final.** `./scripts/check.sh analyze && ./scripts/check.sh test packages/drawing_ui`. Check the coverage floor with
   `COVERAGE=1 ./scripts/check.sh test packages/drawing_ui && ./scripts/coverage.sh packages/drawing_ui`.
   Run `git diff --stat` to confirm that only the planned files changed. Reviewers use `git diff --color-moved=zebra`.

## 6. Risks and deliberately left out
- Contexts: if a helper used the State `context` instead of the LayoutBuilder context, `Theme.of` would bind to a
  different element. The output would be the same, but the dependency would be wrong. The rule in section 3 prevents this. The tree dump
  does not see it, so the reviewer checks every `Theme.of(context)` call site.
- Frame drift: a field that is missed or copied wrong is a compile error or a fixture diff, not a silent change.
- Element tree: extracting methods never adds elements. Turning a `Builder` into a widget class would add one, and the tree
  test would catch it. Converting the Builders into ConsumerWidgets (narrower rebuilds) is therefore out of scope.
- `ref.listen` stays in `build`. Moving it into `_readFrame` would work but would hide a side effect in a "read".
- Left out (follow-up issues, not this PR): hardcoded colors and spacing (`Colors.white`, `Colors.black.withValues`,
  `EdgeInsets.all(16)`, `Colors.red` in the sticky menu), the 'PDF Sayfasi' and 'Yerlesirmek icin' strings (not localized,
  one has a typo), merging the duplicated sticker/image indicators into one widget, dropping `setState(() {})` in
  `SelectionHandles.onSelectionChanged`, and the 8 skipped legacy gesture tests.

## 7. Reference check
N/A. This is an internal refactor with no user-facing behaviour, data-model or file-format decision.
GoodNotes, StarNote and Flexcil were not consulted.
