# Spec: pen picker v2 (#45, plan step 9)

Plan: `docs/plans/45-pen-presets-v2.md` (AC A7, steps 10-11). Brief: `docs/design/BRIEF.md`.
Files: `panels/pen_preset_preview.dart` (step 10), `panels/pen_type_picker.dart` (step 11).

## 1. Purpose
Choose which ink to write with. One primary action: tap a tile to make that tool current.
Each tile shows the stroke you will get (real renderer, current colour and thickness), not an icon.
No Phosphor icons in the tiles.

## 2. Content and order (fixed)
| # | ToolType | Label (visible + semantics) |
|---|---|---|
| 1 | `fountainPen` | Dolma Kalem |
| 2 | `ballpointPen` | Tükenmez Kalem |
| 3 | `brushPen` | Fırça Kalem |
| 4 | `highlighter` | Fosforlu Kalem |
| 5 | `pencil` | Kurşun Kalem |

`dashedPen`, `rulerPen`, `gelPen`, `hardPencil` and `neonHighlighter` are not shown.
Selected means `currentToolProvider == tile.tool`, exact match only. If the current tool is a legacy
type, no tile is selected (no fallback to ballpoint).

## 3. Container and layout
The picker is always one row of five tiles. No grid: five tiles fit at every size class.

```
tablet popover (portrait 820 / landscape 1180 wide; anchored to pen group button)
+--------------------------------------------------------------+
| md                                                           |
| [tile][sm][tile][sm][tile][sm][tile][sm][tile]   <- 5 x 64dp |
| md                                                           |
+--------------------------------------------------------------+
 width 376 = 12 + 5*64 + 4*8 + 12 ; height 120 = 12 + 96 + 12

phone (390 x 844), inside the existing tool panel bottom sheet, full width
| lg [tile][sm][tile][sm][tile][sm][tile][sm][tile] lg |
 tiles are Expanded: (390 - 2*16 - 4*8) / 5 = 65.2dp each; vertical padding md
```
- Tablet (>= 600, both orientations): the tile width is fixed at 64. The popover chrome (surface, radius,
  shadow) stays with `PopoverController`, and popover `maxWidth` must be >= 380 (see section 12).
- Phone (< 600): tiles are `Expanded` with a minimum width of 60. If the available width drops below 60 per
  tile, wrap the row in a horizontal scroll view instead of shrinking the tiles (cannot happen at 360+).
- Widget API: `PenTypePicker({onPenSelected, EdgeInsets? padding})`. Default padding is
  `symmetric(h: md, v: md)` on tablet and `symmetric(h: lg, v: md)` on phone, chosen by
  `ToolbarLayoutMode.compactBreakpoint`. Pass `padding: EdgeInsets.zero` when embedded in a panel.

## 4. Spacing, radius, duration constants
`drawing_ui` cannot import example_app. Add private constants at the top of `pen_type_picker.dart`
with the same values as the app tokens (comment: "mirrors AppSpacing/AppRadius"):
`xs = 4, sm = 8, md = 12, lg = 16` (AppSpacing), `tileRadius = 12` (AppRadius.lg),
`wellRadius = 8` (AppRadius.sm). Durations come from `DrawingTheme.of(context).animationDuration` (200ms).
No other raw numbers in the widget code. A shared `drawing_ui` spacing token is a later follow-up.

## 5. Tile anatomy (tablet sizes; phone only changes the width)
```
+---------- 64 ----------+   radius 12, padding: top sm, sides xs, bottom sm
|  +------ 56 x 40 -----+ |   preview well: radius 8, 1dp hairline
|  |   ~~ preview ~~    | |
|  +--------------------+ |
|          sm             |
|        Tükenmez         |   label block: fixed height 32 (2 lines x 16)
|          Kalem          |
+-------------------------+   total height 96
```
- Hit area is the whole tile (64x96, phone 65x96), above 48dp. `InkWell` with
  `splashFactory: NoSplash.splashFactory` and highlight from the colour table below. No default ripple.
