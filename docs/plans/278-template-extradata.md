# Plan #278: carry template extraData onto pages

Issue: https://github.com/aktasilyas/pdf-drawing-tool/issues/278
Branch: `claude/278-template-extradata`

## Problem
`Template.extraData` (engineer pad margin, copperplate zones, Cornell ratios, planner
hours, etc.) only reaches `TemplatePatternPainter.fromTemplate` (picker preview).
`PageBackground` has no field for it, so pages, their JSON and all three canvas
painters drop it, and the page does not look like the template the user picked. Also:
Cornell reads `marginLeft`/`marginBottom` (absolute, `as double?`) while the registry
defines `leftMarginRatio`/`bottomSummaryRatio`, and the picture cache key in
`PageBackgroundPatternPainter` ignores `templateLineWidth`.

## Acceptance criteria (from the issue)
1. `PageBackground.templateExtraData` (immutable, JSON-safe) with `copyWith`, `==`/`hashCode`,
   `toJson`/`fromJson`; old JSON without the key still loads.
2. All 5 call sites copy `template.extraData`.
3. All 3 background painters pass it to `TemplatePatternPainter`; cache key includes
   `templateLineWidth` and the extra data.
4. Cornell reads the ratio keys, falls back to absolute keys, then to defaults.
5. Parity tests (engineer pad, copperplate) + model round-trip tests; analyze, tests and
   coverage floors green. No file over 300 lines (`page_background_painter.dart` is 324).

## Design
- **drawing_core `PageBackground`**: new `final Map<String, dynamic>? templateExtraData`.
  - New factory `PageBackground.fromTemplate(Template t, {int? color, int? lineColor})`
    sets type/pattern/spacing/lineWidth/extraData; defaults to `t.defaultBackgroundColor`
    and `t.defaultLineColor`. All 5 call sites use it, so the mapping exists in one place.
  - Immutability: the factory and `fromJson` wrap the map with `Map.unmodifiable`
    (nested lists in the registry are already `const`/final). The const constructor
    stays as it is (the `blank`/`grid` constants need it).
  - `toJson` writes `'templateExtraData'` only when non-null and non-empty; `fromJson` reads it
    with `(json['templateExtraData'] as Map?)?.cast<String, dynamic>()`. Missing key gives null.
  - `==`/`hashCode` (new; the class currently has identity equality): value equality over all
    fields; `templateExtraData` uses deep JSON equality; `pdfData` uses identity
    (no byte compare of large images). Helper `jsonDeepEquals`/`jsonDeepHash` lives in
    the new file `drawing_core/lib/src/models/json_value_equality.dart`. It is not exported
    from the barrel and adds no `collection` dependency.
  - Side effect: `Page ==` and the painters' `shouldRepaint` become value-based. That is intended
    and fixes repaints after JSON reload.
- **drawing_ui `TemplatePatternPainter`**: new factory
  `TemplatePatternPainter.fromBackground(PageBackground bg, {required Color lineColor,
  required Size pageSize, double lineWidthScale = 1})`. It requires `bg.templatePattern != null`
  (assert; callers already guard). It sets `backgroundColor: Colors.transparent` and
  `extraData: bg.templateExtraData`. `PageBackgroundPatternPainter`, `DynamicBackgroundPainter`
  and `InfiniteBackgroundPainter` (scale = zoom) switch to it, so the template field mapping
  for painters also lives in one place.
- **Cache key**: append `${templateLineWidth}_${templateExtraData}`. Map `toString` is
  deterministic per insertion order. Equal maps with a different order only miss the cache,
  they never collide.
- **Cornell** (`template_basic_painters.dart`): `left = ratio('leftMarginRatio') * w ??
  num('marginLeft') ?? 0.3 * w`, same for bottom (default 0.2). Use `as num?` everywhere
  (JSON ints). The picker preview also changes slightly (0.28/0.25 instead of 0.3/0.2).
  That is intended: preview and page now both follow the registry.
