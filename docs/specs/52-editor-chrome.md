# Spec: editor chrome redesign (#52)

Brief: `docs/design/BRIEF.md`. Depends on #45 (`docs/specs/45-pen-picker.md`).
Scope: toolbar, pen settings panel, page sidebar.

## 0. Problems in the current code
1. Toolbar is filled with ink blue (`drawing_screen.dart` DrawingTheme uses `colorScheme.primary`); the brief limits accent to selection, focus and primary actions.
2. App `ColorScheme` is still emerald; brief colours exist only in `AppPalette`, which `drawing_ui` cannot read.
3. `DrawingShadows._tint` is emerald.
4. `ElyanotesIcons` uses Phosphor Light; brief wants Regular, Fill when selected.
5. Touch targets < 48dp: `ToolButton` (40/36), `ToolbarIconButton` (36), sidebar `_FilterTab` (40x28), bookmark (28x28), phone slots (40).
6. `FloatingUndoRedo` can sit over the page on tablet.
7. Pen panel shows ink twice (100dp `_SwooshPainter` plus #45 tile previews), inline `fontSize: 16`.
8. Phone sheet opens at fixed 65% height.
9. Popovers have no exit animation.

## 1. Purpose
Primary action: select a tool; tapping the selected tool opens its settings.
Hard rule: chrome never overlaps the page while writing. Toolbar band and tablet
sidebar take layout space. Only short-lived panels (popover, phone sheet, phone
drawer) may overlay; an outside tap closes them and never draws.

## 2. Decisions
- **D1 (decided: option A).** Add `ChromePalette` ThemeExtension in
  `drawing_ui/lib/src/theme/chrome_palette.dart` with roles `background, surface,
  surfaceElevated, border, textPrimary, textMuted, textDisabled, accent,
  accentContainer, onAccent, danger, paper`; const light/dark defaults equal the brief
  table (only place in drawing_ui where colour literals are allowed).
  `ChromePalette.of(context)` falls back to `fromColorScheme`. `example_app` registers
  one built from `AppPalette` in `app_theme.dart`. Rejected: remapping the app-wide
  ColorScheme (restyles every screen, collides with #51).
- **D2.** `theme/chrome_tokens.dart`: `ChromeSpacing` (xxs 2, xs 4, sm 8, md 12, lg 16,
  xl 24, xxl 32), `ChromeRadius` (sm 8, md 10, lg 12, xl 16, xxl 20, full 999),
  `ChromeDurations` (instant 100, fast 200, normal 300), `ChromeIconSizes` (16/20/24).
- **D3.** No free toolbar dragging in v1.0; toolbar is docked to the top.

## 3. Layout
### Tablet landscape (>= 840)
Top band (fill `background`, no border/shadow), height inset + sm + 52 + xs, side
padding lg. Three capsules (fill `surface`, 1dp `border`, radius xl, shadow `chrome`,
height 52): nav (Home, Sidebar if pages > 1, title with chevron, max 240), tools
(Undo, Redo, divider, tools from `toolbarConfigProvider`; last slot becomes overflow
menu, no horizontal scroll), actions (Add page, Export, More). Tool capsule is centred
with >= md gap. Reader mode fades the tool capsule (100ms); other capsules stay.
`FloatingUndoRedo` is removed on tablet.
Sidebar: docked floating card, width 256, footprint `kPageSidebarWidth` = 264
(margin left sm, bottom sm), fill `surface`, hairline, radius xl, shadow `chrome`.
Canvas transform uses the footprint so the page reflows.

### Tablet portrait / medium (600-839)
Same band. Nav: Home + Sidebar (title moves to More). Actions: Add page + More (Export
in More). Tool capsule fits Undo, Redo, divider, 8 tools + overflow at 820.

### Phone (< 600)
Row 1 (48, no fill): Back, serif title, Pages, More. Row 2: tool capsule 48 tall,
margin h sm, 48dp slots, last slot overflow. Chrome height = inset + 104.
Sidebar: left drawer over page with scrim, width min(280, 85%), right corners xl.

## 4. Components
- **`ChromeIconButton`** (`toolbar/chrome_icon_button.dart`): 48x48 hit, 40x40 visual,
  radius md, icon 24 (toolbar) / 20 (panels), no ripple. States: default (transparent,
  textMuted, Regular); pressed (textPrimary 8%); selected (accentContainer, accent,
  Fill); selected+pressed; disabled (textDisabled); focus (2dp accent ring). Pen group
  shows an 8dp ink-colour dot bottom-right with 1.5dp `surface` ring. Semantics:
  button, selected, enabled, label. `ToolButton`, `ToolbarIconButton`,
  `ElyanotesNavButton` delegate to it; public APIs unchanged.
- **`ChromeCapsule` / `ChromeDivider`** (`toolbar/chrome_capsule.dart`).
- **Popover panel:** fill `surfaceElevated`, hairline, radius xl, `panel` shadow, gap
  sm, edge margin md, min space 360, exit animation (100ms ease-in) before removal.
- **DrawingTheme builder** moves to `screens/drawing_screen_theme.dart`:
  toolbarBackground=background, icon=textMuted, selected=accent, disabled=textDisabled,
  panelBackground=surfaceElevated, panelBorder=border.
- **Pen settings panel** (tablet popover, width 380, padding lg): header (48, pen name,
  close), `PenTypePicker`, hairline, sliders (thickness, pressure, stabilisation; track
  4dp, thumb 20dp, 48 hit, no step ticks, tabular values), hairline, colour strip
  (32dp swatches in 48 cells, selected = 2dp accent ring + 2dp gap, "+" opens picker).
  Remove `_StrokePreview` and `_SwooshPainter`. "Uc Keskinligi" label becomes
  "Kalinlik"; keep `NN%` format unless mm mapping is confirmed.
- **Page sidebar:** segmented filter (grid / bookmark / audio, 40 visual, 48 hit),
  2-column thumbnails (radius sm, fill `paper`, hairline, page shadow), selected =
  2dp accent ring outside a 2dp surface gap and an accentContainer number pill,
  bookmark hit 48x48 (Fill accent when set; idle shown only on selected page), 48dp
  "..." target, dashed "Sayfa ekle" cell, empty bookmarks state. Fix Turkish tooltips.
- **Phone sheet:** fill `surfaceElevated`, top radius xxl, drag handle 32x4, height
  follows content (cap 0.6, max 0.85), barrier textPrimary 12%.
- **Not in scope:** `FloatingPenBox`, `PageIndicatorBar`, `ZoomIndicator`, selection
  toolbar, other tool panels (follow-up issue).

## 5. Depth and colour
All colours from `ChromePalette`; no `isDark` ternaries, no `Color(...)` in widgets.
Selection only uses accent/accentContainer. `DrawingShadows`: drop emerald tint; add
`chrome` (light: black 6% y1 blur3 + black 4% y4 blur12 spread-2; dark: none) and
`panel` (light: black 8% y8 blur24 spread-4 + black 4% y1 blur3; dark: black 32%
y8 blur24 spread-4). Page stays `paper` in dark mode.

## 6. Typography and icons
Title: titleMedium with serif family from titleLarge, letter-spacing -0.5%. Panel
header titleSmall w600. Labels labelMedium; values labelMedium tabular figures.
Icons: Phosphor Regular idle / Fill selected; sizes 24 / 20 / 16.

## 7. Motion
Tool select 200 easeOut; pressed fade 100; popover enter 200 (fade + scale 0.96->1),
exit 100 easeIn; tablet sidebar 300; phone drawer 300; reader fade 100. Pen-down during
sidebar animation allowed; transform recalculates once at the end.

## 8. Behaviour
Tap selects; tap selected opens panel; tap again closes. Outside tap or pen-down
closes the popover without a stroke. Esc closes popover. Focus order nav, tools,
actions. Tablet sidebar stays open across page changes; phone drawer closes on page tap.

## 9. Tests
Widget: `chrome_icon_button_test` (48 hit, selected Fill + accentContainer, disabled),
`editor_chrome_layout_test` at 1180x820, 820x1180, 390x844 (canvas never intersects
band/sidebar; androidTapTargetGuideline + textContrastGuideline), `pen_settings_panel_test`
(no swoosh, one `PenTypePicker`, 3 sliders, no overflow at 380 / textScaler 1.3),
`page_sidebar_test` (bookmark 48 hit, toggles without navigating; tabs >= 48),
outside-tap-no-stroke test.
Goldens (light + dark unless noted): toolbar landscape 1180, portrait 820, phone 390,
landscape reader (light), button states strip; pen panel tablet / phone / text130;
sidebar tablet, phone drawer (light), empty bookmarks (light); full-screen harness
landscape (sidebar + popover open), portrait (light), phone. Helper:
`test/golden/helpers/chrome_theme.dart`.
Review checks: no ink blue outside selection; crisp hairlines; concentric radii
(16/10/6); band reads as desk; nothing overlaps page except popover; no pure black in dark.

## 10. Implementation slices (each <= 3 production files)
1. Tokens + palette (`chrome_tokens.dart`, `chrome_palette.dart`, export; unit tests).
2. Depth + icon weight (`drawing_shadows.dart`, `elyanotes_icons.dart`); own PR, regenerates goldens.
3. Host wiring (`example_app/.../app_theme.dart`, golden theme helper).
4. `ChromeIconButton`; `tool_button.dart` delegates.
5. Remaining buttons (`toolbar_widgets.dart`, `elyanotes_nav_button.dart`).
6. Capsule + expanded toolbar (`chrome_capsule.dart`, `tool_bar.dart`, `toolbar_nav_sections.dart`).
7. Medium toolbar.
8. Phone toolbar (`compact_bottom_bar.dart`, `top_navigation_bar.dart`).
9. Screen theme + undo removal (`drawing_screen_theme.dart`, `drawing_screen.dart`, `drawing_screen_layout.dart`).
10. Popover (`popover_panel.dart`).
11. Pen panel (`pen_settings_panel.dart`, `goodnotes_slider.dart`, `color_picker_strip.dart`).
12. Phone sheet (`compact_tool_panel_sheet.dart`).
13. Sidebar shell (`page_sidebar.dart`).
14. Sidebar items (`page_sidebar_widgets.dart`).
15. Sidebar host + motion (`drawing_screen.dart`).
16. Proof: layout test + full-screen goldens, then design-loop review.

## 11. Reference check
- **GoodNotes:** nav, tools and undo/redo share one top bar; left sidebar with page
  thumbnails and filter tabs; tapping the selected tool opens a popover under it (pen
  types, sliders, colours). Its Sept 2025 floating toolbar draws user complaints about
  overlapping content.
- **Flexcil:** not confirmed from official docs (unverified): top toolbar, settings from
  the selected tool, side page panel.
- **StarNote:** store listing confirms pens with colour/thickness; layout unconfirmed.
- **We do:** top-docked chrome (nav / tools / actions), undo/redo in the tool group,
  anchored settings popover with pen types on top, left 2-column page sidebar.
- **Deviations:** floating capsules on a desk-coloured band that still takes layout
  space (brief: quiet, rounded, floating, without overlap); no free toolbar placement
  in v1.0; no swoosh preview (per-tile live previews from #45); sidebar is an inset
  card that pushes the page. Icons are Phosphor; no competitor assets copied.

## Open items
- Thickness label in mm vs %: keep % unless confirmed.
- Flexcil reference unverified.
- Slice 2 changes all existing goldens with shadows/icons: ship as its own PR.
