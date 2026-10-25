# Plan: pen presets v2 (#45)

Milestone M1 Ink engine v2. Depends on #42 (round ends by default), #43 (incremental outline),
#44 (tiled cache). Scope: `packages/drawing_core`, `packages/drawing_ui`. No example_app change.

## 1. Problem and acceptance criteria
Today only `pressureSensitive` styles go through `StrokeOutline`, and
`VariableWidthStrokeRenderer.optionsFor` passes only `size` + `thinning`, so every stroke has round
ends (taper 0). There is no fountain pen in `drawing_core` (`PenType` has 9 legacy types; the toolbar
package already has `fountainPen`). The highlighter style is built in `tool_style_provider.dart` with
`DrawingBlendMode.normal`. The picker (`panels/pen_type_picker.dart`) shows pencil/ballpoint/dashed/
brush/ruler as Phosphor icons with hardcoded sizes.

AC (checkable):
- A1 `PenType.fountainPen` exists; `ToolType.fountainPen` maps to it and to `toolbar.PenType.fountainPen`.
- A2 Each preset produces a `StrokeStyle` that carries its outline tuning (`StrokeDynamics`: taperStart,
  taperEnd, streamline, velocityThinning). `optionsFor(style)` passes all of them to
  `StrokeOutlineOptions`. Fountain and brush have taperStart > 0 and taperEnd > 0 (scaled by thickness);
  ballpoint keeps round ends; old strokes (no dynamics in JSON) render exactly as today.
- A3 Committed render, live render (`ActiveStrokeGeometry`) and PDF vector export use the same routing
  predicate and the same options (parity test, <0.5% pixels differ by >8/255).
- A4 Highlighter strokes use `DrawingBlendMode.multiply`: black ink stays black (pixel = ink colour within
  8/255) whether it was drawn before or after the highlighter. PDF export sets a multiply graphic state.
- A5 Pencil preset renders through `PencilTextureRenderer` even when pressure is on (texture wins).
- A6 One committed golden per preset (fountain, ballpoint, brush, highlighter, pencil) from a shared
  reference stroke set, reviewed as PNGs.
- A7 Picker shows exactly five tiles in order fountain, ballpoint, brush, highlighter, pencil, each with a
  live preview drawn by the real renderer using that tool's current colour/thickness; tap selects the
  tool; selected state visible; touch targets >= 48dp; tokens + `AppSpacing` only. Widget test + golden
  (light/dark x phone/tablet).
- A8 Ink benchmark (1,000 strokes, fountain + brush mix): worst and p95 reported, no regression > 10% vs main.
- A9 `./scripts/check.sh analyze` and `test` pass; every touched file <= 300 lines.

## 2. Affected files
drawing_core:
- `lib/src/models/stroke_dynamics.dart` (new): immutable `StrokeDynamics` + JSON; exported from `stroke_style.dart`.
- `lib/src/models/stroke_style.dart`: new field `dynamics` (default `StrokeDynamics.none`), props, copyWith, JSON key omitted when none.
- `lib/src/models/pen_type.dart`: `fountainPen` (appended last), per-preset tuning in `PenTypeConfig`, highlighter multiply.
drawing_ui:
- `rendering/variable_width_renderer.dart`: `usesOutline(style)` predicate; `optionsFor` maps dynamics.
- `rendering/flutter_stroke_renderer.dart`: one routing order (texture -> outline -> stroked) in all three entry points.
- `rendering/active_stroke_geometry.dart`: `begin()` uses `usesOutline`.
- `services/pdf_content_painter.dart`: pressure branch -> `StrokeOutline.build(optionsFor(style))`; multiply graphic state.
- `services/vector_pdf_renderer.dart`, `utils/pen_type_mapper.dart`: exhaustive switches gain `fountainPen`.
- `models/tool_type.dart`, `toolbar/tool_groups.dart`, `screens/drawing_screen_panels.dart`: `ToolType.fountainPen`.
- `providers/tool_style_provider.dart`: `strokeStyleForToolProvider.family(ToolType)`; active = family(current);
  highlighter from `PenType.highlighter` config (multiply).
- `panels/pen_preset_preview.dart` (new): preview widget + painter. `panels/pen_type_picker.dart`: rewrite.
- `pubspec.yaml`: `alchemist` dev_dependency (first golden of a widget in this package).
- Tests: see section 4.

