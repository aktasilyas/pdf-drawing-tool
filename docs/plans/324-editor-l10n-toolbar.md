# Plan #324: editor l10n slice 3a (DrawingStrings, tool names, toolbar)

The architect decision in issue #324 is binding (DrawingStrings in drawing_ui, keys in example_app ARBs).
This plan covers order, file inventory and tests.

## 1. Problem and acceptance criteria
`drawing_ui` hardcodes Turkish copy and has no l10n path. The criteria are the ones in #324:
- `DrawingStrings`/`DrawingStringsTr`/`DrawingStringsScope`/`context.drawingStrings` are exported. drawing_ui imports no example_app code and no gen-l10n code.
- No user-facing literal remains in the 3a files. A drawing_ui guard test checks them, excluding `lib/src/l10n/`.
- The `editor*` ARB keys exist 1:1 in en/tr. `AppDrawingStrings` is installed in `MaterialApp.router.builder`. A unit test checks that every value is non-empty in en and tr, and that tr equals `DrawingStringsTr`.
- Toolbar widget test, en and tr, at 390x844 and 1280x800, text scale 1.3: localized tooltips/labels and no overflow.
- The robots stop matching Turkish literals for the toolbar items they touch.
- Goldens are unchanged. Analyze and tests pass in CI.

## 2. Design
- `packages/drawing_ui/lib/src/l10n/` (pure Dart except the scope file):
  - `drawing_strings.dart`: `abstract interface class DrawingStrings { ToolStrings get tools; ToolbarStrings get toolbar; }`, plus `class DrawingStringsTr implements DrawingStrings` (const). Slices 3b/3c add `panels`, `pages` and so on as new getters, which keeps every file under 300 lines.
  - `tool_strings.dart`: `abstract class ToolStrings { const ToolStrings(); String get fountainPen; ... }` with a concrete `Map<String, String> toMap()` that lists every getter, used for the drift test. Also `ToolStringsTr extends ToolStrings` holding today's literals.
  - `toolbar_strings.dart`: the same shape (`ToolbarStrings`, `toMap()`, `ToolbarStringsTr`). Strings with parameters are methods, e.g. `String thickness(String value)`. `toMap()` calls them with a fixed sample (`'#000000'`, `'2.0'`).
  - `drawing_strings_scope.dart` (Flutter): `DrawingStringsScope extends InheritedWidget` with `updateShouldNotify => strings != old.strings`, and `extension DrawingStringsContext on BuildContext { DrawingStrings get drawingStrings }` that depends on the scope and falls back to `const DrawingStringsTr()`.
  - `tool_type_label.dart`: `extension ToolTypeLabel on ToolType { String label(DrawingStrings s) }`, an exhaustive switch.
  - `l10n.dart` barrel, exported from `lib/drawing_ui.dart`.
- **`ToolType.displayName` is removed, not deprecated.** A deprecated getter would leave a second source of copy and trigger deprecation lints. Every caller is migrated:
  - lib: `toolbar/toolbar_overflow_menu.dart:82`, `toolbar/tool_button.dart:72`, `widgets/reorderable_tool_list.dart:49`, `widgets/floating_pen_box_slot.dart:78` and `canvas/mock_canvas.dart:48`. The last two are outside the 3a scope; they only switch to `label(context.drawingStrings)`, and their other literals stay as they are.
  - tests: `test/toolbar/toolbar_overflow_menu_test.dart:56,60`, `test/toolbar_professional_test.dart:336,621` and `test/models/tool_type_test.dart:24` switch to `label(const DrawingStringsTr())`.
  - E2E: `example_app/integration_test/robots/editor_robot.dart:86,110` uses `tool.label(tester.drawingStrings)`.
  - `TemplateCategory.displayName` is unrelated and stays.
