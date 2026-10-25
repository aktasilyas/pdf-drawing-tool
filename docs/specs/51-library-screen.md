# Spec: library screen redesign (#51)

Brief: `docs/design/BRIEF.md`. Quality bar: `flutter-ui-craft`. Tokens: `design-tokens`. Visual restyle only: selection,
sort, folders, trash, favorites, search, new-document flow and every callback keep their current behaviour unless §10 lists a change.
Code: `example_app/lib/features/documents/presentation/`.

## 1. Purpose
Find a notebook and open it. Primary action: tap a cover. Secondary: **Yeni** (new document dropdown, unchanged).
The covers are the hero. Chrome is quiet, sits on `background`, and has no cards, shadows or Material ripples.

## 2. Layout per size class
Header mode depends on the **content pane width** (LayoutBuilder), not on the device: `wide` >= 720, `compact` < 720.
```
TABLET LANDSCAPE 1180x820 (sidebar open)
+--------------- 280 ---------------+|+------------------------- 900 -------------------------------------+
| lg                                ||  xl  Tüm Notlar            [Q Ara........240] [sort][view][sel][gear] md [+ Yeni v]  xl |
| [logo] elyanotes          [<<]    ||      (header row 48, padding top md, bottom lg)                                      |
| xl                                ||  [cover][xl][cover][xl][cover][xl][cover][xl][cover]    5 cols x 151, gap xl           |
| [*] Tüm Notlar   (selected)       ||   Title (serif)                                                                       |
| [ ] Favoriler                     ||   12 Eki 2026 · 24 sayfa                                                              |
| [ ] Son Silinenler                ||  xl (row gap)                                                                         |
| lg                                ||  [folder][cover][cover]...                                                            |
| Klasörler          Yönet   [+]    ||                                                                                       |
| [f] Ders Notları             12   ||                                                                                       |
|    [f] Biyoloji               3   ||                                                                                       |
+-----------------------------------+|+---------------------------------------------------------------------------------------+
                          1dp hairline `border` on the sidebar's right edge

PHONE 390x844 (compact header, sidebar in Drawer)
| xs [menu] Tüm Notlar ........... [gear][+] xs |  row 1, 48 high, padding top sm
| lg [Q Ara.................] sm [sort][view][sel] lg |  row 2, 48 high, gap xs between rows
| md                                              |
| lg [cover 171] lg [cover 171] lg                |  2 cols, gap lg, row gap xl
```
- **Tablet landscape** (pane >= 720): sidebar `AppSpacing.sidebarWidth` (280). Pane padding horizontal `AppSpacing.screenPaddingTablet` (24).
- **Tablet portrait** (600–839): the sidebar starts collapsed (`_isSidebarCollapsed` defaults to `width < AppBreakpoints.expanded`,
  read once in `didChangeDependencies`). The toggle opens it inline exactly as today. With the sidebar open the pane is 540 wide, so the header is compact.
- **Phone** (< 600): there is no persistent sidebar. Folders are reached in two ways: the Drawer (menu button, unchanged) and
  folder tiles at the top of the root grid (unchanged). Pane padding `AppSpacing.screenPaddingMobile` (16).
- **Sidebar toggle**: on tablet it is shown in the header only while the sidebar is collapsed. While the sidebar is open, the collapse button in the sidebar header
  is the only toggle, so the title lines up with the grid's left edge (x = 24).

**Grid metrics** (new pure helper `library_grid_metrics.dart`, unit-tested; replaces the magic numbers in `documents_combined_grid.dart`):
- gap: phone `lg` (16) across, `xl` (24) down; tablet `xl` (24) both ways. Columns: phone always 2; tablet
  `n = floor((avail + gap) / (144 + gap))`, clamped to 3..7. Tile width `w = (avail - (n-1)*gap) / n`.
- Cover box `w x 4w/3`. Info block = `sm + titleLarge line (24) + xxs + caption line (16)`; both line heights go through
  `MediaQuery.textScalerOf`. Use `SliverGridDelegateWithFixedCrossAxisCount(n, mainAxisExtent: 4w/3 + info)`.
- Check: 1180 with sidebar: avail 852, 5 cols, w 151. 820 with sidebar collapsed: avail 772, 4 cols, w 175. 390: w 171.
- The grid's top padding is 0 (the header's bottom `lg` gives the spacing). Bottom padding is `xxl` plus the safe area.

