# Plan #327: editor l10n slice 3c (page, document, export, templates, errors)

Same pattern as #324/#326: abstract strings group with a hand-written `toMap()` and a const `*Tr` subclass in `packages/drawing_ui/lib/src/l10n/`, a getter on `DrawingStrings`/`DrawingStringsTr`, `App*` classes in `example_app/lib/features/editor/presentation/l10n/`, keys appended to both ARBs. Line numbers checked on `623089f` (based on #337, slice 3b).

A Python port of `test/helpers/hardcoded_strings.dart` over `packages/drawing_ui/lib/src` flags 188 literals in 58 files; a second heuristic pass found ASCII-only copy the guard misses (`'Bu sayfa'`, `'Izgara'`, `'Kare'`, `'Sayfa eklendi'`, ...). Both are covered below.

## 1. Acceptance criteria
- **Guard:** `hardcoded_strings_guard_test.dart` scans all of `lib/src`; only exclusions are `lib/src/l10n/` and the 7 frozen files in 2.7. A test fails if an excluded path no longer exists. The `migrated` list is deleted.
- **No copy in services/providers:** they return typed failures (2.3); widgets map them through `DrawingStrings`.
- **ARB:** `editorPage*`, `editorPageList*`, `editorExport*`, `editorTemplate*`, `editorError*`, `editorCanvas*` keys 1:1 in `app_en.arb`/`app_tr.arb` with the same placeholders. TR verbatim except 2.8. Drift tests cover every new getter. No golden PNG changes.
- **Widget test:** PageOptionsPanel, ExportPanel, TemplatePicker and FloatingExportProgress (error state) in en and tr at 390x844 and 1280x800, text scale 1.3, no overflow.
- **Robots:** no Turkish literals in editor flows (`pages_robot`, `pdf_robot`, `pdf_flow_test`).
- **CI:** analyze, tests and E2E green.

## 2. Design
### 2.1 New strings groups (each file ≤300 lines)
| File | Class / getter | Covers |
|---|---|---|
| `page_strings.dart` | `PageStrings` / `pages` | page options menu, page actions and snackbars, go-to dialog, document options, scroll direction |
| `page_list_strings.dart` | `PageListStrings` / `pageList` | page indicator, sidebar, thumbnails, add-page panel, drop hint, last-page placeholder |
| `export_strings.dart` | `ExportStrings` / `export` | export panel and options, file dialogs and names, progress (replaces `panels/export_strings.dart`) |
| `template_strings.dart` | `TemplateStrings` / `templates` | template picker, paper size/orientation/colour, infinite background, `templateName(Template)`, `categoryName(TemplateCategory)` |
| `error_strings.dart` | `ErrorStrings` / `errors` | export failures, PDF import failures, PDF page placeholders |
| `canvas_strings.dart` | `CanvasStrings` / `canvas` | layers, zoom bar, pen box, image panel, placement hints, colour strip, text style popup |
| `error_labels.dart` (pure Dart) | | `ExportFailureLabel.message(DrawingStrings)`, `PdfImportFailureLabel.message(DrawingStrings)` |

- `templateName`/`categoryName` are not ARB keys: Tr returns `t.name`/`c.displayName`; the App version returns `nameEn`/`displayNameEn` unless `localeName` starts with `tr` (same rule as `library_labels.localizedName`, inlined because editor must not import documents/presentation).
- `toMap()` samples: `TemplateRegistry.blank`, `TemplateCategory.basic`, ints 1/2/10, String `'Notes'`.

### 2.2 example_app
`AppPageStrings`, `AppPageListStrings`, `AppExportStrings`, `AppTemplateStrings`, `AppErrorStrings`, `AppCanvasStrings`; `AppDrawingStrings` gets 6 fields; all exported from `features/editor/editor.dart`. `pdf_file_importer.dart` stays in `pendingL10n` (library slice) but its API use changes: read `context.drawingStrings` before the await, show `importResult.failure?.message(strings) ?? strings.errors.pdfOpenFailed`, catch path `pdfImportFailureFor(e).message(strings)`.