- Methods that use strings after an `await` (the snackbar in `top_nav_menus.dart`) read `context.drawingStrings` before the await.
- example_app, in `lib/features/editor/presentation/l10n/` (the same pattern as `documents/presentation/l10n/library_labels.dart`):
  - `app_drawing_strings.dart`: `AppDrawingStrings(AppLocalizations l10n) implements DrawingStrings`. `==`/`hashCode` use `l10n.localeName`, so the scope only notifies when the locale changes.
  - `app_tool_strings.dart` and `app_toolbar_strings.dart`: `extends ToolStrings` / `extends ToolbarStrings`.
  - `app_drawing_strings_scope.dart`: `AppDrawingStringsScope({child})` reads `context.l10n` and builds a `DrawingStringsScope`.
  - All four are exported from `features/editor/editor.dart`. `main.dart` wraps the existing builder content with `AppDrawingStringsScope`. Popups and sheets live under the Navigator inside the builder, so they inherit the scope.
- **Copy deviation (flagged):** some TR literals are ASCII-ified (`Duzenleme Modu`, `Ses Kaydi`, `Kayit devam ediyor...`, `Kayitlari goster`, `Daha fazla arac`). In TR they get correct Turkish spelling instead of a verbatim copy, and `Ses Kaydi`/`Ses Kaydı` collapse into one key. I grepped the tests, integration tests and golden widgets: none of these strings are asserted or rendered (they are tooltips or audio-menu text, and audio is frozen). If the reviewer objects, revert those 5 TR values to verbatim and split `audio` into two keys. Everything else is verbatim, so goldens and existing tests stay unchanged.

## 3. Literal inventory (lib/src/..., line, getter, TR value, EN value)
The ARB key is `editorTool<Getter>` for `tools.*`, `editorToolbar<Getter>` for `toolbar.*` and `editorToolbarSettings<Getter>` for the settings panel.
**tools** (`models/tool_type.dart:77-124`): fountainPen Dolma Kalem / Fountain pen; pencil Kurşun Kalem / Pencil;
hardPencil Sert Kalem / Hard pencil; ballpointPen Tükenmez Kalem / Ballpoint pen; gelPen Jel Kalem / Gel pen;
dashedPen Kesik Çizgi / Dashed pen; highlighter Fosforlu Kalem / Highlighter; brushPen Fırça Kalem / Brush pen;
neonHighlighter Neon Fosforlu / Neon highlighter; rulerPen Cetvelli Kalem / Ruler pen; pixelEraser Silgi / Eraser;
strokeEraser Çizgi Silgisi / Stroke eraser; lassoEraser Kement Silgisi / Lasso eraser; shapes Şekiller / Shapes;
text Metin / Text; sticker Çıkartma / Sticker; image Resim / Image; selection Seçim / Select;
panZoom Kaydır/Yakınlaştır / Pan & zoom; laserPointer Lazer İşaretçi / Laser pointer; stickyNote Yapışkan Not / Sticky note;
toolbarSettings Araç Çubuğu Ayarları / Toolbar settings; penGroup Kalem / Pen (`widgets/reorderable_tool_list.dart:46`).
The highlighter and eraser groups (`reorderable_tool_list.dart:47-48`) reuse `highlighter` and `pixelEraser`.
**toolbar** (sites listed as file:line):
- home Ana Sayfa / Home: phone_nav_row 59, toolbar_nav_sections 59, top_navigation_bar 118
- pages Sayfa Paneli / Pages: phone_nav_row 69, nav_sections 67, top_navigation_bar 127
- ruler Cetvel / Ruler: phone_nav_row 78, nav_sections 249, widgets/reorderable_tool_list 122
- audio Ses Kaydı / Audio recording: phone_nav_row 86, nav_sections 278, top_navigation_bar 174, reorderable_tool_list 123
- readerMode Okuyucu Modu / Reader mode, and editMode Düzenleme Modu / Edit mode: the ternaries at phone_nav_row 94, nav_sections 240, top_navigation_bar 155
- more Daha Fazla / More: phone_nav_row 101, nav_sections 293, top_navigation_bar 187
- layers Katmanlar / Layers: nav_sections 258
- addPage Sayfa Ekle / Add page: nav_sections 268, top_navigation_bar 165
- export Dışa Aktar / Export: nav_sections 286, top_navigation_bar 181
- ai Yapay Zeka / AI assistant: compact_bottom_bar 94, medium_toolbar 169, tool_bar 181
- untitled İsimsiz Not / Untitled note: phone_nav_row 33 (delete the `static const untitled`; use it at line 63)
- moreColors Daha Fazla Renk / More colors: quick_access_row 89, 91, 110
- colorSetHighlighter Vurgulayıcı / Highlighter, and colorSetPastel Pastel / Pastel: quick_access_row 156-157 (`ColorSets.all` is 3b)
- selectedColor(hex) `Seçili renk {hex}` / `Selected color {hex}`, and color(hex) `Renk {hex}` / `Color {hex}`: quick_access_row 199-200
- thickness(value) `Kalınlık {value}` / `Thickness {value}`: quick_thickness_chips 98
- moreTools Daha fazla araç / More tools: toolbar_overflow_menu 41
- readOnlyActive Salt okunur mod aktif / Read-only mode on: toolbar_reader_badge 15, top_navigation_bar 199
- readOnly Salt okunur / Read-only: toolbar_reader_badge 35, top_navigation_bar 216
- undo Geri al / Undo: toolbar_widgets 29, widgets/floating_undo_redo 41
- redo İleri al / Redo: toolbar_widgets 35, floating_undo_redo 53
- recordingInProgress Kayıt devam ediyor… / Recording…: top_nav_menus 208
- record Kaydet / Start recording: top_nav_menus 217
- micPermissionRequired `Mikrofon izni gerekli. Lütfen ayarlardan izin verin.` / `Microphone access is required. Please allow it in Settings.`: top_nav_menus 226-227
- showRecordings Kayıtları göster / Show recordings: top_nav_menus 244
- settings panel (`panels/toolbar_settings_panel.dart`): the title at 81 reuses `tools.toolbarSettings`; settingsTabTools Araçlar / Tools (119); settingsTabExtraTools Ek Araçlar / Extra tools (120); settingsToolsHint Araçları sıralayın ve gizleyin / Reorder and hide tools (146); settingsExtraToolsHint Ek araçları sıralayın ve gizleyin / Reorder and hide extra tools (180); settingsReset Varsayılana Sıfırla / Reset to default (215)