- **File split**: move `PageBackgroundView` (lines 256-324) into
  `canvas/page_background_view.dart`. Export it from `canvas/canvas.dart`. Update imports in
  `drawing_canvas.dart` (part `page_layers.dart`), `secondary_canvas_layers.dart` and
  `screens/drawing_screen_add_page_preview.dart`. The painter file drops to about 260 lines.
- Layer rules respected: `Template` and `PageBackground` both live in drawing_core (no Flutter).
  The painter factory stays in drawing_ui. example_app only calls the core factory.

## Affected files
- `packages/drawing_core/lib/src/models/page_background.dart`: field, factory, copyWith, ==, JSON (stays under 300 lines).
- `packages/drawing_core/lib/src/models/json_value_equality.dart` (new): deep equality and hash.
- `packages/drawing_core/test/models/page_background_test.dart`: round-trip, legacy JSON, equality.
- `packages/drawing_ui/lib/src/painters/template_pattern_painter.dart`: `fromBackground` factory.
- `packages/drawing_ui/lib/src/painters/template_basic_painters.dart`: Cornell keys, `num` casts.
- `packages/drawing_ui/lib/src/canvas/page_background_painter.dart`: use factory, cache key, split.
- `packages/drawing_ui/lib/src/canvas/page_background_view.dart` (new): moved widget.
- `packages/drawing_ui/lib/src/canvas/{canvas.dart,drawing_canvas.dart,secondary_canvas_layers.dart}`, `screens/drawing_screen_add_page_preview.dart`: imports/export.
- `packages/drawing_ui/lib/src/canvas/{drawing_canvas_painters,infinite_background_painter}.dart`: use factory.
- `packages/drawing_ui/lib/src/panels/add_page_panel.dart` (301 lines, 2 sites): use `PageBackground.fromTemplate`, which also brings it under 300.
- `packages/drawing_ui/lib/src/panels/page_options_template_actions.dart`: use the core factory. `templateChanged` also compares `t.extraData` with `bg.templateExtraData` (engineer pad and small grid share a pattern).
- `packages/drawing_ui/lib/src/screens/drawing_screen_navigation.dart`: thin_lined fallback uses the factory (the template branch already returns `bg`).
- `packages/drawing_ui/lib/src/panels/infinite_background_panel.dart`: `_applyColor` keeps `templateExtraData: bg.templateExtraData`. One-line change. The file is 425 lines, see Risks.
- `example_app/lib/features/editor/domain/usecases/load_document_usecase.dart`: use the factory.

## Test plan
- Core (`dart test`): fromTemplate copies extraData; toJson -> jsonEncode -> jsonDecode ->
  fromJson round-trip equality (engineer pad, copperplate, vocabulary with list); legacy JSON
  without the key gives null; empty map not serialized; == / hashCode deep (different instances,
  same content); copyWith keeps/replaces extraData; map is unmodifiable.
- drawing_ui `test/canvas/page_background_template_parity_test.dart` (new). For `engineer_pad` and
  `calligraphy_copperplate` at 595x842, the `PageBackgroundPatternPainter(background:
  PageBackground.fromTemplate(t))` image matches the `TemplatePatternPainter.fromTemplate(t,
  lineColor: Color(t.defaultLineColor), backgroundColor: transparent)` image byte for byte
  (record -> `toImage` -> `toByteData(rawRgba)`). It also matches after a JSON round-trip.
  Negative control: the same background without extraData produces different bytes.
- Same file: `DynamicBackgroundPainter` and `InfiniteBackgroundPainter` (zoom 1, offset 0) differ
  between with and without extraData, which proves the data reaches the painter.
- Cache: two backgrounds that differ only in `templateLineWidth` (then only in extraData) produce
  different images from `PageBackgroundPatternPainter`.
- `test/painters/template_pattern_painter_test.dart`: `fromBackground` maps all fields and scales
  lineWidth. Cornell pixel probe: with `leftMarginRatio: 0.28` a line pixel at x=0.28w and none at 0.3w.
  The fallback absolute int `marginLeft: 100` does not throw.
