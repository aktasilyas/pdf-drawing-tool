# Plan #326: editor l10n slice 3b (tool settings panels, selection, context menus)

Follows the binding #324 pattern (`docs/plans/324-editor-l10n-toolbar.md`). Line numbers checked on `fd3164a`.

## 1. Acceptance criteria
- **Guard:** no user-facing literal in the scoped files; they are listed in `packages/drawing_ui/test/l10n/hardcoded_strings_guard_test.dart`.
- **Providers hold no copy:** selection actions carry a `SelectionActionKind`; the screenshot flow returns a `SelectionScreenshotOutcome`. Widgets map both to strings.
- **ARB:** `editorPanel*`, `editorCatalog*`, `editorSelection*` keys 1:1 in `app_en.arb`/`app_tr.arb`. `*Tr` values verbatim (exceptions in 2.6) so goldens do not change. Drift tests cover the new getters.
- **Widget test:** every panel/menu renders in en and tr at 390x844, text scale 1.3, no overflow.
- **Robots:** no Turkish literal for these panels.
- **CI:** analyze and tests green.

## 2. Design
### 2.1 Strings classes (`packages/drawing_ui/lib/src/l10n/`, same shape as `toolbar_strings.dart`)
Abstract class with getters + hand-written `toMap()`, plus a const `*Tr` subclass.
- `panel_strings.dart`: `PanelStrings`/`PanelStringsTr`, getter `DrawingStrings.panels` (panel header, pen, highlighter, eraser, laser, text, sticky note, color picker).
- `catalog_strings.dart`: `CatalogStrings`/`CatalogStringsTr`, getter `DrawingStrings.catalog` (shapes panel, shape names, sticker panel, sticker categories).
- `selection_strings.dart`: `SelectionStrings`/`SelectionStringsTr`, getter `DrawingStrings.selection` (lasso panel, selection actions, screenshot messages, context menus).
- `toolbar_strings.dart`: add `colorSetBasic`, `colorSetNeon` (also in `toMap()`) so `ColorSets.all` can go.
- `enum_labels.dart` (pure Dart): `ShapeTypeLabel`, `StickerCategoryLabel`, `SelectionActionKindLabel` with `String label(DrawingStrings)`, exhaustive switches.
- Lasso/laser/eraser enum labels stay as functions in their panel files (their enums live in Flutter-importing provider files). Eraser `_titleForMode`/`_labelFor` merge into one `eraserTypeLabel(ToolType, DrawingStrings)` in `eraser_settings_widgets.dart`.
- Reused 3a strings: pen header title `active.penType == null ? s.tools.penGroup : <tool>.label(s)`; `PenTypePicker` tiles use `ToolType.label(s)`; highlighter `tools.highlighter`/`tools.neonHighlighter`; sticky note `tools.stickyNote`; eraser `tools.strokeEraser`/`tools.lassoEraser`/`tools.pixelEraser`.

### 2.2 example_app (`lib/features/editor/presentation/l10n/`)
`AppPanelStrings`, `AppCatalogStrings`, `AppSelectionStrings` backed by `AppLocalizations`; `AppDrawingStrings` gets 3 fields; `AppToolbarStrings` gets 2 getters; all exported from `features/editor/editor.dart`.

### 2.3 Typed results instead of provider copy
- `models/selection_action_kind.dart`: `enum SelectionActionKind { ai, color, screenshot, cut, duplicate, delete, bringToFront, sendToBack, copy, paste, askAi, takeScreenshot }`.
- `SelectionAction`: `label` removed, `required SelectionActionKind kind` added; `id` stays.
- `selection_capture_actions.dart`: `enum SelectionScreenshotOutcome { captureFailed, savedAndCopied, saved, copied, saveFailed }`, `screenshotOutcomeFor(SelectionImageSaveResult)`; `screenshotSelection` returns `Future<SelectionScreenshotOutcome?>` (null = cancelled / unmounted) and shows no snackbar. `selectionImageSaveMessage` and `showSnackBar` deleted.
- `widgets/selection_screenshot_feedback.dart`: `showSelectionScreenshotFeedback(BuildContext?, SelectionScreenshotOutcome)` maps outcome to text (mounted check first) and shows the snackbar.
- Renderers call `action.kind.label(context.drawingStrings)`.

