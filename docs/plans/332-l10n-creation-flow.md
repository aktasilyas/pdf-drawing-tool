# Plan: #332 library slice 2b step 5 — creation flow in TR + EN

Continues `docs/plans/201-l10n-library.md` (step 5). One branch `claude/332-l10n-creation-flow`,
one PR; each step below is one commit / one implementer run. No Flutter SDK in agent sessions:
every step ends with push → dispatch `update-goldens.yml` (runs `flutter gen-l10n`, commits
`lib/l10n/*.dart` + goldens) → `git fetch && git merge` → CI `analyze` + `test` green.
Folder management (`manage_folders*`, `move_to_folder*`) stays in #333.

## Acceptance (from the issue)
- `new_document_dialog`, `new_document_importers`, `pdf_file_importer`, `format_picker_sheet`,
  `folder_color_picker`, `template_selection_screen`, `template_category_tabs`, `template_grid`,
  `template_preview_section` leave `pendingL10n`; guard passes. `document_card_helpers.dart` is
  already migrated (#331) — nothing to do. Residue the scanner misses is cleared too:
  `cover_grid.dart` (`'Baslik'`), `template_grouped_list.dart` (`category.displayName`).
- New `library*` keys in both ARBs. TR = today's literal, except the ASCII typos on the
  template screen (`Iptal`, `Olustur`, `Yeni not olustur`, `Sablon`, `Kagit`, `Baslik`,
  `Not Basligi`, `Isimsiz Not`), which get proper Turkish letters (rule of #201; no golden
  covers these widgets, so all goldens stay pixel-identical).
- Template/category names follow the locale via `localizedName` (`nameEn`/`displayNameEn`).
- `PaperColor` keeps only the persisted value (`storageKey`, unchanged — stored data);
  display labels live in `presentation/l10n/library_labels.dart` (`PaperColorL10n.label`).
- `library_text_scale_test.dart` covers the new-document menu and the format sheet at 1.3,
  tr+en, 390x844; a new test covers the template screen the same way.
- Creation-flow robots use `tester.l10n` / widget types, no Turkish literals.

## Design
- **Access.** `context.l10n` (`package:example_app/l10n/l10n.dart`). Functions that cross async
  gaps (`importPdfFile`, `importImage`, `importPdf`, `_createQuickNote`, `_createWhiteboard`)
  read `final l10n = context.l10n;` before the first `await`, like the existing
  `messenger`/`router` captures. `showMenu` items: `_buildMenuItem` takes the label from the
  caller, which resolves it from `context.l10n` before `showMenu`.
- **Enum labels.** Extend `library_labels.dart` (stays < 150 lines):
  `NewDocumentOptionL10n.label(l)` (5 menu items) and `PaperColorL10n.label(l)` (exhaustive,
  7 values). Both `_getPresetName` copies (format sheet, preview section) are deleted in favour
  of the existing `PaperSizePresetL10n.label`. `'${w} x ${h} mm'` → `// l10n-ignore`.
- **Persisted values.** `new_document_dialog` writes `PaperColor.white.storageKey` instead of the
  `'Beyaz kağıt'` literal. `paper_color.dart`: doc comment only ("not display copy; see
  `PaperColorL10n`"); no API change, `tryParse` untouched. The mapper's consumer is
  `PaperColorPalette`: each swatch gets `Semantics(label: color.label(l), selected: …,
  button: true)` — no pixel change, closes an a11y gap so the mapper is not dead code.
- **Generated titles are user data.** Quick note / whiteboard / untitled titles are localized
  once at creation and stored; the date part keeps today's `yyyy-MM-dd HH:mm` substring.
- **Errors.** Image import catch keeps `commonErrorDetail('$e')` (TR "Hata: …" unchanged) and
  additionally logs via `logger`. `importResult.errorMessage` (drawing_ui) is passed through.

## ARB keys (EN / TR; `{x}` String unless noted)
- S1: libraryNewNotebook Notebook / Not Defteri; libraryNewWhiteboard Whiteboard / Beyaz Tahta;
  libraryNewQuickNote Quick note / Hızlı Not; libraryImportPdf Import PDF / PDF İçe Aktar;
  libraryImportImage Import image / Resim İçe Aktar; libraryQuickNoteTitle(date) "Quick note -
  {date}" / "Hızlı Not - {date}"; libraryWhiteboardTitle(date) "Whiteboard - {date}" / "Beyaz
  Tahta - {date}"; libraryPdfReadFailed Couldn't read the PDF file / PDF dosyası okunamadı;
  libraryImageReadFailed Couldn't read the image file / Resim dosyası okunamadı;
  libraryImageLoading Loading image... / Resim yükleniyor...; libraryImageTooLarge "Image is
  too large. Maximum size: 4096x4096" / "Resim çok büyük! Maksimum boyut: 4096x4096";
  libraryPdfTooLarge "PDF is too large. Maximum size: 200 MB" / "PDF dosyası çok büyük!
  Maksimum boyut: 200MB"; libraryPdfOpening Opening PDF... / PDF açılıyor...;
  libraryPdfImportFailed Couldn't import the PDF / PDF import başarısız; libraryOpening(title)
  "Opening {title}" / "{title} açılıyor"; libraryOpeningWithPages(title, pages) "Opening {title}
  ({pages})" / "{title} açılıyor ({pages})" with pages = existing `libraryPageCount(n)`.
- S2: libraryFormat Format / Format; libraryOrientation Orientation / Yön; libraryPortrait
  Portrait / Dikey; libraryLandscape Landscape / Yatay; librarySize Size / Boyut;
  libraryFormatSummary(orientation, size) "{orientation}, {size}" (both); libraryCover Cover /
  Kapak; libraryPaper Paper / Kağıt; libraryTitle Title / Başlık; libraryNoteTitleHint Note
  title / Not Başlığı. Reuse commonOk ("Tamam").
- S3: libraryTemplateCategoryAll All / Hepsi; libraryNoTemplatesInCategory No templates in
  this category / Bu kategoride şablon yok.
- S4: libraryCreateNoteTitle Create new note / Yeni not oluştur; libraryTemplate Template /
  Şablon; libraryUntitledNote Untitled note / İsimsiz Not. Reuse commonCancel, commonCreate.
- S5: libraryPaperColor{White,Black,Cream,Gray,Green,Blue,Yellow} "<Colour> paper" / today's
  `storageKey` text (Beyaz kağıt, Siyah kağıt, Krem kağıt, Gri kağıt, Yeşil kağıt, Mavi kağıt,
  Sarı kağıt); librarySelectColor Choose a color / Renk Seç (#333 reuses it). Reuse commonCancel.
Every placeholder gets `"type"` in `@key`; same placeholder set in en/tr (guard test).

## Steps (one implementer run each; verify = push, dispatch update-goldens, merge, CI green;
## with a local SDK: `cd example_app && flutter gen-l10n && flutter analyze && flutter test test/l10n test/features/documents`)
1. **New-document menu + importers.** Files: `lib/l10n/app_en.arb`, `app_tr.arb` (S1),
   `widgets/new_document_dialog.dart`, `widgets/new_document_importers.dart`,
   `widgets/pdf_file_importer.dart`, `l10n/library_labels.dart` (`NewDocumentOptionL10n`),
   `test/l10n/hardcoded_strings_guard_test.dart` (drop 3 entries),
   `screens/library_text_scale_test.dart` (+ "new-document menu": tap `LibraryNewButton`, expect
   `l10n.libraryImportImage`, no overflow). Enum coverage test for the new extension lands in
   step 5 (keeps this step at 8 files).
2. **Format sheet + preview section.** ARBs (S2), `widgets/format_picker_sheet.dart`,
   `widgets/template_preview_section.dart`, `widgets/cover_grid.dart`, guard (drop 2),
   `library_text_scale_test.dart` (+ "format sheet": pump a `Builder` that calls
   `FormatPickerSheet.show(context, PaperSize.a4)` inside `localizedApp`, expect
   `l10n.libraryOrientation`, no overflow). `cover_grid_test.dart` stays green.
3. **Template catalogue.** ARBs (S3), `widgets/template_category_tabs.dart`,
   `widgets/template_grid.dart`, `widgets/template_grouped_list.dart` (`localizedName` for
   `category.displayName/displayNameEn` and `template.name/nameEn`), guard (drop 2). New
   `test/features/documents/presentation/widgets/template_catalogue_l10n_test.dart`: en shows
   `TemplateRegistry.blank.nameEn` and `libraryTemplateCategoryAll`; tr shows `name`.
4. **Template screen + robots.** ARBs (S4), `screens/template_selection_screen.dart`, guard
   (drop 1), new `screens/template_selection_text_scale_test.dart` (1.3, tr+en, 390x844; cover
   tab and paper tab; override `documentsControllerProvider`/`currentFolderIdProvider` as in
   `library_fixtures.dart`), `integration_test/robots/library_robot.dart` (`createNotebook`:
   `tester.l10n.libraryNewNotebook`, wait for `find.byType(TemplateSelectionScreen)`, tap
   `find.widgetWithText(AppButton, l10n.commonCreate)`; doc comments without Turkish),
   `integration_test/robots/new_notebook_robot.dart` (same three finders).
5. **Paper colours + folder colour picker.** ARBs (S5), `l10n/library_labels.dart`
   (`PaperColorL10n`), `widgets/paper_color_palette.dart` (swatch `Semantics`),
   `domain/entities/paper_color.dart` (doc comment), `widgets/folder_color_picker.dart`, guard
   (drop 1; only #333 files remain), `test/.../l10n/library_labels_test.dart` (every
   `PaperColor` and `NewDocumentOption` label non-empty and distinct in en and tr). Then
   dispatch e2e on the branch (`gh api -X POST …/e2e.yml/dispatches -f ref=claude/332-…`).

## Test plan
Guard (pending list, same keys/placeholders), `library_labels_test` (enum coverage),
`template_catalogue_l10n_test` (locale switch of drawing_core names), both text-scale tests
(no overflow tr+en at 1.3), existing `cover_grid_test`, `pdf_file_importer_test`, library
goldens unchanged, e2e shards `phone-a/phone-b/tablet` green on the branch (creation flow,
covers/templates, PDF import in the emulator's locale).

## Risks
- Context after async gaps in importers: capture l10n first or `use_build_context_synchronously`
  lints/crashes. Popup menu items have no localized context unless resolved before `showMenu`.
- New-doc menu in the text-scale test calls `ensureDocumentQuota` → `featureAccessProvider`;
  flags-off default allows it, otherwise override it in the test.
- gen-l10n errors only show in CI; keep each ARB diff small, run the guard ARB tests first.
- The template screen's TR copy changes (ASCII → Turkish letters); robots move to l10n in the
  same PR, so no e2e run sees the mismatch.

## Left out (YAGNI)
`Cover.name` has no English variant in drawing_core (editor slice); raw exception text in the
image-import error (kept as today, cleanup separate); 24dp swatch touch target (#202); locale
date in quick-note titles; drawing_ui PDF import error copy; folder management (#333).

## Reference check
GoodNotes, StarNote and Flexcil follow the system language for every creation dialog, template
and paper name, with no in-app language picker → same: all creation copy and template names come
from `AppLocalizations`/`nameEn`. Auto titles ("Quick note - date") are stored as typed user data
in the creation language, as these apps do with their default titles. No deviation.