## 3. Header (`documents_header.dart` + the screen's top bars, merged into one `LibraryHeader` layout)
| Slot | Wide (one row, height 48) | Compact (two rows) |
|---|---|---|
| Title | `AppTypography.displayMedium`, `textPrimary`, 1 line, ellipsis. The breadcrumb replaces it inside a folder (existing) | row 1, `headlineLarge` |
| Search | `AppSearchField`, fixed width 240, hint `DocumentsStrings.search`, writes `searchQueryProvider` | row 2, Expanded |
| Sort / view / select | `AppIconButton` ghost, 48 hit, icon `md` (20) | row 2, trailing |
| Settings | ghost icon button, placed before Yeni | row 1, before the + button |
| Yeni | `AppButton` primary, medium, leading `plus`, trailing `caretDown`, wrapped to a 48 minimum hit height; keeps `newButtonKey` | row 1 trailing: `AppIconButton` filled, `plus`, same key |
- Spacing (wide): title → actions `lg` min gap; search → sort `sm`; between icon buttons 0 (the hit boxes touch); gear → Yeni `md`.
- The search field is newly visible. The provider and the filtering already exist (`documents_content_view.dart`), and the no-results empty state is
  `DocumentsEmptySearchResult`. Its "Aramayı temizle" button must also clear the field's text (pass `text:`).
- Remove the `_buildSoftDivider` hairline under the header. Spacing alone separates header and grid.
- Sort popup (`sort_popup_button.dart`): the trigger becomes ghost (no circle fill). The menu is `surfaceElevated`, radius `AppRadius.lg`, 1dp `border`,
  items 48 high, label `labelLarge textPrimary`, current option has a trailing `check` in `accent`. Keep the menu content.
- Trash section: the info strip becomes `surface` fill, 1dp `border`, radius `AppRadius.md`, `info` icon `textMuted`. No `AppColors.warning`.
- Selection mode (`selection_mode_header.dart`) replaces both header rows with one 48dp row padded like the header:
  `[x close] "{n} seçildi" (titleMedium, accent)` ... `[Tümü text button labelLarge textMuted, checkSquare/square icon] [copy] [folderSimple move] [trash]`.
  The delete icon is `danger` when enabled. Disabled icons are `textDisabled`. On phone, use `AppIconButtonSize.medium` too (48 hit, no small).

## 4. Document tile (`document_card.dart`). No container, the object sits on `background`
```
+---- w ----+        cover box w x 4w/3
|  [cover]  |  <- CoverPreviewWidget(cover, title, showBorder:false): renderer draws board, pages, shadow
|        (*)|  <- favorite badge, only when isFavorite: 24 disc surfaceElevated, star Fill textPrimary, sm icon, 48 hit
+-----------+
 sm
 Biyoloji          v   <- titleLarge (Source Serif 4, 16/24 w600) textPrimary, 1 line ellipsis; caretDown sm textMuted
 12 Eki 2026 · 24 sayfa  <- caption textMuted, tabular figures; "· N sayfa" only when pageCount > 1
```
- Without a cover (PDF, image, notebook without cover, whiteboard): the page thumbnail is contained in the cover-board rect
  (insets: left 1.2%·w, right 6%·w, bottom 6%·w, the same as `CoverGeometry.cover`), with its own aspect (`isPortrait`, paper mm), **bottom-centred**
  so baselines line up across the row. Page: paper fill (`DocumentPaperColors`, unchanged data colours), 1dp `border`, radius `AppRadius.xs`, no shadow.
  Delete the spiral-binding decoration and the whiteboard frame. A whiteboard is a page with the dot grid in the light palette's `textPrimary` @ 24% on `paper` (pages stay light in dark mode, so the dots are theme-invariant).
- Remove the page-count badge (it used a 9px inline font) because the count is now in the meta line. Remove the always-visible empty star.
- Gestures (unchanged): tap cover = open (in selection mode: toggle). Long-press = enter selection. Tap on the info block (title, caret, meta;
  hit area includes the `sm` gap, at least 48 high) = document menu. Tap on the favorite badge = toggle favorite.