### 2.3 Typed failures (mapped to text only in widgets)
- `services/export_errors.dart`: `enum ExportFailure { storageFull, cannotWrite, failed, noPages }`; `exportFailureFor(Object)` replaces `friendlyExportError`; the three `export*Message` consts are deleted.
- `pdf_export_models.dart`: `PDFExportResult.errorMessage` → `ExportFailure? failure`, `.error(ExportFailure)`, `wasCancelled => !isSuccess && failure == null`.
- `pdf_exporter.dart`: `'Sayfa bulunamadı'` → `ExportFailure.noPages`; catch uses `exportFailureFor(e)`.
- New `services/pdf_import_failure.dart` (pure Dart): `enum PdfImportError { passwordProtected, fileAccess, openFailed, pagesUnreadable, tooManyPages }`, `final class PdfImportFailure { const PdfImportFailure(this.error, {this.pageCount = 0, this.maxPages = 0}); ==/hashCode }`.
- `pdf_import_errors.dart`: `pdfImportFailureFor(Object)` replaces `friendlyPdfImportError`; `pdfPasswordProtectedMessage` deleted; ArgumentError/StateError map to `openFailed`.
- `pdf_import_models.dart`: `PDFImportServiceResult.errorMessage` → `PdfImportFailure? failure`.
- `pdf_import_service.dart`: `_unreadablePagesMessage` deleted (check becomes `failure?.error != PdfImportError.pagesUnreadable`); too-many-pages returns `PdfImportFailure(tooManyPages, pageCount:, maxPages:)`.
- `add_page_import_helper.dart`: `onError` → `void Function(PdfImportFailure)?`.
- `providers/export_progress_provider.dart`: `errorMessage` → `ExportFailure? failure`, `setError(ExportFailure)`; `String estimatedTimeRemaining` → `Duration? get remaining`, formatted by the widget with `export.remainingSeconds/Minutes`.
- `providers/pdf_provider.dart`: state models retyped; `importProgressMessageProvider`/`exportProgressMessageProvider` (English copy, test-only callers) deleted.
- `providers/document_provider.dart`: default title becomes `''`; display falls back to `toolbar.untitled` when null/empty (`document_title_button.dart`, `phone_nav_row.dart`); empty title gives export file name `export.fallbackFileName`.

### 2.4 APIs that need strings outside a build
Callers capture strings before `onClose()`/`await`.
- `performPagesPDFExport`, `performPDFExport`, `PDFExportRunner.run`, `performPNGExport`, `exportCurrentPageAsPNG` take `required ExportStrings strings`.
- `buildExportFilename(title, {required String fallback})`, `sanitizeFilename(title, {required String fallback})`.
- `showPageUndoSnackBar(..., String message, {required String undoLabel})`.
- `colorSemanticsLabel(Color)` → `colorHex(Color)` (`'#RRGGBB'`); callers use `s.toolbar.color(colorHex(c))`.
- `PdfBackgroundStrings` and its export deleted; `PdfPagePlaceholder` reads `context.drawingStrings.errors`.
- `AddPagePosition` loses `label`; label function in `add_page_panel_widgets.dart`.
- `paperColorPresets` → `enum PaperColorPreset { white, cream, black }` with `color`, label function in `template_picker_helpers.dart`.
- Infinite background options become `(pattern, label fn)` records.

### 2.5 Splits to stay ≤300 lines
- `export_panel.dart`: `performPDFExport`, `performPagesPDFExport`, `PDFExportRunner`, `pdfExportRunnerProvider` move to `panels/pdf_export_action.dart` (re-exported from `export_panel.dart`).
- `add_page_panel.dart`: template/action sections move to `panels/add_page_panel_sections.dart`.

### 2.6 Dead code deleted instead of localized (no caller in lib or example_app)
- `widgets/page_navigator.dart` (+ export, `test/widgets/page_navigator_test.dart`)
- `canvas/mock_canvas.dart` (+ exports, references in `test/drawing_screen_test.dart`)
- `panels/toolbar_editor_panel.dart` (+ exports, `test/panels/toolbar_editor_panel_test.dart`)
- `showRotatePageDialog` + `_rotateOption` in `page_options_helpers.dart`