### 2.4 Catalog data keyed by enum
- `enum StickerCategory { emoji, animals, food, travel, objects, symbols, hands, nature }`; `stickersForCategory(StickerCategory)`, `stickerAt(StickerCategory, int)`; `stickerCategories` = `StickerCategory.values`.
- `ColorSets.all` deleted; `quick_access_row.dart` builds the map from `ToolbarStrings`.

### 2.5 Async and dialog contexts
Eraser clear dialog reads `ctx.drawingStrings` inside its builder. Snackbars after `await` read strings behind a mounted check.

### 2.6 Copy deviations (none asserted by a test or rendered in a golden)
1. Selection toolbar `'Cogalt'` becomes `'Çoğalt'` (one `duplicate` key; tooltip only).
2. `shapes_settings_panel` semantics label was `shape.name` (English identifier); now the localized shape name. Semantics only.
3. `text_context_menu` tooltip `'Kopyala'` calls `onDuplicate`; kept verbatim via `selection.copy`. Follow-up: decide the label.
4. Adjacent files added to finish the flows: `panels/chrome_panel_parts.dart` (`Kapat`), `widgets/selection_toolbar.dart`, `widgets/compact_color_picker.dart`, `widgets/screenshot_preview_dialog.dart`, `widgets/color_presets.dart`.
5. `'B'`/`'I'`/`'U'` glyph buttons in `text_settings_panel.dart` get `// l10n-ignore`.

## 3. Literal inventory
ARB key = prefix + capitalized getter: `editorPanel` (`panels.*`), `editorCatalog` (`catalog.*`), `editorSelection` (`selection.*`), `editorToolbar` (`toolbar.*`). No placeholders.

**panels.\***: close Kapat/Close; thickness Kalınlık/Thickness; pressureSensitivity Basınç Duyarlılığı/Pressure sensitivity; stabilization Çizgi Stabilizasyonu/Stroke stabilization; penType Kalem türü/Pen type; glow Parlaklık/Glow; straightLine Düz çizgi/Straight line; size Boyut/Size; eraserPixel Piksel Silgi/Pixel eraser; eraserPressure Basınç hassasiyeti/Pressure sensitivity; eraserHighlighterOnly Sadece vurgulayıcı sil/Erase highlighter only; eraserAutoLift Otomatik kaldır/Auto-deselect; clearPage Sayfayı Temizle/Clear page; clearPageTitle Sayfayı Temizle?/Clear page?; clearPageMessage "Bu sayfa içeriğini tamamen silecek. Bu işlem geri alınamaz."/"This erases everything on this page. This can't be undone."; cancel İptal/Cancel; clearPageConfirm Temizle/Clear; laserDot Lazer Nokta/Laser dot; laserLine Lazer Çizgi/Laser line; laserHollow Lazer Çizgi (Boş)/Hollow laser line; laserRainbow Lazer Gökkuşağı/Rainbow laser; laserDuration Süre/Duration; textTitle Metin Aracı/Text tool; textHint "Tuvale dokunarak metin kutusu ekleyin."/"Tap the canvas to add a text box."; textColor Renk/Color; textStyle Stil/Style; addNote Not Ekle/Add note; colorHex Altıgen/Hex; colorRed Kırmızı/Red; colorGreen Yeşil/Green; colorBlue Mavi/Blue; colorCancel İptal et/Cancel; colorDone Bitti/Done; colorSwatches Kartelalar/Swatches; colorSpectrum Spektrum/Spectrum.

**catalog.\***: shapesTitle Şekil/Shape; strokeWidth Kontur Kalınlığı/Stroke width; strokeColor Kontur Rengi/Stroke color; fillShape Şekil dolgusu/Fill shape; fillColor Dolgu Rengi/Fill color; shapeLine…shapePlus (Çizgi, Ok, Dikdörtgen, Elips, Üçgen, Eşkenar dörtgen, Yıldız, Beşgen, Altıgen, Artı / Line, Arrow, Rectangle, Ellipse, Triangle, Diamond, Star, Pentagon, Hexagon, Plus); stickersTitle Çıkartmalar/Stickers; addSticker Çıkartma Ekle/Add sticker; stickerEmoji…stickerNature (Emoji, Hayvanlar, Yiyecek, Seyahat, Nesneler, Semboller, Eller, Doğa / Emoji, Animals, Food, Travel, Objects, Symbols, Hands, Nature).

