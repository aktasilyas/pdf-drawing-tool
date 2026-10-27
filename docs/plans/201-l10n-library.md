# Plan: #201 slice 2 — library (documents) in TR + EN

Builds on slice 1 (`docs/plans/201-l10n-settings.md`). No Flutter SDK in agent sessions:
every step ends with push → dispatch `update-goldens.yml` (runs `flutter gen-l10n`, commits
`lib/l10n/*.dart` + goldens) → `git fetch && git merge` → CI `analyze` + `test` green.

## Acceptance
- No user-facing literal in `lib/features/documents/presentation/**` and
  `lib/core/widgets/feedback/**` (guard test). `presentation/constants/documents_strings.dart`
  and the unused `widgets/document_context_menu.dart` are deleted.
- Domain/data stay Flutter-free: no `AppLocalizations`/`BuildContext` below presentation.
  User-facing domain rules are typed (`LibraryRule`); presentation maps enums → l10n.
- Dates use `intl` `DateFormat.yMMMd(l10n.localeName)` (tr: "21 Eki 2026", en: "Oct 21, 2026").
- Counts use ICU plurals (en "1 page"/"3 pages"; tr "3 sayfa").
- Library screen, its menus/dialogs, template picker, manage-folders and move-to-folder:
  no overflow at text scale 1.3 on 390x844, tr and en (`library_text_scale_test.dart`).
- Existing widget tests/goldens pass with locale pinned to tr (TR values = current literals,
  so goldens are pixel-identical; regenerate only if the workflow shows a diff).
- E2E robots work in any device locale: library strings come from `tester.l10n`, never
  Turkish literals; finders prefer widget types where one exists.

