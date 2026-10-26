# Plan: #146 Tool panels on the chrome layout

Branch `claude/146-tool-panels-chrome`. Follow-up of #52 (spec `docs/specs/52-editor-chrome.md` §4).
No SDK in the authoring session, so CI is the only compiler: every step is mechanical
and uses only API names read in the source.

## 1. Acceptance criteria
- **AC1.** `highlighter_settings_panel`, `eraser_settings_panel`, `shapes_settings_panel`,
  `text_settings_panel`, `laser_pointer_panel`, `lasso_selection_panel` and `sticky_note_panel` have
  a 48dp `ChromePanelHeader` (title + `ChromeIconButton` close), `ChromeHairline` dividers,
  `ChromeSpacing` / `ChromeRadius` only, `ChromePalette` only.
  Grep gate (must print nothing):
  `grep -nP "colorScheme|Color\(0x|Colors\.(?!transparent)|isDark|controlSurface|PanelCloseButton|TextStyle\(" <file>`
  (content-colour constants with a `// content:` comment are the documented exception).
- **AC2.** Every tappable ≥ 48x48; no overflow at width 380 with `textScaler` 1.3; one widget test per panel.
- **AC3.** 14 goldens (7 panels × light/dark), regenerated in CI and reviewed by `ui-designer`.
- **AC4.** Behaviour unchanged: slider min/max/`divisions` as today (highlighter, eraser, shapes,
  laser keep the `GoodNotesSlider` default `divisions = 8`; text keeps `divisions: 16`; never add
  `divisions: null`). Provider calls, titles and Turkish strings unchanged.

## 2. Shared widgets — `packages/drawing_ui/lib/src/panels/chrome_panel_parts.dart`
Export from `lib/src/panels/panels.dart` (and therefore the package barrel).
```dart
/// 48dp panel header: title (titleSmall w600 textPrimary, 1 line, ellipsis) + close.
class ChromePanelHeader extends StatelessWidget {
  const ChromePanelHeader({super.key, required this.title, required this.onClose});
  static const double height = ChromeSizes.minTouchTarget; // 48
  final String title;
  final VoidCallback onClose;
}
/// 1dp palette.border line with ChromeSpacing.md vertical padding (moved from the pen panel's _Hairline).
class ChromeHairline extends StatelessWidget { const ChromeHairline({super.key}); }
/// Section label: textTheme.labelMedium, w600, palette.textMuted, bottom pad ChromeSpacing.xs. Verbatim text.
class ChromeSectionLabel extends StatelessWidget {
  const ChromeSectionLabel(this.label, {super.key});
  final String label;
}
```
- Header body is a verbatim copy of the pen panel header; the pen panel uses it and drops
  `_Hairline`. `PenSettingsPanel.headerHeight = ChromePanelHeader.height`.
- Type selectors (highlighter, eraser, lasso, laser) use `ChromeIconButton` (`icon`, `tooltip`
  required, `onPressed`, `selectedIcon`, `selected`, `iconSize`, `key`): 48 hit / 40 visual.
  Row `spaceEvenly`, `iconSize: ChromeIconSizes.md`. Only icon names already in each file.
- Structure: `Padding(EdgeInsets.all(ChromeSpacing.lg))` → `Column(mainAxisSize: min,
  crossAxisAlignment: stretch)` → header, content blocks separated by `ChromeHairline`.
  Gaps map 4→xs, 6/8/10→sm, 12→md, 16/20→lg. Close = `activePanelProvider` ← null.

### `CompactToggle` (`lib/src/widgets/compact_toggle.dart`)
Constructor unchanged. Body: `ConstrainedBox(minHeight: ChromeSizes.minTouchTarget)` + opaque
`GestureDetector(onTap: () => onChanged(!value))` around the row (the Switch still wins its own
taps, so one call). Label `labelMedium` `textPrimary`. Switch: `activeTrackColor: activeColor ??
palette.accent`, `activeThumbColor: palette.onAccent`, `inactiveThumbColor: palette.textMuted`,
`inactiveTrackColor: palette.surfaceElevated`, `trackOutlineColor:
WidgetStatePropertyAll(palette.border)`.

## 3. Per panel (`packages/drawing_ui/lib/src/panels/`)
- **highlighter**: header `isNeon ? 'Neon Fosforlu' : 'Fosforlu Kalem'`; type selector →
  `ChromeIconButton(selected:, tooltip:, key: ValueKey('highlighter-type-${t.name}'))`; sliders
  `palette.accent`; order preview, type row, hairline, sliders + toggle, hairline, strip.
  Swoosh painter colours are user ink (content).