## 3. Design
```dart
class StrokeDynamics extends Equatable {            // drawing_core, pure Dart
  final double taperStart, taperEnd;                 // px, already scaled by thickness
  final double streamline;                           // default 0.5 (= today)
  final double velocityThinning;                     // default 0.2 (= today)
  static const none = StrokeDynamics();              // taper 0 => round ends
  bool get isNone; Map<String, dynamic> toJson(); factory fromJson(Map?);
}
// PenTypeConfig gains: taperStartFactor, taperEndFactor, streamline, velocityThinning, blendMode, usesOutline
// toStrokeStyle(): dynamics = StrokeDynamics(taperStart: factor * thickness, ...)
static bool usesOutline(StrokeStyle s) =>
    s.texture != StrokeTexture.pencil && (s.pressureSensitive || !s.dynamics.isNone);
static StrokeOutlineOptions optionsFor(StrokeStyle s) => StrokeOutlineOptions(size: s.thickness,
    thinning: s.pressureSensitive ? s.pressureSensitivity : 0, velocityThinning: d.velocityThinning,
    streamline: d.streamline, taperStart: d.taperStart, taperEnd: d.taperEnd);
```
Starting tuning (final values set in the golden step, by eye + ui-designer review):

| preset | pressure | thinning | velThin | streamline | taperStart | taperEnd | render |
|---|---|---|---|---|---|---|---|
| fountain | on | 0.55 | 0.25 | 0.45 | 1.5 w | 3 w | outline |
| ballpoint | off | 0 | 0.10 | 0.50 | 0 | 0 | outline (round ends, slight speed thinning) |
| brush | on | 0.90 | 0.35 | 0.55 | 2.5 w | 4 w | outline |
| highlighter | off | - | - | - | - | - | stroked, rectangle nib, opacity 0.4, multiply |
| pencil | user | - | - | - | - | - | `PencilTextureRenderer` |

- Why store tuning on the stroke (file format): re-tuning presets later must not change existing notes,
  and the PDF exporter/thumbnail renderer only see `Stroke`. Taper is stored in px so a later thickness
  edit on a selection keeps the shape (selection resize scales points, not taper; accepted for v1.0).
- Data flow: settings -> `strokeStyleForToolProvider(tool)` -> `PenType.toStrokeStyle` -> tool ->
  `Stroke.style` -> renderer (`usesOutline` + `optionsFor`) in committed, live, tile and PDF paths.
- State ownership: presets are const config in `drawing_core`; user overrides stay in
  `penSettingsProvider` (unchanged). The picker reads the family provider; previews own no state.
- Tiles: multiply strokes already force a tile re-raster (`SceneEntry.usesBlend`), so A4 holds in the cache.
- Preview: `PenPresetPreview(style)`; the painter builds its `Path`/outline in the constructor (no allocation
  in `paint()`), `shouldRepaint` compares `style` (Equatable). The preview curve is a private
  const in the preview file.
- Layer rules respected: drawing_core gets no Flutter import; drawing_ui does not import example_app.

## 4. Test plan
- core `test/models/stroke_dynamics_test.dart`: equality, JSON round trip, missing key -> none.
- core `test/models/stroke_style_test.dart`: dynamics in props/copyWith/JSON; legacy JSON unchanged.
- core `test/models/pen_type_test.dart`: per preset taper > 0 / == 0, taper scales with thickness, highlighter multiply.
- ui `test/rendering/variable_width_renderer_test.dart` (new): `optionsFor` maps every field; `usesOutline` table.
- ui `test/rendering/flutter_stroke_renderer_test.dart`: tapered stroke: pixel width at 2px from the end < 30%
  of mid width; pencil + pressure still textured; ballpoint ends round.
- ui `test/rendering/active_stroke_geometry_test.dart`: tapered style -> `ActiveStrokeMode.outline`; live vs committed parity.
- ui `test/services/pdf_content_painter_test.dart`: tapered stroke exports a filled outline; highlighter sets multiply.
- ui `test/golden/pen_presets_golden_test.dart` + `test/golden/reference_strokes.dart`: 5 PNGs
  (`pen_preset_<name>.png`), paper tint, reference set = slow S-curve with pressure ramp, fast flick, dot,
  handwriting zigzag; highlighter scene draws ink before AND after the highlighter. Same raw-canvas pattern as
  `tiled_layer_golden_test.dart` (no fonts, deterministic).
- ui `test/panels/pen_type_picker_test.dart` + `test/golden/pen_type_picker_golden_test.dart` (alchemist).
- ui `test/benchmark/ink_benchmark_test.dart`: fountain/brush section.

## 5. Steps (one implementer run each; <= 3 production files, tests extra)
1. StrokeDynamics model. Files: `stroke_dynamics.dart` (new), `stroke_style.dart`. If `stroke_style.dart`
   passes 300 lines, move the three factories to `stroke_style_factories.dart` as a static-extension file.
   Verify: `cd packages/drawing_core && dart test test/models/`.
2. Presets in core + fountain enum. Files: `pen_type.dart`, `pen_type_mapper.dart`, `vector_pdf_renderer.dart`
   (exhaustive switches). Verify: `dart test test/models/pen_type_test.dart` (core) and
   `flutter test test/utils/pen_type_mapper_test.dart` (ui).
3. Render routing. Files: `variable_width_renderer.dart`, `flutter_stroke_renderer.dart`.
   Verify: `flutter test test/rendering/`.