- example_app `load_document_usecase_test.dart`: template `engineer_pad` gives a page background
  whose `templateExtraData` equals `{showMarginLeft: true, marginMm: 25}`.
- Panels: one widget test in `test/panels/` that `page_options` / add-page from a template stores
  extraData (via `documentProvider` state). Only if harness exists; otherwise the factory
  test covers the mapping.

## Steps (one implementer run each)
1. **Core model (TDD).** Write the failing tests in `page_background_test.dart`, then add
   `json_value_equality.dart`, the field, `fromTemplate`, copyWith, JSON and ==/hashCode.
   Verify: `cd packages/drawing_core && dart test test/models/page_background_test.dart && dart analyze`.
2. **Split.** Move `PageBackgroundView` to `page_background_view.dart`, fix imports/export.
   No behaviour change. Verify: `./scripts/check.sh analyze` and `cd packages/drawing_ui && flutter test test/canvas`.
3. **Painter factory + Cornell (TDD).** Tests in `template_pattern_painter_test.dart` first, then
   `fromBackground` and the Cornell keys/casts. Verify: `flutter test test/painters`.
4. **Wire the 3 painters + cache key (TDD).** Write `page_background_template_parity_test.dart`
   (it fails first), then switch the painters to `fromBackground` and extend the key.
   Verify: `flutter test test/canvas test/canvas_dark_mode_test.dart`.
5. **Call sites in drawing_ui.** add_page_panel, page_options_template_actions,
   drawing_screen_navigation, infinite_background_panel. Verify: `cd packages/drawing_ui && flutter test`.
6. **example_app call site.** Test first in `load_document_usecase_test.dart`, then the use case.
   Verify: `cd example_app && flutter test test/features/editor`.
7. **Gate.** `./scripts/check.sh analyze && ./scripts/check.sh test`, then
   `COVERAGE=1 ./scripts/check.sh test packages/drawing_core && ./scripts/coverage.sh packages/drawing_core`
   (same for drawing_ui). Check `wc -l` on every touched file.

## Risks
- Value `==` on `PageBackground` changes `Page ==`. Anything that relied on identity to force an
  update would now skip it. Mitigation: full drawing_ui + example_app suites in step 7, and the
  E2E workflow runs on the PR (it touches example_app/lib).
- Existing documents saved before this change have no extraData and keep rendering as before.
  There is no migration, because the template id is not stored on the page (see YAGNI).
- `infinite_background_panel.dart` is already 425 lines. It gets a one-line change here; the split
  is left to a follow-up issue so this PR stays focused.
- Byte-exact parity can vary across Skia backends. Both images come from the same engine in
  one process, so they should match. If they flake, compare with a tolerance of 0 differing
  pixels in the margin column instead.

## Left out (YAGNI / follow-ups to file)
- Storing `templateId` on the page and backfilling extraData for old documents.
- `pdf_content_painter.dart` exports every template as a plain grid, and `thumbnail_generator.dart`
  hand-rolls patterns, so neither uses extraData. These are separate issues (PDF export
  fidelity, thumbnail parity) and should reuse `fromBackground` there.
- `page_options_template_actions` resolves the "current template" by pattern `firstOrNull`.
  Matching it by extraData/id belongs with the templateId follow-up.
- No UI to edit extraData (margin width etc.).

## Reference check
- GoodNotes: "Change Template" applies the chosen library template (with color/size/orientation)
  to the page, and the page renders as the picker thumbnail, including Cornell variants
  ([help](https://support.goodnotes.com/hc/en-us/articles/7353743758991-Change-a-page-template-in-Goodnotes),
  [Cornell](https://www.goodnotes.com/templates/cornell-notes)).
- StarNote / Flexcil: the template gallery thumbnail is the same artwork/geometry the new page
  gets. Neither shows a preview that differs from the result.
- What we do: preview and page are fed by the same data (`Template.extraData` copied into
  `PageBackground` and drawn by the same painter). This follows the shared pattern; no deviation.