- **eraser**: header `_titleForMode(active)`; type selector → `ChromeIconButton` keyed
  `eraser-type-${t.name}`; `_CompactActionButton` → `ClearPageButton` (`eraser-clear-page`,
  minHeight 48, `ChromeRadius.md`, `palette.danger` icon+label `labelLarge`); dialog colours →
  `surfaceElevated/textPrimary/textMuted/danger`. Split into `eraser_settings_widgets.dart` if >300
  lines. `eraser_preview_painter.dart`: colours from palette (textMuted, danger, accent) passed in.
- **shapes**: header `'Şekil'`; drop `controlSurface`; `_ShapeOption` keyed `shape-${shape.name}`,
  selected `accentContainer` fill + 1.5dp `accent` border + `accent` icon, idle transparent +
  1dp `border` + `textMuted`, `Semantics(button, selected, label)`; grid spacing `ChromeSpacing.sm`;
  `_StripLabel` → `ChromeSectionLabel`; slider `palette.accent`.
- **text**: header `'Metin Aracı'`; hint `bodySmall textMuted`; labels → `ChromeSectionLabel`;
  `_StyleToggle` 48 square hit, 40 visual, keys `text-style-bold|italic|underline`, selected
  `accentContainer`/`accent`, idle `border`/`textMuted`; slider keeps `divisions: 16`;
  `text_preview_painter.dart` border → `palette.border`.
- **laser** (406 lines, split): `_LaserPreview` + painter → `laser_preview_painter.dart`
  (`LaserPreview`); `Colors.white` core → content constant. Header `_titleFor(mode, style)`;
  `_PillCard` → 4 `ChromeIconButton`s keyed `laser-type-solid|hollow|rainbow|dot`.
- **lasso**: header `_titleForMode`; mode selector `ChromeIconButton` keeping `lasso-mode-${name}`
  keys and `_iconFor` pairs; `'Seçilebilir'` → `ChromeSectionLabel`; `_TypeChip` 48 min height,
  keyed `lasso-type-${type.name}`, pill `ChromeRadius.full`; `selection_preview_painter.dart`
  colours from palette.
- **sticky note**: `ChromePanelHeader('Yapışkan Not')`; action tile `sticky-note-add`, minHeight 56,
  `ChromeRadius.lg`, 1dp `border`, 24dp swatch in the note content colour
  (`const _kDefaultNoteColor = Color(0xFFFFF3CD); // content: mirrors StickyNote default`) +
  `'Not Ekle'` `labelLarge textPrimary`. `_addStickyNote` unchanged.

Not touched: `ColorPickerStrip`, `GoodNotesSlider`, `PanelCloseButton` / `ToolPanel` (public API).

## 4. Tests
- Harness `test/panels/helpers/panel_harness.dart`: `pumpPanel(tester, panel, {textScale,
  brightness, setup})` (mock prefs, 400x1600 view, `chromeTheme(brightness)`, MediaQuery
  textScaler, 380 wide in a scroll view) and `expectMinTapTarget(tester, finder)`.
- One `test/panels/<panel>_test.dart` each: 1.3 overflow, min tap targets, close via
  `byTooltip('Kapat')`, slider divisions, key interactions (type switch, toggles, clear dialog,
  shape select, bold, laser mode, sticky add → undo available + panel closed).
- `test/widgets/compact_toggle_test.dart`: height ≥ 48, tapping the label flips the value.
- Golden `test/golden/tool_panels_golden_test.dart`: 7 panels × `Brightness.values`,
  `tool_panel_<name>_<brightness>`, pattern of `chrome_icon_button_golden_test.dart`.

## 5. Existing tests to keep green
`test/lasso_panel_test.dart` (keys, icons, texts, height < 600), `compact_toggle_test.dart`
(one Text, one Switch, single onChanged), `toolbar_compact_sheet_test.dart` (class names),
`pen_settings_panel_test.dart` and chrome goldens (pen panel pixel-identical after step 1).
Skipped legacy groups stay skipped.

## 6. Steps
1. Shared parts + pen panel + exports. 2. CompactToggle + test. 3. Harness + highlighter.
4. Eraser. 5. Shapes. 6. Text. 7. Laser split. 8. Lasso. 9. Sticky note.
10. Goldens: dispatch `update-goldens.yml`, merge, `ui-designer` review, fix.

## 7. Risks / left out
- Compile risk without SDK: CI is the gate.
- Panels get taller; the popover scrolls and the phone sheet caps height.
- Previews stay (mode explanation; behaviour-unchanged rule); removal is a ui-designer call.

## 8. Reference check
GoodNotes, StarNote and Flexcil use one consistent popover for every tool (title/variants,
options, size, colours) → every tool panel follows the pen-panel layout. GoodNotes closes by
tapping outside; we keep the explicit 48dp close from spec §4. Mode previews kept for v1.0.