4. Live parity. Files: `active_stroke_geometry.dart`. Verify: `flutter test test/rendering/active_stroke_geometry_test.dart test/canvas/`.
5. ToolType.fountainPen. Files: `tool_type.dart`, `tool_groups.dart`, `drawing_screen_panels.dart`.
   Verify: `flutter test test/providers/ test/toolbar_professional_test.dart`.
6. Style family + highlighter multiply. Files: `tool_style_provider.dart` (+ barrel if needed).
   Verify: `flutter test test/providers/tool_style_provider_test.dart test/golden/tiled_layer_golden_test.dart`.
7. PDF export parity. Files: `pdf_content_painter.dart` (gets shorter). Verify: `flutter test test/services/ test/integration/pdf_workflow_test.dart`.
8. Preset goldens + tuning (design-loop round: Read PNGs, `ui-designer` review, max 3 rounds; tuning edits
   only in `pen_type.dart`). Files: `reference_strokes.dart`, `pen_presets_golden_test.dart`, `pen_type.dart`.
   Verify: `flutter test --update-goldens test/golden/pen_presets_golden_test.dart` then without the flag.
9. Picker spec: `ui-designer` writes `docs/specs/45-pen-picker.md` (tile anatomy, preview size, labels,
   selected state, tokens). No code.
10. Preview widget. Files: `pen_preset_preview.dart` (new), `panels.dart` barrel. Verify: `flutter test test/panels/pen_preset_preview_test.dart`.
11a. Picker rewrite + goldens. Files: `pen_type_picker.dart`, `pubspec.yaml` (alchemist). Verify:
    `flutter test test/panels/pen_type_picker_test.dart test/golden/pen_type_picker_golden_test.dart`, design-loop review.
11b. Picker integration (spec `docs/specs/45-pen-picker.md` section 12): picker becomes the type row of
    `PenSettingsPanel` (replaces `PenTypeSelector`), popover `maxWidth` 380, remove unused
    `penPickerModeProvider` path. Verify: `flutter test test/panels/ test/screens/`.
12. Benchmark + full check. Files: `ink_benchmark_test.dart`. Verify: `./scripts/check.sh analyze && ./scripts/check.sh test`, `scripts/ink_benchmark.sh`.

## 6. Risks and left out
- Live highlighter preview is in its own `RepaintBoundary` above the tiles, so multiply has nothing to blend with
  while drawing: ink under a live highlighter looks tinted, then snaps crisp at pen-up. Mitigation in step 6/8:
  measure; if visible, draw live multiply strokes at the committed opacity and accept the pop, or follow-up issue.
- On screen, multiply blends with ink in the same layer only, not with the PDF page/template (separate widget
  below). At 0.4 alpha PDF text stays readable but olive-tinted. PDF export does multiply against the page.
  See owner question Q2.
- Ballpoint moves from stroked path to outline fill: slightly more work per stroke (benchmark in step 12).
- Taper on a pixel-erased fragment: split fragments inherit tapers (each piece gets tapered ends). Accepted for
  v1.0; note in step 3 test as known behaviour.
- Left out (YAGNI): tip-sharpness slider, per-preset stabilisation UI, straight-line highlighter snapping,
  "highlighter behind ink" z-reordering (multiply already gives the look for dark ink), new pencil grain
  algorithm (keep current deterministic grain), removing legacy pen types, default-tool change.

## 7. Reference check
- GoodNotes: Pen tool has three types: fountain (pressure-sensitive), ball (constant width), brush (most
  pressure-responsive); highlighter is a separate tool; settings include tip sharpness and stabilisation.
- StarNote: store listing names fountain, ballpoint and highlighter pens with colour/thickness presets; the
  Android listing adds pencil.
- Flexcil: pen tool includes a fountain pen plus round/square/dotted/straight-line pens; the highlighter is
  tuned so it does not blur the text underneath.
- What we do: fountain/ballpoint/brush behave like GoodNotes (pressure none for ball, strongest for brush), pencil
  as in StarNote Android, highlighter translucent + multiply so ink and text stay readable (Flexcil/GoodNotes
  user expectations). Deviation: highlighter and pencil sit in the same picker as the pens (issue AC) instead of
  a separate tool. Reason: one place to choose ink on phones; the highlighter keeps its own tool group too.
  Own curves and icons; no copied assets.

## 8. Owner questions (needs-owner; work can start on steps 1-8 meanwhile)
- Q1 The picker drops dashed pen and ruler pen (and never showed gel/hard pencil/neon). They stay in the enum and
  in toolbar customization, and old strokes render. OK to remove them from the picker for v1.0?
- Q2 Is multiply against ink only (not against the PDF page on screen) acceptable for v1.0? A true on-screen
  multiply over PDF text needs the ink layer composited into the page picture (follow-up issue, more cost).
- Q3 Turkish label for fountain pen: "Dolma Kalem"? Highlighter in the pen picker: same label as the tool ("Fosforlu Kalem")?