The placeholder keys (`editorToolbarSelectedColor`, `editorToolbarColor`, `editorToolbarThickness`) need `@key` metadata with `"type": "String"`.

## 4. Steps (each is one implementer run; no SDK locally, so CI and the workflow verify)
Every step ends with `git push` and checking CI (`gh api repos/aktasilyas/pdf-drawing-tool/commits/<sha>/check-runs`).
1. **Infrastructure + ToolType + ARB keys.**
   - Create the 6 `lib/src/l10n/*` files, the barrel export and `ToolTypeLabel`. Delete `displayName` and migrate every caller listed in section 2, including the 3 drawing_ui tests.
   - In `example_app/integration_test/helpers/l10n.dart`, add `DrawingStrings get drawingStrings => element(find.byType(Scaffold).first).drawingStrings;` and use it in `editor_robot.dart:86,110`.
   - Add every key from section 3 to `app_en.arb` and `app_tr.arb`. Do not touch the generated `app_localizations*.dart` files.
   - New test `test/l10n/drawing_strings_test.dart`: with no scope, the fallback is TR; a scope overrides it; every `ToolType` label is non-empty and distinct; `toMap()` values are non-empty.
   - Push, then dispatch `update-goldens` with `inputs[package]=packages/drawing_ui`. Run `git fetch && git merge origin/claude/324-editor-l10n-toolbar`. Verify with `git show --stat HEAD`: the workflow commit should touch only `example_app/lib/l10n/*` and formatting. Any changed PNG is a defect.
2. **Toolbar part A:** phone_nav_row, toolbar_nav_sections, top_navigation_bar, toolbar_reader_badge, toolbar_widgets, toolbar_overflow_menu, tool_button.
   - Before editing, move `ToolbarNavLeft` (lines 18-87) out of `toolbar_nav_sections.dart` (300 lines) into a new `toolbar/toolbar_nav_left.dart`, and export it from `toolbar/toolbar.dart` and `drawing_ui.dart`.
   - Verify: CI analyze and the drawing_ui tests; `wc -l` ≤ 300.