- States: pressed = `AnimatedScale` 0.97 (`AppDurations.instant`, `AppDurations.enter`), no ripple/splash. Keyboard focus = the selected ring (below) without the fill.
  Trash: the days-left badge sits bottom-left on the cover, radius `AppRadius.xs`, `labelMedium`. Fill is `danger`/`onDanger` when <= 7 days,
  otherwise `surfaceElevated`/`textMuted`.

## 5. Folder tile (`folder_card.dart` + new `folder_tile_art.dart` CustomPainter)
Same footprint and info block as a document tile, so rows stay aligned. The art is an original drawn folder, bottom-aligned in the cover box:
- Body box `w x 0.78w` on the bottom edge. Back panel: full body, radius `0.06w`, colour = folder colour darkened (HSL lightness −0.08).
  Tab: top-left, `0.40w x 0.08w`, same colour, top corners rounded. Sheet: `paper`, inset `0.06w` on the sides, top `0.05w` below the back top.
  Front panel: from `0.20w` below the back top to the bottom, full width, same radius. Colour = the folder colour tamed theme-independently
  (HSL saturation capped at 0.45, lightness clamped to 0.42..0.62; this calms the saturated legacy folder palette). Back panel and tab use the
  tamed colour darkened by 0.08 lightness; a 1dp line darkened by 0.16 runs along the body's bottom edge. The art is drawn inside the cover board rect. Top edge highlight: 1dp `paper` @ 25%. No icon, no number on the art.
- Paints are built in the painter's constructor. `shouldRepaint` compares the colour and the palette. Reuse it at 36x48 in list rows.
- Meta line: `"{n} belge"`. Favorite badge is the same as for documents. Remove the `Icons.folder_rounded` FittedBox and the white count text.
- Keep `Key('folder_card_more_button')` on the caret.

## 6. Selection (grid)
- Checkbox at the top-right of the cover board (inset `sm` from the board's right edge, which is 6%·w in from the box edge), 24 visual, the whole tile is the hit area.
  Off: `surfaceElevated` @ 92% fill, 1.5dp `textMuted` ring. On: `accent` fill, `check` (Regular) `sm` in `onAccent`.
- Selected tile: a backdrop behind cover and info, inflated by `sm` on each side (fits inside the `lg`/`xl` gaps), radius `AppRadius.lg`,
  `accentContainer` fill, 1.5dp `accent` border. `AnimatedContainer`, `AppDurations.fast`, `AppDurations.enter`.
- Remove every `AppColors.primary` (legacy green) overlay and border in these widgets. The favorite badge is hidden in selection mode.

## 7. List view (`documents_list_view.dart`, `document_list_tile.dart`)
```
| md [36x48 thumb] md  Biyoloji (titleLarge)                       [(*)] [>] md |  row 64
|                      12 Eki 2026 · 24 sayfa (caption textMuted)               |
|                      ------------------------------------------ hairline -----|  divider indent 60
```
- Rows sit flat on `background`: no per-row card or shadow. Folder rows are also 64 (not 52). They use `FolderTileArt` and meta `"{n} belge"`, and the count badge is removed.
- Thumbnail: `CoverPreviewWidget` at 36x48 (empty title) or the page/folder art. Trailing: favorite star (Fill, `textMuted`, `sm`, 48 hit)
  only when favorite, then `caretRight` `sm` `textDisabled` (decorative). In selection mode the checkbox (§6 style) replaces the caret.
- Pressed: `textPrimary` @ 6% fill, radius `AppRadius.md`. Selected: `accentContainer` fill, radius `AppRadius.md`. Dividers: 1dp `border`
  between rows, starting at the text column (md + 36 + md = 60). Section labels "Klasörler"/"Belgeler": `labelMedium textMuted`,
  left `md`, top `lg` (0 for the first), bottom `xs`. Pane padding is the same as the grid. Long-press = menu (unchanged).

## 8. Sidebar (`documents_sidebar.dart`, `sidebar_item.dart`; `sidebar_tile.dart` is deleted once unused)
- `surface` fill, 1dp `border` right edge. Header row (top `lg`): logo + wordmark **unchanged** (BRIEF open question; do not restyle), collapse
  `AppIconButton` ghost `sidebar` (tablet) / `x` (drawer). Then `xl`.
- Nav rows "Tüm Notlar" (`notebook`), "Favoriler" (`star`), "Son Silinenler" (`trash`). They are restyled `SidebarItem`s: height 48, margin horizontal `sm`,
  padding horizontal `md`, radius `AppRadius.md`, icon `md`, gap `md`, label `labelLarge textPrimary`. Selected: `accentContainer` fill, icon
  Fill `accent`, label `accent` w600. Pressed: `textPrimary` @ 6%. The nav card (`AppCard` elevated) and the indented dividers are removed.
- Remove the disabled "Etiketler / Yakında" row. It is not v1.0 scope and has no behaviour.
- `lg`, then the "Klasörler" header row (48): `labelMedium textMuted`, left `lg`. Trailing: "Yönet" (`labelMedium accent`, 48 hit) and `plus` ghost.
- Folder rows: same `SidebarItem`. Icon `folder` Fill in the folder colour (also when selected). Count `caption textMuted` with tabular figures
  (was `textDisabled`, which fails AA). Subfolders add `lg` indent. Empty: "Klasör yok" `caption textMuted`, left `lg`.

## 9. Empty state (`DocumentsEmptyState`, root with no folders and no documents)
Centred in the pane, max width 320: `CoverPreviewWidget(CoverFamily.linenSand, title: null)` at 120x160, then `xl`, then "Henüz not yok"
(`headlineMedium textPrimary`), `sm`, "Yeni bir defter oluşturun ya da bir PDF içe aktarın." (`bodyMedium textMuted`, centred), `xl`,
`AppButton` primary medium "Yeni not" (leading `plus`). It calls the screen's `onNewPressed` (new optional `onCreateNew` passed through
`DocumentsContentView`). The logo image and the `description_outlined` icon are removed. The search-empty state only swaps its icons to Phosphor (`magnifyingGlass`, `x`).