### 2.7 Guard exclusions and non-copy
- Frozen: `lib/src/panels/ai_assistant_panel.dart`, `lib/src/panels/audio_recording_dropdown.dart`, `lib/src/providers/audio_recording_provider.dart`, `lib/src/screens/audio_recording_list_item.dart`, `lib/src/screens/audio_recordings_list.dart`, `lib/src/screens/audio_rename_dialog.dart`, `lib/src/widgets/floating_recording_bar.dart`.
- `// l10n-ignore`: `panel_section.dart` `'PRO'`/`'Premium'`; `text_style_popup.dart` B/I/U glyphs.
- Not copy, left as is: command descriptions, `toString`s, `'Layer 1'` data defaults in importers, `generatePageName`, `'Elyanotes'` PDF creator, paper size names `A4`/`Letter`/`Legal`.

### 2.8 Copy deviations (no test or golden asserts them)
1. ASCII TR fixed: `Katmani Sil` → `Katmanı Sil`, `Katmani Kopyala` → `Katmanı Kopyala`, `Goster` → `Göster`, `Kilidi Ac` → `Kilidi Aç`, `Resmi yerlesirmek icin dokunun` → `Resmi yerleştirmek için dokunun`.
2. English-only copy gets Turkish: `'Failed to\ngenerate'` → `Önizleme\noluşturulamadı`; StabilizationSlider `'Stabilization'` reuses `panels.stabilization`.
3. `'Sayfa bulunamadı'` merges into `errors.exportNoPages`; the `'PDF dışa aktarılamadı'` fallback becomes `failure ?? ExportFailure.failed`.
4. Raw error text no longer shown: PDF import ArgumentError/StateError; `pdf_background` logs the raw error instead.
5. Document default title (2.3).

## 3. Literal inventory
ARB key = prefix + capitalized getter. Placeholders are `int` unless marked `S` (String).

**Reused getters:** `toolbar.export` (page_options_panel, export panel title), `toolbar.addPage` (page_options_panel), `toolbar.undo` (page_options_actions, page_structure_undo), `toolbar.untitled` (document_title_button), `toolbar.layers` (layer_list_header), `toolbar.color(hex)` (color_chip), `panels.cancel` (page_options_actions, page_options_helpers, page_indicator_bar, template_picker), `panels.clearPage`/`clearPageConfirm` (page_options_actions), `panels.textColor`/`size`/`textStyle` (text_style_popup), `panels.stabilization` (thickness_slider), `selection.delete` (sticky_note_menu), `selection.color` (color_picker_strip), `selection.more` (unified_color_picker), `tools.image` (add_page_panel).

**pages.\*** (`editorPage`): rename Yeniden Adlandır/Rename; moveDocumentToTrash Çöpe Taşı/Move to trash; documentOptions Doküman Seçenekleri/Document options; pageNumber(number) `Sayfa {number}`/`Page {number}`; bookmarkPage Yer imi koy/Bookmark page; removeBookmark Yer imini kaldır/Remove bookmark; copyPage Sayfayı kopyala/Copy page; pastePage Sayfayı yapıştır/Paste page; duplicatePage Sayfayı çoğalt/Duplicate page; changeTemplate Şablonu değiştir/Change template; goToPageMenu Sayfaya git/Go to page; exportPagePdf PDF olarak dışa aktar/Export page as PDF; clearPageMenu Sayfayı temizle/Clear page; movePageToTrash Çöpe taşı/Move to trash; settings Ayarlar/Settings; editToolbar Araç Çubuğunu Düzenle/Edit toolbar; scrollDirection Kaydırma yönü/Scroll direction; scrollHorizontal Yatay/Horizontal; scrollVertical Dikey/Vertical; pageCopied Sayfa kopyalandı/Page copied; pagePasted Sayfa yapıştırıldı/Page pasted; pageDuplicated Sayfa çoğaltıldı/Page duplicated; lastPageCannotDelete Son sayfa silinemez/The last page can't be deleted; pageDeleted Sayfa silindi/Page deleted; clearPageQuestion(page) `Sayfa {page} temizlensin mi?\nBu işlem geri alınabilir.`/`Clear page {page}?\nYou can undo this.`; pageAdded Sayfa eklendi/Page added; pageMoved Sayfa taşındı/Page moved; goToPage Sayfaya Git/Go to page; go Git/Go.