**selection.\***: lassoFreeform Serbest Seçim/Freeform; lassoRectangle Dikdörtgen Seçim/Rectangle; lassoSelectable Seçilebilir/Selectable; typeHandwriting El yazısı/Handwriting; typeShape Şekil/Shapes; typeImage Resim/Images; typeHighlighter Vurgulayıcı/Highlighter; typeText Metin/Text; typeTape Bant/Tape; typeLink Link/Links; typeLabel Etiket/Labels; ai AI Asistan/AI assistant; color Renk/Color; screenshot Ekran Resmi/Screenshot; cut Kes/Cut; duplicate Çoğalt/Duplicate; delete Sil/Delete; bringToFront Öne Getir/Bring to front; sendToBack Arkaya Gönder/Send to back; copy Kopyala/Copy; paste Yapıştır/Paste; askAi Yapay zekaya sor/Ask AI; takeScreenshot Ekran Resmi Çek/Take screenshot; more Daha fazla/More; save Kaydet/Save; screenshotCaptureFailed Ekran resmi oluşturulamadı/Couldn't create the screenshot; screenshotSavedAndCopied "Ekran resmi galeriye kaydedildi ve panoya kopyalandı"/"Screenshot saved to the gallery and copied to the clipboard"; screenshotSaved Ekran resmi galeriye kaydedildi/Screenshot saved to the gallery; screenshotCopied Ekran resmi panoya kopyalandı/Screenshot copied to the clipboard; screenshotSaveFailed Ekran resmi kaydedilemedi/Couldn't save the screenshot; contextEdit Düzenle/Edit; contextStyle Stil/Style; contextMove Taşı/Move.

**toolbar.\*** (new): colorSetBasic Temel/Basic; colorSetNeon Neon/Neon.

## 4. Changed APIs and callers
- `SelectionAction.label` → `kind`: provider, `selection_toolbar_buttons.dart`, `selection_overflow_menu.dart`.
- `screenshotSelection` return type: only `selection_actions_provider.dart`.
- `selectionImageSaveMessage` deleted: `test/services/selection_image_sink_test.dart` asserts `screenshotOutcomeFor`.
- Sticker catalog API now takes `StickerCategory`: `sticker_panel.dart`, `sticker_panel_parts.dart`, `sticker_panel_actions.dart`, `test/panels/sticker_catalog_test.dart`.
- `ColorSets.all` deleted: `quick_access_row.dart`, `test/widgets/color_presets_test.dart`.

## 5. Steps
No SDK in the session: CI and the `update-goldens` workflow (which also regenerates `app_localizations*.dart` and formats) verify.
1. Strings classes, ARB keys, example_app classes, drift tests.
2. Selection typed results, feedback widget, renderers, context menus.
3. Panels A (pen, highlighter, eraser, laser, text, sticky note, color picker, chrome header).
4. Catalog (shapes, lasso, stickers, color sets).
5. Guard list, example_app widget tests, robots; regenerate via workflow; expect no PNG change; E2E on the branch.

## 6. Tests
- `drawing_ui/test/l10n/drawing_strings_test.dart`: new `toMap()` values non-empty; labels non-empty and distinct for `ShapeType`, `StickerCategory`, `SelectionActionKind`.
- `example_app/.../app_drawing_strings_test.dart`: new groups non-empty in en/tr; tr maps equal `DrawingStringsTr`; en≠tr per group with a small allow-list.
- Selection unit tests: every action kind has a label; `screenshotOutcomeFor` covers all results; feedback snackbar shows TR fallback and scope override.
- `example_app/.../editor_panels_l10n_test.dart`: {en, tr} × each panel at 390x844, scale 1.3, no overflow, localized text found, TR literal absent in en.

## 7. Robots
`editor_robot.dart`: eraser type via `ValueKey('eraser-type-<name>')`; close via `tester.drawingStrings.panels.close`.

## 8. Risks / out of scope
- E2E emulator locale may be English, so the robot change must land here.
- `toMap()` is hand-written; review checks completeness.
- `PenType.displayNameTr` in drawing_core is no longer read by the UI; removal is a follow-up.
- Out of scope: page/document/export UI (3c), drawing_screen and AI panel copy, RTL.

## 9. Reference check
GoodNotes, StarNote and Flexcil localize all editor chrome (tool settings, lasso/selection menus, sticker categories) to the system language with no in-app picker. Terms follow GoodNotes EN ("Bring to front", "Freeform"). Same as 3a, no deviation.
