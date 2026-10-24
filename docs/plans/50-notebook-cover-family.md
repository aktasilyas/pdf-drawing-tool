# Plan: original procedural cover family (#50)

## Problem and acceptance criteria
The new-notebook flow offers a mix of flat colors, gradients and bitmap covers, some of which come
from third parties. Replace what the picker offers with an original procedural family (BRIEF.md
"Cover family"): Linen sage/sand/slate, Leather oxblood/cognac/navy, Kraft natural/charcoal,
Felt mustard/dusty rose. Each has a label plate in the paper-surface color with a serif title.
- AC1: 10 covers rendered by `CustomPainter` code only. No new image assets, no fragment shaders.
- AC2: Golden sheet of all 10 covers at 120dp and 240dp width (3:4), light and dark.
- AC3: `CoverGridView` (new-notebook flow) and the editor's change-cover picker list only the family.
  The default for new notebooks is `linen_sage`.
- AC4: Every coverId persisted before this change (Drift `documents.cover_id`,
  `PageBackground.coverId` in page JSON) still resolves and renders exactly as it does today.
- AC5: Thumbnails (`ThumbnailGenerator`) and the editor cover page (`PageBackgroundPainter`) render
  family covers the same way as the preview, with no asset loading.
- AC6: Rendering is deterministic, so goldens are stable: noise is seeded from the cover id and
  never comes from `String.hashCode` or wall-clock time.

## Affected files
drawing_core
- `lib/src/models/cover.dart`: add `CoverStyle.material` and the `CoverMaterial {linen, leather, kraft, felt}`
  field `material`, plus JSON. Unknown style values still fall back to `solid`.
- `lib/src/services/cover_family.dart` (new): the 10 `Cover` constants, `labelPlateColor` and `labelInkColor` ints.
- `lib/src/services/cover_registry.dart`: add `family` and `pickable` lists. `all` = legacy + family.
  `defaultCover = CoverFamily.linenSage`. Legacy constants stay untouched.
- `lib/drawing_core.dart`: export `cover_family.dart`.

drawing_ui
- `lib/src/painters/cover/cover_noise.dart` (new): FNV-1a seed from id, `math.Random(seed)` helpers.
- `lib/src/painters/cover/cover_textures.dart` (new): 4 texture builders. Each records a `ui.Picture` once
  in a unit 600x800 space (linen: jittered warp/weft hairlines; leather: seeded grain cells + vignette
  + inset stitch dashes; kraft: short fibre strokes + speckle; felt: dense two-tone fuzz specks).
- `lib/src/painters/cover/cover_renderer.dart` (new): `CoverRenderer.paint(Canvas, Size, Cover)`.
  It draws the base color, the cached texture picture (scaled, alpha-blended), the spine hinge shading
  and the label plate (RRect, paper color, hairline debossed edge). `static Rect labelPlateRect(Size)`
  is shared so the widget title and handwriting area line up.
- `lib/src/painters/cover/legacy_cover_pattern_painter.dart` (new): `_CoverPatternPainter` moved out of
  the widget so the widget stays under 300 lines.
- `lib/src/widgets/cover_preview_widget.dart`: material branch = `CustomPaint(CoverRenderer)` + serif title
  in `Positioned.fromRect(labelPlateRect)`. Ring-dot spine decoration only for legacy styles.
- `lib/src/canvas/page_background_painter.dart`: `case CoverStyle.material` calls `CoverRenderer.paint`.
- `lib/src/services/thumbnail_generator.dart`: rename `_renderCoverImage` to `_renderCover`. Material covers
  paint synchronously through `CoverRenderer`; image covers keep the asset path.
- `lib/src/widgets/template_picker/template_picker.dart`: `covers: CoverRegistry.pickable`.
- `lib/drawing_ui.dart`: export `cover_renderer.dart`.

example_app
- `lib/features/documents/presentation/widgets/cover_grid.dart`: use `CoverRegistry.pickable`. Migrate this
  file's `isDark` ternaries to `context.palette` (boy-scout rule) and keep tap targets at 48dp or more.
- `lib/features/documents/presentation/screens/template_selection_screen.dart`: no logic change expected
  (it already uses `defaultCover`). Touch only if analysis or the widget test needs it.
- `test/helpers/font_loader.dart` (new): pull `_loadFont` out of `app_palette_test.dart` for reuse.

## Design
- Backward compatibility (AC4): coverIds are a persisted contract. All 17 legacy `Cover` constants
  stay in `CoverRegistry.all`, so `byId` resolves them. They only drop out of `pickable`. New ids are frozen:
  `linen_sage, linen_sand, linen_slate, leather_oxblood, leather_cognac, leather_navy,
  kraft_natural, kraft_charcoal, felt_mustard, felt_dusty_rose`. A contract test lists every legacy and
  new id and fails if any of them disappears. No DB migration, no JSON migration. `assets/covers/`
  stays for legacy documents. Removing it is a separate owner decision (licensing, THIRD_PARTY).
- Colors: the base colors are `int`s in drawing_core, as `CoverRegistry` already does (drawing_core cannot
  use Flutter `Color`). Candidate values are below. ui-designer confirms them in step 6.
  sage 0xFF8A9A7B, sand 0xFFCDBB98, slate 0xFF5B6770, oxblood 0xFF5E1F24, cognac 0xFF9A5B2E,
  navy 0xFF1F2B44, kraft 0xFFB8946A, charcoal 0xFF3A3836, mustard 0xFFC9A13B, dusty rose 0xFFC99A9A.