## 10. Tokens, icons, motion, small core fixes
- Colours: only `context.palette` roles named above. No `AppColors.*`, no `isDark`, no `Colors.*` in touched files (except `Colors.transparent`). Folder,
  cover and paper colours are user data and pass through. No `AppShadows` in this screen: its light tint is legacy teal (`#00B988`), which is off-brief.
  Follow-up issue: retint `AppShadows` to a neutral warm colour.
- Contrast (AA): `textMuted` on `background` is 4.9:1 light and 6.5:1 dark. `accent` on `accentContainer` is 6.8:1 and 5.5:1. `textDisabled` is never used for text that carries meaning.
- Icons: Phosphor is available through `drawing_ui`'s re-export (`phosphor_icons` ^3.0.1, already a dependency). Add a `// Library` section to
  `ElyanotesIcons` (`packages/drawing_ui/lib/src/theme/elyanotes_icons.dart`; widgets never use Phosphor directly) with **Regular** for chrome and **Fill**
  for selected, per the BRIEF: notebook, star, trash, folder, plus, caretDown, caretRight, magnifyingGlass, sortAscending, squaresFour,
  rows, checkCircle, check, x, copy, folderSimple, checkSquare, square, gearSix, sidebar, list, info.
  Open question (architect): the editor's registry uses Light for chrome, which differs from the BRIEF. This screen follows the BRIEF.
- Core boy-scout fixes, needed for dark mode: `AppIconButton` ghost uses `AppColors.primary/textSecondaryLight/surfaceVariantLight`. Change it to `textMuted`
  icon, selected = `accentContainer` fill + `accent` icon, pressed `textPrimary` @ 6%, no splash. `AppSearchField` gets an enabled 1dp `border` outline
  (today the `surface` fill is invisible on `background`) and Phosphor icons.
- Motion: sidebar width `AppDurations.fast` (was a raw 250ms); open uses `AppDurations.enter`, close uses `AppDurations.exit`. Grid/list switch and normal/selection
  header use `AnimatedSwitcher` fade, `AppDurations.fast`, `AppDurations.fade`. Selection backdrop/checkbox use `AppDurations.fast` with `enter`. Press scale uses `instant`.
- Behaviour changes, all small and deliberate: (a) search field visible; (b) tablet sidebar starts collapsed below 840; (c) the unfavorited star is no
  longer on every tile, so add "Favorilere Ekle/Kaldır" (`star`) to `folder_menus.dart` (the document menu already has it); (d) "Etiketler" row removed;
  (e) empty-state CTA.