**pageList.\*** (`editorPageList`): pageOf(page, count) `Sayfa {page} / {count}`/`Page {page} of {count}`; pageRangeOf(first, last, count) `Sayfa {first}-{last} / {count}`/`Pages {first}–{last} of {count}`; previousPage Önceki Sayfa/Previous page; nextPage Sonraki Sayfa/Next page; goToPageHint(pageLabel S) `{pageLabel}, Sayfaya gitmek için dokunun`/`{pageLabel}, tap to go to a page`; addPage Sayfa ekle/Add page; addBookmark Yer imi ekle/Add bookmark; noBookmarks Henüz yer imi yok/No bookmarks yet; noBookmarksHint `Bir sayfayı işaretlemek için küçük resmindeki yer imi simgesine dokunun.`/`Tap the bookmark icon on a thumbnail to bookmark that page.`; filterAllPages Tüm sayfalar/All pages; filterBookmarks Yer imleri/Bookmarks; filterRecordings Ses kayıtları/Recordings; pageOptions Sayfa seçenekleri/Page options; thumbnailFailed `Önizleme\noluşturulamadı`/`Preview\nunavailable`; dropToAddPage `Yeni sayfa eklemek için\nsürükleyip bırakın`/`Drag and drop\nto add a new page`; positionBefore Önce/Before; positionAfter Sonra/After; lastPage Son sayfa/Last page; moreTemplates Daha Fazla Şablon/More templates; takePhoto Fotoğraf çek/Take photo; importFile İçe aktar/Import.

**export.\*** (`editorExport`): scopeAll Tümü/All; scopeCurrent Bu sayfa/This page; scopeRange Aralık/Range; from Başlangıç/From; to Bitiş/To; includeTemplate Sayfa şablonunu dahil et/Include page template; exportPng PNG Olarak Dışa Aktar/Export as PNG; exportPdf PDF Olarak Dışa Aktar/Export as PDF; sharePdf PDF Paylaş/Share PDF; invalidRange(count) `Sayfa aralığı 1 ile {count} arasında olmalı.`/`The page range must be between 1 and {count}.`; savePdfDialog PDF Kaydet/Save PDF; savePngDialog PNG Kaydet/Save PNG; fallbackFileName doküman/document; pageFileName(title S, page) `{title}_sayfa{page}`/`{title}_page{page}`; exporting `PDF Dışa Aktarılıyor...`/`Exporting PDF…`; percent(percent) `%{percent}`/`{percent}%`; remainingSeconds(seconds) `~{seconds} sn`/`~{seconds} s`; remainingMinutes(minutes) `~{minutes} dk`/`~{minutes} min`; saved PDF Kaydedildi/PDF saved; savedWithSize(size S) `PDF Kaydedildi ({size})`/`PDF saved ({size})`; cancelled İptal edildi/Cancelled.

**errors.\*** (`editorError`): exportStorageFull `Dışa aktarma için yeterli depolama alanı yok. Yer açıp tekrar deneyin.`/`Not enough storage to export. Free up space and try again.`; exportCannotWrite `Dosya yazılamadı. Tekrar deneyin.`/`Couldn't write the file. Try again.`; exportFailed `Dışa aktarılamadı. Tekrar deneyin.`/`Export failed. Try again.`; exportNoPages Dışa aktarılacak sayfa yok/There are no pages to export; pdfPasswordProtected `Bu PDF parola korumalı. Parolayı kaldırıp tekrar deneyin.`/`This PDF is password-protected. Remove the password and try again.`; pdfFileAccess `PDF dosyasına erişilemedi.`/`Couldn't access the PDF file.`; pdfOpenFailed `PDF açılamadı. Dosya bozuk olabilir.`/`Couldn't open the PDF. The file may be damaged.`; pdfPagesUnreadable `PDF sayfaları okunamadı. Dosya bozuk olabilir.`/`Couldn't read the PDF pages. The file may be damaged.`; pdfTooManyPages(count, max) `PDF çok fazla sayfa içeriyor ({count}). Maksimum {max} sayfa destekleniyor.`/`This PDF has too many pages ({count}). Up to {max} pages are supported.`; pdfPagePlaceholder PDF Sayfası/PDF page; pdfSourceMissing Kaynak PDF bulunamadı/Source PDF not found; pdfLoadFailed PDF Yüklenemedi/Couldn't load PDF.
(The TR error texts must be copied verbatim from the current source, which wins over this table if they differ.)