3. **Toolbar part B + widgets/panel:** top_nav_menus, quick_access_row, quick_thickness_chips, compact_bottom_bar, medium_toolbar, tool_bar, widgets/floating_undo_redo, widgets/reorderable_tool_list, panels/toolbar_settings_panel.
   - Verify: CI drawing_ui tests unchanged and green.
4. **example_app wiring** (needs the l10n commit from step 1).
   - Add the 4 files under `features/editor/presentation/l10n/`, the barrel exports and the `main.dart` builder wrap.
   - Add `test/features/editor/presentation/l10n/app_drawing_strings_test.dart`, modeled on `library_labels_test.dart` (uses `lookupAppLocalizations`). For en and tr, every `tools.toMap()`/`toolbar.toMap()` value is non-empty and tool labels are distinct. tr maps equal `const DrawingStringsTr()` maps (key sets too). en differs from tr for at least the nav keys.
   - Add `test/features/editor/presentation/l10n/editor_toolbar_l10n_test.dart`, modeled on `settings_text_scale_test.dart`. It uses `localizedApp(locale:, builder: (c, child) => AppDrawingStringsScope(child: _scaled(c, child)))`, `ProviderScope` with drawing_ui `sharedPreferencesProvider`, `audioRecordingEnabledProvider` false and 2 pages, and `Scaffold(body: DrawingThemeProvider(child: AdaptiveToolbar()))`.
   - Matrix: {en, tr} × {390x844, 1280x800} × {normal, reader mode}. Assert `find.byTooltip(s.toolbar.home)`, `s.toolbar.undo`, `ToolType.ballpointPen.label(s)`, `s.toolbar.readOnly` (reader mode only), and `expectNoOverflow` from `helpers/a11y.dart`. Under en it also checks that `find.byTooltip('Ana Sayfa')` finds nothing.
5. **Guard + robots.**
   - Copy `example_app/test/helpers/hardcoded_strings.dart` to `packages/drawing_ui/test/helpers/hardcoded_strings.dart`.
   - New `packages/drawing_ui/test/l10n/hardcoded_strings_guard_test.dart`: migrated = `lib/src/toolbar`, `lib/src/models/tool_type.dart`, `lib/src/widgets/floating_undo_redo.dart`, `lib/src/widgets/reorderable_tool_list.dart`, `lib/src/panels/toolbar_settings_panel.dart`; excluded = `lib/src/l10n/`. Add 2 sanity tests of the scanner.
   - Robots, replacing the literal with `tester.drawingStrings.toolbar.*`: `editor_robot.dart:41` home, `:178` undo, `:182` redo; `pdf_robot.dart:72` export, `:76` more; `pages_robot.dart:57` more, `:71` pages. Leave the 3b/3c literals (`Kapat`, eraser panel labels, `PDF Paylaş`, `Sayfa Ekle`, `Boş`).
   - Hand-format `integration_test/`, because the workflow does not format it.
   - Final checks: CI green; dispatch `update-goldens` once more and expect no PNG changes; dispatch E2E on the branch.

## 5. Risks and left out
- If the E2E emulator locale is English, the toolbar is English after step 4. That is why the robot migration must land in this PR (step 5) before E2E runs.
- `toMap()` is maintained by hand, so a getter missing from it escapes the drift test. Mitigations: a doc comment on every strings class, and review.
- Out of scope (3b/3c): `ColorSets.all` names, panels, page sidebar, the `DocumentTitleButton`/`document_provider` "İsimsiz Not", `mock_canvas` copy and the `Kapat` tooltip.
- No RTL work and no in-app language picker.

## 6. Reference check
GoodNotes, StarNote and Flexcil follow the system language with no in-app picker and localize all editor chrome, including tool names, tooltips and menus. We do the same through the app locale, migrating slice by slice. There are no deviations.