## 11. Golden tests
`example_app/test/features/documents/presentation/screens/library_golden_test.dart`. It follows `cover_family_golden_test.dart`:
`matchesGoldenFile`, `loadAppTestFonts()`, `CoverTextureStore.ensureLoaded()`, `tester.view.physicalSize` at DPR 1, real `AppTheme.light/dark`.
It pumps `DocumentsScreen` in a `ProviderScope` with these overrides: `foldersProvider`, `documentsProvider` (family), `favoriteDocumentsProvider`,
`favoriteFoldersProvider`, `totalDocumentCountProvider` (8), `viewModeProvider`, and `SharedPreferences.setMockInitialValues({})`. Premium flag is off (default).
| # | File | Size | Theme | State |
|---|---|---|---|---|
| 1 | `library_tablet_light_grid` | 1180x820 | light | root, grid, sidebar open, "Tüm Notlar" selected |
| 2 | `library_tablet_dark_grid` | 1180x820 | dark | same |
| 3 | `library_phone_light_grid` | 390x844 | light | root, grid |
| 4 | `library_phone_dark_grid` | 390x844 | dark | same |
| 5 | `library_tablet_light_list` | 1180x820 | light | root, list view |
| 6 | `library_tablet_light_empty` | 1180x820 | light | no folders, no documents |
| 7 | `library_tablet_light_selection` | 1180x820 | light | selection mode; doc 1, doc 4 and folder "Projeler" selected |

**Fixtures** (fixed dates, sorted by date desc, the default). Folder colours come from `AppColors.folderColors` (data):
- Folders (root): "Ders Notları" `[9]` 12 docs · "Projeler" `[5]` 4 docs, favorite · "Okuma" `[11]` 0 docs. Subfolder "Biyoloji" `[9]` under
  Ders Notları, 3 docs (sidebar only).
- Documents (root), `updatedAt` 2026-10-21 going down one day each:
  1 "Biyoloji" `linen_sage` 24 p, favorite · 2 "Toplantı Notları" `leather_navy` 6 p · 3 "Günlük" `kraft_natural` 31 p (label plate) ·
  4 "Matematik Ödev 3" no cover, `small_grid`, Krem kağıt, 3 p · 5 "Çok uzun bir defter adı kısaltma testi için" `leather_oxblood` 1 p ·
  6 "Beyaz Tahta" whiteboard, 1 p · 7 "Sunum Taslağı" no cover, landscape (`isPortrait: false`), `thin_lined`, 2 p · 8 "Fizik" `felt_mustard` 12 p, favorite.
- No PDF fixture: `DocumentPreview` loads through `loadDocumentUseCaseProvider`, so it is not deterministic in tests.

Review checklist: baselines aligned across covers, folder and landscape page; title/meta left edges on the grid column; header title at x=24;
no teal/green anywhere; dark mode has no light chrome slabs; every tap target >= 48; long title ellipsized; serif only on titles.
Widget tests to update: `folder_card_test`, `document_card_test`, `documents_header_test`, `documents_list_view_test`, `document_list_tile_test`,
plus a unit test for `library_grid_metrics` (5/4/2 cols at 852/772/358).

## 12. Reference check
- GoodNotes (support.goodnotes.com, "Organize folders and documents"): a Documents view with a "+ New" menu (document/folder).
  One icon switches grid/list. Search by name. "Select Items" for bulk move/export/trash. In grid, the item menu opens from an arrow
  next to the name. Folders have a colour. Titles sit under the thumbnails.
- StarNote (App Store notes): folder and tag lists on the note list page, global search with folder filters, custom folder sort. No public
  detail on grid/list (not verified).
- Flexcil (product knowledge, unverified): left panel with documents/favorites/trash and folders, a thumbnail grid with names below, sort and view
  controls top-right.
- What we do: the converged pattern. Persistent sidebar on wide tablets, drawer on phone, thumbnail grid with title under the object, caret
  next to the name for the menu (GoodNotes), header search plus sort/view/select, "+ Yeni" dropdown. Deviations: covers are our procedural
  family with a serif title (BRIEF). The folder art is our own drawing, not a folder glyph. The large serif title follows the warm-paper brief. Nothing is
  copied (no icons, art or exact layout).