- Label plate: this is part of the physical notebook, not the app chrome. It always uses the light
  paper surface (`0xFFFBF9F4`, mirrors `AppPalette.light.surface`) with ink `textPrimary` light, in both themes.
  That way persisted thumbnails do not depend on the theme. An example_app test asserts that the mirror
  matches the token.
  Title: `Theme.of(context).textTheme.titleLarge` (SourceSerif4 per `AppTypography`), no inline fontSize.
  `FittedBox(scaleDown)`, max 2 lines, ellipsis. The plate sits in the upper third, 64% wide, 3:1.
- Title only in the widget: `PageBackgroundPainter` and `ThumbnailGenerator` draw a blank plate.
  On the editor cover page the user can handwrite on it, like a real label. The library card and picker
  use `CoverPreviewWidget` and show the typed title.
- Performance: one cached `ui.Picture` per material+seed (at most 10, in a static map, built lazily
  on first paint). `paint()` only scales and draws the cached picture with preallocated `Paint`s.
  `shouldRepaint` compares the cover id and plate color.
- Why not fragment shaders: they need a shader asset pipeline in drawing_ui, they are unreliable in
  `flutter test` goldens, and they would need a CPU path anyway for `ThumbnailGenerator`'s
  `PictureRecorder`. Painted pictures cover all three render targets with one code path.
- Layers: drawing_core = data only. drawing_ui = rendering. example_app = picker UI. No rule is bent.

## Test plan
- drawing_core `test/services/cover_registry_test.dart`: every legacy id resolves, `pickable` == the
  10 family ids in BRIEF order, default is `linen_sage`, ids are unique.
  `test/models/cover_test.dart`: JSON round-trip with `material`, unknown style falls back to solid.
- drawing_ui `test/painters/cover_renderer_test.dart`: rendering twice gives identical bytes
  (determinism), `labelPlateRect` proportions, center pixel inside the plate == plate color.
- drawing_ui `test/services/thumbnail_generator_test.dart` (extend): a material cover renders without
  `rootBundle` and the corner pixel is close to the base color. Legacy image path unchanged.
- drawing_ui `test/widgets/cover_preview_widget_test.dart`: the title Text lies inside the plate rect.
  The legacy solid cover still shows the ring decoration.
- example_app `test/features/documents/presentation/widgets/cover_grid_test.dart`: shows 10 items,
  tapping `felt_mustard` calls back with that cover, the item hit area is at least 48dp.
- example_app `.../widgets/cover_family_golden_test.dart`: loads SourceSerif4 and Inter, sheet = 10 covers
  in a 5x2 grid, title "Biology". Writes `goldens/cover_family_120_{light,dark}.png` and
  `goldens/cover_family_240_{light,dark}.png`.

## Steps (one implementer run each)
1. drawing_core model + registry: `cover.dart`, `cover_family.dart`, `cover_registry.dart`, barrel, 2 tests.
   Verify: `cd packages/drawing_core && dart test test/models/cover_test.dart test/services/cover_registry_test.dart && dart analyze`
2. drawing_ui renderer: `painters/cover/{cover_noise,cover_textures,cover_renderer}.dart` + barrel + test.
   Verify: `cd packages/drawing_ui && flutter test test/painters/cover_renderer_test.dart && dart analyze`
3. drawing_ui preview widget: `cover_preview_widget.dart`, `legacy_cover_pattern_painter.dart`, widget test.
   Verify: `cd packages/drawing_ui && flutter test test/widgets/cover_preview_widget_test.dart`
4. drawing_ui render targets: `page_background_painter.dart`, `thumbnail_generator.dart`,
   `template_picker.dart`, extend the thumbnail test.
   Verify: `cd packages/drawing_ui && flutter test test/services/thumbnail_generator_test.dart test/widgets/template_picker`
5. example_app picker: `cover_grid.dart` (pickable + palette migration), the plate token mirror test,
   `cover_grid_test.dart`. Check `template_selection_screen.dart`.
   Verify: `cd example_app && flutter test test/features/documents && ./scripts/check.sh analyze`
6. Golden sheet + design loop: font helper, golden test, `--update-goldens`. ui-designer reviews the PNGs
   (texture subtlety at 120dp, plate contrast, color fidelity to BRIEF). Fixes go back into step 2 files.
   Verify: `cd example_app && flutter test test/features/documents/presentation/widgets/cover_family_golden_test.dart`
   then `./scripts/check.sh test`.

## Risks
- Texture moiré or noise at 120dp: keep detail density proportional to size (pick the picture LOD for
  the bucket < 200dp vs >= 200dp). Two cached pictures per material at most.
- `thumbnail_generator.dart` is already 498 lines. The change keeps the line count about the same.
  Splitting it is a follow-up issue, not this PR.
- Legacy covers stay selected in old documents. The editor picker then shows no selection; that is acceptable.
- Golden font fidelity depends on loading the font in the test. Goldens are generated on Linux, like CI.

## Left out (YAGNI)
Custom photo covers, per-notebook custom colors, removing legacy assets/covers, premium covers
(FF_PREMIUM is off), embossed title on thumbnails, migrating old documents to family covers.

## Reference check
- GoodNotes: a cover is a template applied to page 1 (Change Template → Cover tab; the first page is
  what the Library shows). The built-in covers are flat or illustrated, and the notebook title is shown
  below the thumbnail, not printed on the cover.
- Flexcil: notebooks get a cover chosen from a color/design set when they are created, and the title
  is shown under the thumbnail. (Search did not surface official docs; this is from product knowledge
  and is unverified.)
- StarNote: the store listing mentions templates and digital paper. No cover specifics were found.
- Pattern we follow: the cover is page 1 of the notebook (we already model this with `Page.createCover`),
  it is chosen at creation from a curated grid, can be changed later from page options, and is
  stored by id.
- Deviation: the title sits on a serif label plate printed on the cover, and the covers are procedural
  material textures instead of bitmaps. Reason: the owner-approved BRIEF (originality, no copied assets),
  and it also removes our dependence on third-party cover images.