- Label: `Theme.of(context).textTheme.labelSmall`, `height: 16/11`, centred, `maxLines: 2`,
  `softWrap: true`, `overflow: ellipsis`. Normal space in the string; inner width >= 56 breaks it at the
  space. Selected adds `fontWeight: w600`. Never set `fontSize` inline. Fixed 32dp label block keeps
  tiles aligned.
- Preview well: background `ref.watch(canvasColorSchemeProvider).background` (the page colour the ink
  lands on; light paper by default, also in dark UI, per the brief), 1dp `outlineVariant` border,
  clipped to radius 8.

## 6. Preview (`PenPresetPreview(style)`, step 10)
- Input: `ref.watch(strokeStyleForToolProvider(tool))`. The picker passes the style; the preview owns no state.
- **Curve** (private const `_kPreviewCurve`): 17 samples of the cubic
  P0 (0, 0.80), C1 (0.30, -0.60), C2 (0.70, 1.60), P3 (1, 0.20) in a unit box (y down): a soft S-shape.
  Stored as a const literal of (x, y, pressure). Pressure ramps 0.30 -> 1.0 (t 0 to 0.40), holds 1.0
  (to t 0.60), falls to 0.45 at t 1, so fountain and brush show thinning and taper. Uniform timestamps,
  8ms per sample (deterministic).
- **Highlighter** uses `_kPreviewLine`: 9 samples on y = 0.5, pressure 1 (a chisel S-curve reads as a
  blob at this size).
- **Box**: the curve maps into the well deflated by `symmetric(h: sm, v: md)` (40x16 on tablet). The nib
  may overflow into the padding; the well clips it.
- **Thickness mapping** (so a 40px highlighter and a 1.5px pencil both read):
  `n = ((t - cfg.minThickness) / (cfg.maxThickness - cfg.minThickness)).clamp(0, 1)`,
  `w = lerpDouble(lo, hi, n)` with fountain/ballpoint/pencil 1.5..6, brush 2..8, highlighter 6..14.
  Build `style.copyWith(thickness: w, dynamics: taperStart/taperEnd scaled by k = w / t)`, and clamp
  `taperStart + taperEnd <= 0.6 * curve length`.
- **Multiply**: no ink mark under the highlighter. Over the paper well multiply equals normal blending,
  and a fake ink mark would put a colour in the chrome the user did not choose. The A6 preset golden
  proves multiply. The preview keeps the real `blendMode`. On a dark page colour the highlighter preview
  is faint, exactly as on the canvas.
- **Painter**: constructor builds the `Stroke` and its geometry once. `paint()` only calls the shared
  renderer entry used for committed strokes (texture -> outline -> stroked), no allocation.
  `shouldRepaint` returns `old.style != style || old.size != size`. Wrapped in a `RepaintBoundary`.

## 7. Colour roles (ColorScheme, mapped from the brief palette by the app theme)
| State | Tile fill | Tile border | Label |
|---|---|---|---|
| idle | transparent | none | `onSurfaceVariant` |
| pressed | `onSurface` @ 8% | none | `onSurfaceVariant` |
| selected | `primaryContainer` | 1.5dp `primary` | `primary`, w600 |
| selected + pressed | `primary` @ 12% over `primaryContainer` | 1.5dp `primary` | `primary`, w600 |
| keyboard focus | unchanged | 2dp `primary` ring (replaces the 1.5dp border) | unchanged |

Same roles in light and dark (both pass AA). No `isDark` checks, no `Color(...)` literals. Ink colour
is user content and passes through unchanged.

## 8. Motion
- Selection fill and border: `AnimatedContainer`, `DrawingTheme` duration (200ms), `Curves.easeOut`.
- Pressed highlight appears at once, fades out in 100ms.
- Preview changes repaint at once, no animation. `selectTool` and `onPenSelected` fire on tap-up and
  never wait on an animation.