**templates.\*** (`editorTemplate`): allCategories Tümü/All; coverTab Kapak/Cover; paperTab Kâğıt/Paper; apply Uygula/Apply; portrait Dikey/Portrait; landscape Yatay/Landscape; paperSquare Kare/Square; paperWidescreen `Geniş (16:9)`/`Widescreen (16:9)`; custom Özel/Custom; colorWhite Beyaz/White; colorCream Krem/Cream; colorBlack Siyah/Black; colorYellow Sarı/Yellow; templatesHeader Şablonlar/Templates; background Arka Plan/Background; backgroundPattern Arka Plan Deseni/Background pattern; patternPlain Düz/Plain; patternDotted Noktalı/Dotted; patternGrid Izgara/Grid; backgroundColor Arka Plan Rengi/Background color. Methods (not ARB): `templateName`, `categoryName`.

**canvas.\*** (`editorCanvas`): addLayer Katman Ekle/Add layer; defaultLayerName(number) `Katman {number}`/`Layer {number}`; deleteLayer Katmanı Sil/Delete layer; duplicateLayer Katmanı Kopyala/Duplicate layer; hideLayer Gizle/Hide; showLayer Göster/Show; lockLayer Kilitle/Lock; unlockLayer Kilidi Aç/Unlock; zoomLock Yakınlaştırma kilidi/Zoom lock; zoomLevel(percent) `Yakınlaştırma {percent}%, favori düzeyler`/`Zoom {percent}%, favorite levels`; favoriteZoom Favori yakınlaştırma/Favorite zoom; penBox(count) `Kalem kutusu, {count} kalem`/`{count, plural, =1{Pen box, 1 pen} other{Pen box, {count} pens}}`; finishEditing Düzenlemeyi bitir/Done editing; editPenBox Kalem kutusunu düzenle/Edit pen box; collapsePenBox Kalem kutusunu daralt/Collapse pen box; removePen Kalemi kaldır/Remove pen; addImage Resim Ekle/Add image; addImageHint Galeriden veya kamerayla resim ekleyin/Add an image from the gallery or camera; fromGallery Galeriden Seç/Choose from gallery; fromGalleryHint Albümden bir resim seçin/Pick an image from your albums; takePhoto Fotoğraf Çek/Take photo; takePhotoHint Kamera ile yeni fotoğraf çekin/Take a new photo with the camera; tapToPlace Yerleştirmek için dokunun/Tap to place; tapToPlaceImage Resmi yerleştirmek için dokunun/Tap to place the image; addColor Renk ekle/Add color; textStyleTitle Metin Stili/Text style; emojiSize Emoji Boyutu/Emoji size; textPreviewSample Merhaba/Hello.

Placeholder keys need `@key` metadata with types in `app_en.arb`.