## Design
- **ARB rules.** Keys `library*`; `common*` for generic verbs. EN text given below, TR value =
  the current Turkish literal verbatim unless "TR:" is stated (ASCII typos are fixed).
  Plurals: `=1{...}` + `other{...}`, every branch contains the placeholder or a space
  (the guard's placeholder regex `\{(\w+)\}` must see the same set in en/tr); tr uses
  `{n, plural, other{...}}`. Every placeholder gets `"type": "int"` or `"String"` in
  `@key`. No `use-escaping`, so `Premium'a` and `"` are literal (escape `"` as `\"` in JSON).
- **Provider messages (no context).** `presentation/providers/library_error.dart`:
  `enum LibraryAction {createDocument, importDocument, moveDocument, toggleFavorite,
  trashDocument, deleteDocument, renameDocument, restoreDocument, duplicateDocument,
  deleteDocumentForever, trashDocuments, deleteDocumentsForever, duplicateDocuments,
  moveDocuments, trashPage, deletePageForever, emptyTrash, createFolder, renameFolder,
  recolorFolder, saveFolderOrder, moveFolder, deleteFolder}`.
  `LibraryError(Failure failure, LibraryAction action)`; `String message(AppLocalizations l)`
  = `LibraryRuleFailure` → `rule.message(l)`, anything else → `action.failureMessage(l)`.
  `reportLibraryFailure(Ref, Failure, LibraryAction)` logs `'${action.name}: ${failure.message}'`.
  `LibraryErrorListener` shows `next.message(context.l10n)`.
- **Domain rules.** New `domain/entities/library_rule.dart`: `enum LibraryRule {folderDepth,
  folderIntoOwnSubfolder, folderMoveDepth, folderWithSubfoldersMove, documentLimit,
  folderLimit}` and `class LibraryRuleFailure extends ValidationFailure` (`const
  LibraryRuleFailure(this.rule) : super('library rule: ...')`, English diagnostic message per
  rule, `props => [...super.props, rule]`). Used in `folder_repository_impl.dart` (4 sites),
  `create_document_usecase.dart`, `create_folder_usecase.dart`. Export from `documents.dart`.
- **Enum labels.** New `presentation/l10n/library_labels.dart` (extensions only, ≤150 lines):
  `LibraryActionL10n.failureMessage`, `LibraryRuleL10n.message`, `SortOptionL10n.label`,
  `PaperSizePresetL10n.label` (A4/A5/A6/Letter/Legal literal + `// l10n-ignore`),
  `SidebarSectionL10n.title`, `localizedName(l, tr:, en:)` = `l.localeName.startsWith('tr') ? tr : en`
  for drawing_core `TemplateCategory.displayName/displayNameEn` and `Template.name/nameEn`.
  Delete the unused `SortOptionExtension`/`SortDirectionExtension` in `sort_option.dart`.
- **Persisted values are not copy.** `PaperColor.storageKey` stays Turkish (stored data);
  presentation defaults use `PaperColor.yellow.storageKey` / `PaperColor.white.storageKey`.
  Data-layer defaults in `document_model.dart`/`document_info.dart`/`document_repository.dart`
  are untouched (not shown, not guarded).
- **Duplicate title.** `DocumentRepository.duplicateDocument(String id,
  {required String Function(String title) copyTitle})`; controller `duplicateDocument(id,
  {required copyTitle})` and `duplicateDocuments(ids, {required copyTitle})`; widgets pass
  `context.l10n.libraryCopyTitle` (tear-off). Repository impl drops the `(kopya)` literal.
- **Dates.** `DocumentDateFormatter.format(DateTime d, String localeName)` →
  `DateFormat.yMMMd(localeName).format(d)`. `LibraryMeta.document(d, l10n)` /
  `LibraryMeta.folder(f, l10n)`. Symbols are loaded by `GlobalMaterialLocalizations` in apps
  and widget tests; pure unit tests call `initializeDateFormatting()`.
- **Core feedback.** `AppConfirmDialog.show` labels become `String?`, defaulting to
  `context.l10n.commonConfirm` / `commonCancel`; `AppModal` close tooltip `commonClose`.
- **Guard.** `migratedDirs` gains `lib/features/documents/presentation` and
  `lib/core/widgets/feedback`, plus `const pendingL10n = <String>{...}` (file paths skipped
  until their step lands; must be empty after step 6, and a test asserts each entry exists).
  The scanner misses Turkish words without Turkish letters; each step also clears the
  "residue" literals listed for its files (e.g. `'Belgelerim'`, `'sayfa'`, `'Not Defteri'`).
- **Tests.** `test/helpers/l10n.dart` `localizedApp` gains `navigatorKey`. Every library widget
  test uses `localizedApp` (tr). **E2E.** `integration_test/helpers/l10n.dart`:
  `extension on WidgetTester { AppLocalizations get l10n => AppLocalizations.of(
  element(find.byType(Scaffold).first)); }` (call only after the library is visible).
  Robots wait for `find.byType(LibraryNewButton)` instead of the `'Yeni Belge'` tooltip.

## Keys (EN text; `{x}` String, `{n}`/`{count}`/`{days}`/`{page}` int)
- **common (step 1):** commonConfirm "Confirm" (TR Onayla), commonCreate "Create" (Oluştur),
  commonDelete "Delete" (Sil), commonDone "Done" (Bitti), commonOk "OK" (Tamam), commonRetry
  "Try again" (Tekrar dene), commonRename "Rename" (Yeniden Adlandır), commonMove "Move" (Taşı),
  commonDuplicate "Duplicate" (Çoğalt), commonRestore "Restore" (Kurtar), commonMenu "Menu"
  (Menü), commonErrorDetail "Error: {error}" (Hata: {error}). Reuse commonCancel/Save/Close/Back,
  settingsTitle (header gear tooltip), settingsPinFavorites (sort menu).
- **errors (step 2):** libraryError<Action> for each `LibraryAction`, EN "Couldn't <verb> …":
  CreateDocument "create the notebook", ImportDocument "import the document", MoveDocument
  "move the notebook", ToggleFavorite "update favorites", TrashDocument "move the notebook to
  the trash", DeleteDocument "delete the notebook", RenameDocument "rename the notebook",
  RestoreDocument "restore the notebook", DuplicateDocument "duplicate the notebook",
  DeleteDocumentForever "delete the notebook permanently", TrashDocuments/
  DeleteDocumentsForever/DuplicateDocuments/MoveDocuments (plural "notebooks"), TrashPage
  "move the page to the trash", DeletePageForever "delete the page permanently", EmptyTrash
  "empty the trash", CreateFolder/RenameFolder/MoveFolder/DeleteFolder "… the folder",
  RecolorFolder "change the folder color", SaveFolderOrder "save the order". TR = the literal at
  each current `reportLibrary*` call (doc+folder favourite share "Favori durumu değiştirilemedi").
  libraryRule*: FolderDepth "Folders can only be one level deep" (TR Alt klasörlerin altına
  klasör oluşturulamaz), FolderIntoOwnSubfolder "A folder can't be moved into its own
  subfolder", FolderMoveDepth "A folder can't be moved into a subfolder", FolderWithSubfoldersMove
  "A folder with subfolders can't be moved into another folder", DocumentLimit "You've reached
  the free limit. Upgrade to Premium.", FolderLimit "You've reached the folder limit. Upgrade to
  Premium." (TRs = current repository/use-case literals).
- **screen chrome (step 3):** librarySectionAll "All notes", librarySectionFavorites
  "Favorites", librarySectionTrash "Recently deleted", libraryFolderFallback "Folder",
  libraryBreadcrumbRoot "Library" (Belgelerim), libraryFolders "Folders" (Klasörler),
  libraryDocuments "Documents" (Belgeler), libraryManage "Manage" (Yönet), libraryNewFolder "New
  folder", libraryNoFolders "No folders", librarySidebarCollapse "Collapse", libraryOpenSidebar
  "Open sidebar", librarySearchHint "Search...", libraryListView "List view", libraryGridView
  "Grid view", librarySelectMode "Select", libraryNewDocument "New document",
  libraryNewDocumentLocked "Document limit reached", libraryNew "New", libraryTrashInfo "Deleted
  notes are permanently removed after 30 days", libraryEmptyTrash "Empty trash",
  libraryEmptyTrashConfirmMessage "Everything in the trash will be deleted permanently. This
  can't be undone." (TR = current two-part literal joined), libraryEmptyTrashConfirm "Empty",
  libraryTrashEmptied "Trash emptied", libraryOpenFailed "Couldn't open the notebook" (TR Belge
  açılamadı; the failure detail is logged, no longer shown), libraryTrashCountsTowardsLimit
  "Notes in the trash count towards the limit. Delete them permanently to free up space, or",
  libraryRemainingDocuments(count) plural "1 document left"/"{count} documents left" (TR
  "{count} belge hakkınız kaldı"), librarySortTitle "Sort", librarySortByDate "By date",
  librarySortByName "By name", librarySortBySize "By size", librarySortNewestFirst "Newest
  first", librarySortOldestFirst "Oldest first", libraryEmptyTitle "No notes yet",
  libraryEmptyMessage "Create a notebook or import a PDF.", libraryEmptyAction "New note",
  libraryEmptyFavoritesTitle "No favorite notes", libraryEmptyFavoritesMessage "Tap the star icon
  to add notes to your favorites", libraryEmptyFolderTitle "This folder is empty",
  libraryEmptyFolderMessage "Move notes here or create a new one", libraryTrashEmptyTitle "Trash
  is empty", libraryTrashEmptyMessage "Deleted notes will appear here", libraryNoResultsTitle
  "No results", libraryNoResultsMessage(query) "No notes match \"{query}\"", libraryClearSearch
  "Clear search", librarySelectedCount(count) "{count} selected", librarySelectAll "All" (Tümü),
  libraryDeleteForever "Delete permanently" (Kalıcı Sil), libraryDeleteForeverTitle "Delete
  permanently?" (Kalıcı Olarak Sil), libraryDeleteDocumentsTitle "Delete notes" (Belgeleri Sil),
  libraryDocumentLimitReached "Document limit reached" (Belge Limitine Ulaştınız),
  libraryDocumentsCopied(count), libraryDocumentsTrashed(count), libraryDocumentsDeleted(count)
  ("{count} documents duplicated/moved to the trash/deleted"), libraryDeleteDocumentsForeverMessage(count)
  "{count} documents will be deleted permanently. This can't be undone.",
  libraryTrashDocumentsMessage(count) "{count} documents will be moved to the trash." (all plural).
- **tiles/menus/trash (step 4):** libraryPageCount(count) "1 page"/"{count} pages" (TR "{count}
  sayfa"), libraryDocumentCount(count) "1 document"/"{count} documents" (TR "{count} belge"),
  libraryDaysLeft(days) "1 day"/"{days} days" (TR "{days} gün"), libraryRemoveFavoriteBadge
  "Remove from favorites" (Favorilerden çıkar), libraryRemoveFromFavorites "Remove from
  favorites" (Favorilerden Kaldır), libraryAddToFavorites "Add to favorites", libraryMoveToTrash
  "Move to trash", libraryDocumentDuplicated "Notebook duplicated", libraryDocumentMoved
  "Notebook moved", libraryDocumentRestored "Notebook restored",
  libraryDeleteDocumentForeverMessage "This notebook will be deleted permanently. This can't be
  undone.", libraryDocumentNameLabel "Notebook name" (Belge Adı), libraryChangeColor "Change
  color", libraryFolderMoved "Folder moved", libraryFolderColorChanged "Folder color changed",
  libraryDeleteFolderTitle "Delete folder", libraryDeleteFolderNonEmptyMessage(count) plural
  "This folder contains {count} documents. Deleting it also deletes them. Continue?" (TR = the
  three joined literals), libraryDeleteFolderMessage "Delete this folder?", libraryFolderDeleted
  "Folder deleted", libraryRenameFolderTitle "Rename folder", libraryFolderNameLabel "Folder name"
  (TR "Klasör adı" — unifies "Klasör Adı"), libraryFolderRenamed(name) "Folder renamed to
  \"{name}\"", libraryPageNumber(page) "Page {page}", libraryTrashedPageTitle(document, page)
  "{document} — Page {page}", librarySourceDocumentMissing "The original notebook no longer
  exists", libraryPageRestored "Page restored", libraryPageRestoreFailed "Couldn't restore the
  page", libraryDeletePageForeverMessage "This page will be deleted permanently. This can't be
  undone.", libraryCopyTitle(title) "{title} (copy)" (TR "{title} (kopya)").
- **creation flow (step 5):** libraryNewNotebook "Notebook" (Not Defteri), libraryNewWhiteboard
  "Whiteboard", libraryNewQuickNote "Quick note", libraryImportPdf "Import PDF",
  libraryImportImage "Import image", libraryQuickNoteTitle(date) "Quick note - {date}",
  libraryWhiteboardTitle(date) "Whiteboard - {date}", libraryUntitledNote "Untitled note" (TR
  İsimsiz Not), libraryCreateNoteTitle "Create new note" (TR Yeni not oluştur), libraryCover
  "Cover", libraryTemplate "Template" (TR Şablon), libraryPaper "Paper" (TR Kağıt), libraryTitle
  "Title" (TR Başlık), libraryNoteTitleHint "Note title" (TR Not Başlığı), libraryFormat
  "Format", libraryOrientation "Orientation", libraryPortrait "Portrait", libraryLandscape
  "Landscape", librarySize "Size", libraryPaperSquare "Square", libraryPaperWide "Widescreen",
  libraryPaperCustom "Custom", libraryTemplateCategoryAll "All" (Hepsi),
  libraryNoTemplatesInCategory "No templates in this category" (TR …şablon yok),
  libraryPdfReadFailed "Couldn't read the PDF file", libraryImageReadFailed "Couldn't read the
  image file", libraryImageLoading "Loading image...", libraryImageTooLarge "Image is too large.
  Maximum size: 4096x4096", libraryPdfTooLarge "PDF is too large. Maximum size: 200 MB",
  libraryPdfOpening "Opening PDF...", libraryPdfImportFailed "Couldn't import the PDF",
  libraryOpening(title) "Opening {title}", libraryOpeningWithPages(title, pages) "Opening {title}
  ({pages})" (pages = `libraryPageCount(n)`). `'${w} x ${h} mm'` → `// l10n-ignore`.
- **folder management (step 6):** libraryManageFolders "Manage folders", libraryNoFoldersYet "No
  folders yet", libraryNoFoldersHint "Tap the button below to create a folder",
  libraryNoFoldersStartHint "Create a folder to get started", libraryFolderOrderSaved "Order
  saved", libraryAddSubfolder "Add subfolder", libraryAddSubfolderTitle(parent) "New folder in
  {parent}", libraryDeleteFolderConfirm(name) "Delete the folder \"{name}\"?\nIts notes will be
  moved to the trash.", libraryFolderManagement "Folder management", libraryMoveFolderTitle "Move
  folder", libraryMoveToFolderTitle "Move to folder", libraryFoldersLoadFailed(error) "Couldn't
  load folders: {error}", libraryFolderNameEmpty "Folder name can't be empty",
  libraryFolderCreated(name) "Folder \"{name}\" created", libraryRootFolders "Top-level folders",
  libraryNoFolderRoot "Documents (no folder)", libraryFolderNameHint "Enter a folder name",
  libraryColor "Color", librarySelectColor "Choose a color".

## Initial `pendingL10n` (paths under `lib/features/documents/presentation/`, from a scan)
constants/documents_strings.dart, providers/{documents_controller, documents_controller_bulk,
documents_controller_page_trash, folders_provider}.dart, screens/{documents_screen,
documents_screen_helpers, manage_folders_screen, template_selection_screen}.dart,
widgets/{document_card_helpers, document_normal_menu, document_quota, document_trash_menu,
documents_empty_states, documents_error_views, documents_header, documents_list_view,
documents_menu_common, documents_sidebar, folder_color_picker, folder_menus,
format_picker_sheet, library_header_parts, library_list_row, library_tile_parts,
manage_folder_list_item, move_to_folder_create_form, move_to_folder_dialog,
move_to_folder_list, new_document_dialog, new_document_importers, pdf_file_importer,
rename_document_dialog, selection_mode_header, sort_popup_button, template_category_tabs,
template_grid, template_preview_section, trashed_page_card, trashed_page_menu}.dart (40 files).
Residue the scanner cannot see (clear in the owning step): `'Belge silinemedi'`
(controller), `'Belgelerim'`, `'Favoriler'`, `'Son Silinenler'`, `'Kapak'`, `'Sablon'`,
`'Isimsiz Not'`, `'Baslik'`, `'Not Basligi'`, `'Letter'/'Legal'/'Kare'`, `'Kapat'/'Daralt'`,
`'Favorilere Ekle'`, `'Devam etmek istiyor musunuz?'`, `'Belge limiti doldu'`, `'Yeni Belge'`,
`'sayfa'`/`'belge'` in `LibraryMeta`, `'Not Defteri'`, `'Beyaz Tahta'`, `'Belgeleri Sil'`,
`'… belge silindi'`, `'Yeniden eskiye'`, `'Eskiden yeniye'`. Turkish-letter literals:
`grep -rnP "['\"][^'\"]*[çğıöşüÇĞİÖŞÜ]" <file>`.

## Steps (one implementer run each)
**PR 2a = steps 1–2 (this PR)**: foundation; no visible change except error toasts in en.
1. *Harness + common + core feedback.* Files: `test/helpers/l10n.dart` (+`navigatorKey`); every
   `MaterialApp(` in `test/features/documents/**` (26 files) → `localizedApp(` (keep theme/
   builder/home/navigatorKey/debugShowCheckedModeBanner); ARB common keys;
   `core/widgets/feedback/app_confirm_dialog.dart`, `app_modal.dart`; guard: add both dirs +
   `pendingL10n` listing every currently offending documents/presentation file;
   `integration_test/helpers/l10n.dart`. Verify: CI analyze+test; goldens unchanged.
2. *Typed errors + labels.* `library_rule.dart` (new), `folder_repository_impl.dart`,
   `create_document_usecase.dart`, `create_folder_usecase.dart`, `documents.dart` export,
   `sort_option.dart` (delete extensions), `library_error.dart`, `library_error_listener.dart`,
   `documents_controller.dart`, `_bulk`, `_page_trash`, `_empty_trash`, `folders_provider.dart`,
   `presentation/l10n/library_labels.dart` (new); remove these files from `pendingL10n`.
   Tests: update `folder_repository_impl_test` L231, `create_*_usecase_test` to assert
   `isA<LibraryRuleFailure>().having((f) => f.rule, ...)`; `documents_controller_bulk_test`
   L70/L122 assert `reported?.action`; new `test/.../l10n/library_labels_test.dart` (every enum
   value non-empty and distinct per locale via `lookupAppLocalizations(Locale('en'|'tr'))`);
   `library_error_listener_test` stays green in tr. Verify: CI.

**PR 2b = steps 3–4**
3. *Library chrome.* `documents_screen.dart`, `documents_screen_helpers.dart`
   (`getSectionTitle(ref, l10n, …)`, rule toast, confirm dialog), `documents_header.dart`,
   `library_header_parts.dart`, `documents_sidebar.dart` (`'elyanotes'` l10n-ignore),
   `sort_popup_button.dart`, `documents_empty_states.dart`, `documents_error_views.dart`,
   `documents_list_view.dart`, `selection_mode_header.dart`. Robots: `library_robot.dart`
   (`enum LibrarySection {all, favorites, trash}` + `label(l10n)`, `openSection(LibrarySection)`,
   opener tooltips, empty state, emptyTrash, waitForLibrary by type), `settings_robot.open`
   (`l10n.settingsTitle`), `pdf_robot` (`find.byType(LibraryNewButton)`). New
   `test/features/documents/presentation/screens/library_text_scale_test.dart` (pattern of
   `settings_text_scale_test.dart`, `libraryOverrides`, tr+en): grid, list, empty, selection
   header, trash section via drawer (info bar), sort menu, empty-trash confirm.
4. *Tiles, menus, trash, dates, duplicate.* `document_card_helpers.dart` (DateFormat, days),
   `library_tile_parts.dart`, `library_list_row.dart`, `document_card.dart`,
   `document_list_tile.dart`, `folder_card.dart`, `folder_list_tile.dart` (LibraryMeta l10n),
   `document_normal_menu.dart`, `document_trash_menu.dart`, `documents_menu_common.dart`,
   `document_quota.dart`, `folder_menus.dart`, `rename_document_dialog.dart`,
   `trashed_page_card.dart`, `trashed_page_menu.dart`, `document_menu_actions.dart`; duplicate
   chain (repository interface/impl, controller + bulk, `selection_mode_header.dart`); delete
   `documents_strings.dart`, `document_context_menu.dart` (+ export). Tests: mocktail stubs add
   `copyTitle: any(named: 'copyTitle')`; `library_repositories_test` passes `(t) => '$t (copy)'`;
   new `document_date_formatter_test.dart` (tr "21 Eki 2026", en "Oct 21, 2026",
   `initializeDateFormatting()` in setUpAll); text-scale test adds item menu sheet, rename
   dialog, folder delete dialog. Robot: rename/favorites/trash/restore via l10n.

**PR 2c = steps 5–6**
5. *Creation flow.* `new_document_dialog.dart`, `new_document_importers.dart`,
   `pdf_file_importer.dart`, `template_selection_screen.dart`, `template_preview_section.dart`,
   `template_category_tabs.dart`, `template_grid.dart`, `template_grouped_list.dart`,
   `cover_grid.dart`, `format_picker_sheet.dart`. Robots: `new_notebook_robot`,
   `library_robot.createNotebook` (`libraryNewNotebook`, `libraryCreateNoteTitle`,
   `commonCreate`). Text-scale: new-doc menu, template screen, format sheet.
6. *Folder management.* `manage_folders_screen.dart`, `manage_folder_list_item.dart`,
   `move_to_folder_dialog.dart`, `move_to_folder_list.dart`, `move_to_folder_create_form.dart`,
   `folder_color_picker.dart`. Robot folder flows via l10n. `pendingL10n` becomes empty and is
   removed. Text-scale: manage folders, move-to-folder dialog. Dispatch e2e on the branch.

## Risks
- A widget test still pumping a migrated widget without delegates throws
  (`nullable-getter: false`): step 1 converts all library tests up front.
- Blind edits: gen-l10n typos only surface in CI; keep each step's ARB diff reviewable
  and run the guard ARB tests (same keys/placeholders) first.
- E2E locale: CI emulator is probably en-US; the e2e suite becomes the en smoke test.
  Editor/pdf robots keep Turkish literals for not-yet-localized drawing_ui strings.
- `tester.l10n` before the first Scaffold throws — robots only call it after `waitForLibrary`.

## Left out (YAGNI / later slices)
drawing_core `Cover.name` (no English name) and `PenType`/toolbar copy → editor slice;
`drawing_ui` PDF import error texts (`pdf_import_errors.dart`); core `ValidationFailure`
factories and `PremiumFailure` texts (auth/premium frozen); `master_detail_layout`,
`app_password_field`; persisted Turkish `PaperColor.storageKey` (data, not copy); in-app
language picker; relative dates ("yesterday").

## Reference check
GoodNotes, StarNote, Flexcil follow the system language with no in-app picker (slice 1);
library dates and counts follow the system locale's formats → we use `DateFormat` with the
active locale and ICU plurals. Duplicates get a localized "copy" suffix in the UI language
(iOS/Android file convention; GoodNotes, Flexcil duplicate in place with a suffix) → we
localize the suffix at creation time and store it as part of the title (user data, not
re-translated later). No deviation.