## 9. Behaviour and semantics
- Tap: `ref.read(currentToolProvider.notifier).selectTool(tool)`, then `onPenSelected?.call(tool)`.
- Row: `Semantics(container: true, label: 'Kalem türü')`. Tile:
  `Semantics(button: true, selected: isSelected, label: <Turkish label>)`. Preview in
  `ExcludeSemantics`; the visible label is excluded too so it is announced once.
- No tooltips (label always visible). Focus order follows tile order; Enter/Space activates.

## 10. Tests (step 11)
Widget test `test/panels/pen_type_picker_test.dart`:
- Exactly 5 `PenPresetPreview`; labels appear in table order, sorted by x.
- `Kesik Çizgi` and `Cetvelli Kalem` find nothing.
- Tapping `Fosforlu Kalem` sets `currentToolProvider == highlighter`; `onPenSelected` receives `highlighter`.
- Only the current tool's tile is selected; with current tool `dashedPen`, none is.
- Every tile is at least 48x48.
- After overriding the brush colour, the brush tile's `PenPresetPreview.style == strokeStyleForToolProvider(brushPen)`.
- No overflow at width 390 (phone) or 376 (tablet), or with `textScaler 1.3`.
- Preview: `shouldRepaint` false for an equal style, true after a colour change.

Golden test `test/golden/pen_type_picker_golden_test.dart` (alchemist; CI goldens committed, platform
goldens for review):
| # | Name | Theme | Size | State |
|---|---|---|---|---|
| 1 | `tablet_light` | light | 376 | ballpoint selected, defaults |
| 2 | `tablet_dark` | dark | 376 | ballpoint selected |
| 3 | `phone_light` | light | 390 | ballpoint selected |
| 4 | `phone_dark` | dark | 390 | ballpoint selected |
| 5 | `tablet_light_highlighter` | light | 376 | highlighter selected |
| 6 | `tablet_light_max` | light | 376 | every preset at maxThickness, saturated colours |
| 7 | `tablet_dark_min` | dark | 376 | every preset at minThickness |
| 8 | `phone_light_text130` | light | 390 | textScaler 1.3, fountain selected |

Design-loop review checks: taper on fountain and brush, round ends on ballpoint, grain on pencil,
translucent flat highlighter, nothing clipped except inside the well.

## 11. Reference check
- GoodNotes: the pen popover has a row of pen types (fountain, ball, brush) at the top with a stroke
  preview; highlighter is a separate tool.
- StarNote / Flexcil: pen types sit in a horizontal row in the pen popover, colour and size below.
- What we do: one horizontal row like all three, with a live stroke preview per tile instead of a drawn
  pen illustration (original, no copied assets). Deviation: highlighter is in the row (A7) so phones
  have a single ink chooser.

## 12. Integration (found while writing this spec; decided for step 11)
- Today the picker is unreachable: nothing sets `penPickerModeProvider` to `true`, and the phone sheet
  (`compact_tool_panel_sheet.dart`) never passes picker mode.
- `PenSettingsPanel` (`pen_settings_panel.dart` / `pen_settings_widgets.dart`) still shows its own type
  row with dashed/ruler and no fountain, which contradicts architect decision Q1.
- Decision (follows the GoodNotes convention of pen types at the top of the pen popover): step 11 embeds
  `PenTypePicker(padding: EdgeInsets.zero)` as the type row at the top of `PenSettingsPanel`, replacing
  `PenTypeSelector`; this makes the picker reachable on phone and tablet with no new entry point.
  `penPickerModeProvider` and the standalone picker popover path become unused; remove them in the same
  step if nothing else reads them.
- `drawing_screen_layout.dart`: popover `maxWidth` becomes 380 for both panel kinds (was 300 for the picker).
- Step 11 therefore touches up to 5 production files; split it into 11a (picker + preview wiring, goldens)
  and 11b (PenSettingsPanel integration, layout width, provider cleanup).