## 4. Changed APIs and callers
- `ExportStrings` statics → `context.drawingStrings.export`: export_panel, export_options_section, `test/panels/export_panel_scope_test.dart`.
- `strings` parameter on export runners: lib callers export_panel, document_options_panel, page_options_actions; fake runners in `test/toolbar/phone_export_menu_test.dart`, `test/panels/export_options_test.dart`, `test/panels/export_panel_scope_test.dart`, `test/services/pdf_share_export_test.dart`, `test/panels/png_export_action_test.dart`.
- `errorMessage` → `failure`: `test/services/pdf_exporter*_test.dart`, `pdf_import_service_test.dart`, `pdf_import_failure_test.dart`, `export_errors_test.dart`, `test/providers/pdf_provider_test.dart`, `example_app/integration_test/export_memory_test.dart`.
- `friendlyPdfImportError`: add_page_import_helper, `example_app/.../pdf_file_importer.dart`.
- `colorSemanticsLabel` → `colorHex`: `test/widgets/a11y_labels_test.dart`.
- Document title default: `test/providers/document_provider_test.dart`.
- `implements DrawingStrings` fakes in tests change to `extends DrawingStringsTr`.

## 5. Steps
1. **1a** drawing_ui l10n infrastructure: 6 groups, `error_labels.dart`, getters, barrel, pure failure types, delete `panels/export_strings.dart` and migrate its callers, update fakes, drift + label tests.
2. **1b** example_app: ARB keys, 6 `App*` classes, `AppDrawingStrings`, exports, drift test.
3. **2** errors and export pipeline (2.3, 2.4 export items, 2.5 split, document_options_panel, floating_export_progress, png_export_action, export_file_name, add_page_panel `onError`, `pdf_file_importer.dart`, tests in §4).
4. **3** page UI (page_options_*, page_structure_undo, add_page_panel(+sections), add_page_panel_widgets, drawing_screen_navigation, page_sidebar_*, drawing_screen_add_page_preview, page_indicator_bar, page_thumbnail, document_title_button, phone_nav_row, document_provider + test).
5. **4** templates (template_picker/*, infinite_background_*), parallel with 2.
6. **5** canvas and misc (layers/*, zoom_control_bar, floating_pen_box_*, color_chip, color_swatch_grid, color_picker_strip, unified_color_picker, text_style_popup, thickness_slider, image_panel, text_preview_painter, panel_section, placement_indicators, sticky_note_menu, pdf_background, pdf_page_placeholder, secondary_canvas_view, deletions in 2.6, a11y_labels_test), parallel with 2 and 4.
7. **6** guard, `editor_pages_l10n_test.dart` ({en, tr} × {390x844, 1280x800} × 1.3: PageOptionsPanel, ExportPanel(embedded), TemplatePicker, FloatingExportProgress error state), robots; regenerate via workflow (no PNG change); E2E on the branch.

## 6. Robots (`s = tester.drawingStrings`)
- `pages_robot.dart`: add page → `s.toolbar.addPage`; blank template → `s.templates.templateName(TemplateRegistry.blank)`; `s.pageList.pageOptions`; `s.pages.movePageToTrash`; `s.pages.pageDeleted`; `s.toolbar.undo`; `s.pageList.addBookmark`; `s.pageList.filterBookmarks`; `s.pageList.filterAllPages`.
- `pdf_robot.dart`: `s.toolbar.export`, `s.export.sharePdf`.
- `pdf_flow_test.dart`: `'Dosya bozuk olabilir'` → either `s.errors.pdfOpenFailed` or `s.errors.pdfPagesUnreadable`; password → `s.errors.pdfPasswordProtected`.
- `integration_test/` is hand-formatted. Library robot literals belong to the library slice.

## 7. Risks / out of scope
- E2E emulator locale may be English; robot changes must land here.
- `toMap()` is hand-written; review checks completeness.
- Document title `''` default is only visible before load; check `save_document_usecase` only saves a loaded document.
- Dead-code deletion removes public drawing_ui API with no consumer in the repo.
- Out of scope: drawing_core cover names, `PenType.displayNameTr`/`TemplateCategory.displayName` cleanup, example_app documents literals, RTL.

## 8. Reference check
GoodNotes, StarNote and Flexcil follow the system language for page menus, export sheets, template and paper names and error toasts, with no in-app picker; import/export errors are short actionable sentences, never raw exception text. We do the same: typed failures mapped to localized copy, template names in the active locale. Terms follow GoodNotes EN ("Move to trash", "Go to page", "Portrait/Landscape"). No deviation.
