# Library screen redesign Implementation Plan (#51)

> **For agentic workers:** REQUIRED SUB-SKILL: subagent-driven-development (or executing-plans). Steps use `- [ ]`.

**Goal:** Restyle the library (DocumentsScreen) to `docs/specs/51-library-screen.md`. Covers are the hero, the chrome is quiet, and dark mode is correct. Behaviour stays the same except for the changes listed in spec §10.
**Architecture:** Presentation-only change in `example_app/lib/features/documents/presentation/`, plus small core-widget fixes
(`AppIconButton`, `AppSearchField`) and a `drawing_ui` icon/export addition. No domain/data change.
**Spec:** `docs/specs/51-library-screen.md` (read it with this plan). Skills: design-tokens, flutter-ui-craft, design-loop.

## Global constraints
- Colours only via `context.palette` (`AppPalette`: background, surface, surfaceElevated, border, textPrimary, textMuted,
  textDisabled, accent, accentContainer, danger, onAccent, onDanger, paper). In touched files: no `AppColors.*`, `isDark`, `Colors.*`
  (except `Colors.transparent`), no `AppShadows`. Folder/cover/paper colours (`Color(folder.colorValue)`, `DocumentPaperColors`) are data.
- Spacing `AppSpacing` (xxs 2, xs 4, sm 8, md 12, lg 16, xl 24, xxl 32, screenPaddingMobile 16, screenPaddingTablet 24,
  sidebarWidth 280, minTouchTarget 48). Radius `AppRadius` (xs 4, md 10, lg 12). Icon sizes `AppIconSize` (sm 16, md 20, lg 24).
- **Spec erratum:** the spec writes `AppDurations.enter/exit/fade`. Those are curves: use `AppCurves.enter`, `AppCurves.exit`, `AppCurves.fade`.
  Durations: `AppDurations.instant` (100ms) and `AppDurations.fast` (200ms).
- Type: `AppTypography.displayMedium/headlineLarge/headlineMedium/titleLarge (serif 16/24)/titleMedium/labelLarge/labelMedium/caption/bodyMedium`.
  Numbers use `fontFeatures: const [FontFeature.tabularFigures()]` (`dart:ui`).
- Icons come only from `ElyanotesIcons.library*` (Step 1). Import `package:drawing_ui/drawing_ui.dart` with a `show` list
  (e.g. `show ElyanotesIcons, CoverPreviewWidget, CoverGeometry`) to avoid name clashes.
- No ripples: `InkWell(splashFactory: NoSplash.splashFactory, highlightColor: palette.textPrimary.withValues(alpha: 0.06))`.
- Files stay ≤ ~300 lines. `documents_screen.dart` (398) and `documents_menus.dart` (410) must not grow; the screen shrinks in Step 9.
- New public widgets get `Library*` names and are exported from `example_app/lib/features/documents/documents.dart`.
- Copy is Turkish, exactly as written in the spec.

## Verification without an SDK (every step)
Nothing compiles locally. Each step ends with: commit, `git push origin claude/<branch>`, then dispatch
`update-goldens.yml` with `inputs[package]=example_app` (or `packages/drawing_ui` for Step 1). This workflow is also the test runner.
The run fails if any test fails (read the job log), and on success it commits goldens and dispatches CI (analyze + tests).
Done means the run is green and the CI run on the branch is green. Never push to main. Keep history append-only.
Golden caveat: from Step 7 on, every visual step changes the library goldens. Read the new PNGs after each run (design-loop); never accept them blindly.

## Review focus (each has a test in the owning step)
1. Text scale 1.3: the info block grows and the grid extent follows (no overflow). Step 3 metrics test + Step 6 overflow test.
2. Typing in search is not overwritten by unrelated rebuilds during the 300ms debounce. Step 2 `AppSearchField` test.
3. Narrow tablet pane (portrait, sidebar open, pane 540): compact header, 3 columns (avail 492, w 148). Step 3 + Step 8.
4. Long names ellipsize in grid, list and sidebar. Step 5/6 tests + golden fixture doc 5.
5. Favorite stays reachable without the always-on star: the folder menu gets the toggle. Step 13 test.

---
## PR slice 1: branch `claude/51-library-tiles` (Steps 1–7)

### Step 1: drawing_ui library icons + CoverGeometry export
Files: `packages/drawing_ui/lib/src/theme/elyanotes_icons.dart`, `packages/drawing_ui/lib/drawing_ui.dart`.
- Add a `// Library (BRIEF: Regular chrome, Fill selected)` section. The names avoid clashes with existing members:
  `libraryNotebook/libraryNotebookFill` (notebook), `libraryStar/libraryStarFill`, `libraryTrash/libraryTrashFill`,
  `libraryFolder/libraryFolderFill`, `libraryPlus`, `libraryCaretDown`, `libraryCaretRight`, `librarySearch` (magnifyingGlass),
  `librarySort` (sortAscending), `libraryGrid` (squaresFour), `libraryRows` (rows), `librarySelect` (checkCircle), `libraryCheck`,
  `libraryClose` (x), `libraryCopy`, `libraryMove` (folderSimple), `libraryCheckSquare`, `librarySquare`, `librarySettings` (gearSix),
  `librarySidebar`, `libraryMenu` (list), `libraryInfo`, `libraryLock` (lock). Non-Fill = `PhosphorIconsRegular.x`, Fill = `PhosphorIconsFill.x`.
- Update the file's header doc: the library follows the BRIEF (Regular/Fill), and the editor keeps Light/Regular (open question, spec §10).
- Export `src/painters/cover/cover_geometry.dart` from `drawing_ui.dart` (class `CoverGeometry`, `CoverGeometry.of(Size).cover`).
- Risk: `notebook, sortAscending, squaresFour, rows, folderSimple, checkSquare, square` have not been used in the repo yet (pub.dev is blocked here).
  CI analyze is the check. If one is missing, report it and pick the nearest Phosphor name. Do not use Material icons.
- Verify: dispatch with `packages/drawing_ui`, then confirm CI analyze is green for drawing_ui and example_app.

### Step 2: core widget fixes (TDD)
Files: `example_app/lib/core/widgets/buttons/app_icon_button.dart`, `.../inputs/app_search_field.dart`;
tests (new) `example_app/test/core/widgets/buttons/app_icon_button_test.dart`, `.../inputs/app_search_field_test.dart`.
- `AppIconButton`: new optional `final Color? iconColor` (applied by ghost only). Ghost: `Material(color: isSelected ? accentContainer : transparent)`,
  icon `isSelected ? accent : (disabled ? textDisabled : iconColor ?? textMuted)`, no splash, pressed fill textPrimary@6%. A disabled ghost
  uses no `Opacity`. Filled: fill `accent`, icon `onAccent` (this removes legacy green and affects all default-variant usages; that is intended).
  Leave tonal/outline alone (follow-up).
- `AppSearchField`: `enabledBorder` and `border` = 1dp `palette.border`. Icons `ElyanotesIcons.librarySearch` / `libraryClose`.
  `didUpdateWidget` syncs only when `widget.text != oldWidget.text` (external change). Today it syncs whenever the text differs from the controller, which clobbers typing.
- Tests: ghost icon colour = `AppPalette.light.textMuted` and `.dark.textMuted`; selected → `accentContainer` fill + `accent` icon;
  `onPressed: null` → `textDisabled`; `iconColor: danger` honoured; filled → `accent`. Search: enabled border colour = palette.border width 1;
  type 'ab', rebuild parent with the same `text: ''` → field still shows 'ab'; change `text` to '' → field clears.

### Step 3: grid metrics (TDD) + grid wiring
Files: new `.../presentation/widgets/library_grid_metrics.dart`; `documents_combined_grid.dart`;
test new `example_app/test/features/documents/presentation/widgets/library_grid_metrics_test.dart`.
- `@immutable class LibraryGridMetrics` with
  `factory LibraryGridMetrics.resolve({required double availableWidth, required bool isPhone, TextScaler textScaler = TextScaler.noScaling})`.
  Fields: `int columns`, `double crossGap, rowGap, tileWidth, infoHeight`. Getters: `coverHeight` (= 4w/3), `mainAxisExtent`,
  `SliverGridDelegateWithFixedCrossAxisCount get delegate`. Statics: `minTileWidth = 144`, `minColumns = 3`, `maxColumns = 7`,
  `double paneHorizontalPadding(bool isPhone)` (16/24), `double infoBlockHeight(TextScaler s)`.
- `infoBlockHeight` = `(sm + s.scale(16) * 1.5 + xxs + s.scale(12) * 1.33).ceilToDouble()` (titleLarge/caption size × height).
  This deviates from the spec's `scale(24)`, which under-sizes with Android's non-linear scaler. At 1.0 it equals 50.
- Phone: 2 cols, crossGap lg, rowGap xl. Tablet: gap xl/xl, `n = ((avail + gap) / (144 + gap)).floor().clamp(3, 7)`.
- Tests: 852 tablet → 5, w ≈ 151.2; 772 → 4, 175; 358 phone → 2, 171, gaps 16/24; 492 → 3, 148; 300 → 3; 2000 → 7;
  infoHeight 50 at noScaling and 62 at `TextScaler.linear(1.3)`; mainAxisExtent at 852 ≈ 251.6.
- Grid: compute metrics from `constraints.maxWidth - 2 * pad`, isPhone = `Responsive.isPhone(context)`, scaler `MediaQuery.textScalerOf`.
  Move the padding **into** `GridView.builder(padding: EdgeInsets.fromLTRB(pad, AppSpacing.sm, pad, AppSpacing.xxl + MediaQuery.paddingOf(context).bottom))`.
  The `sm` top padding keeps the selected backdrop (inflated by sm) from being clipped by the viewport. The header compensates in Step 8.
  Leave `trash_content_view.dart` alone (tiles adapt; follow-up).
- Existing `documents_combined_grid_test.dart` must pass unchanged.

### Step 4: tile art: `FolderTileArt` + `LibraryPageThumbnail`
Files (new): `.../widgets/folder_tile_art.dart`, `.../widgets/library_page_thumbnail.dart`; tests (new) `folder_tile_art_test.dart`,
`library_page_thumbnail_test.dart`.
- `class FolderTileArt extends CustomPainter { FolderTileArt({required this.color, required this.palette}); final Color color; final AppPalette palette; }`
  All `Paint`s are built in the initializer list. Geometry per spec §5: body `w × 0.78w` on the bottom edge; back colour
  `HSLColor.fromColor(color).withLightness((l - 0.08).clamp(0.0, 1.0)).toColor()`; front `Color.lerp(color, palette.surface, 0.30)`;
  1dp `palette.paper`@25% highlight. `shouldRepaint`: `color != old.color || palette != old.palette`.
- `LibraryPageThumbnail({required DocumentInfo document})`: a LayoutBuilder. Board = `CoverGeometry.of(size).cover`, page aspect from
  `isPortrait` + `paperWidthMm/paperHeightMm`, contain-fit in the board, **bottom-centred**. Fill `DocumentPaperColors.fromName`
  (whiteboard: `palette.paper` + `WhiteboardGridPainter(dotColor: textPrimary@8%)`), 1dp `border`, radius `AppRadius.xs`, no shadow.
  pdf/image → `DocumentPreview(document:)` clipped in the same rect; else `DocumentThumbnailPainter(templateId)`.
- Tests: `shouldRepaint` false for equal inputs, true for a new colour; a landscape doc at 151×201.6 → the page rect is wider than tall and its bottom
  equals board bottom (find the page `DecoratedBox`/`Container` and `tester.getRect`).

### Step 5: shared tile parts
Files (new): `.../widgets/library_tile_frame.dart`, `.../widgets/library_tile_parts.dart`; test (new) `library_tile_parts_test.dart`.
- `library_tile_parts.dart`:
  `LibrarySelectionCheckbox({required bool isSelected})`: a 24 `AnimatedContainer` circle (fast, `AppCurves.enter`). Off: `surfaceElevated`@0.92 fill +
  1.5dp `textMuted` ring. On: `accent` fill + `Icon(libraryCheck, size: sm, color: onAccent)`.
  `LibraryFavoriteBadge({required VoidCallback? onTap})`: 48 hit, 24 `surfaceElevated` disc, `libraryStarFill` sm `textPrimary`.
  `LibraryTileInfo({required String title, required String meta, VoidCallback? onTap, bool showCaret = true, Key? caretKey})`:
  opaque `GestureDetector` around `Padding(top: sm)` + title row (`titleLarge textPrimary`, 1 line ellipsis, caret `libraryCaretDown` sm textMuted)
  + `xxs` + meta (`caption textMuted`, tabular). `abstract final class LibraryMeta { static String document(DocumentInfo d); static String folder(Folder f); }`
  gives `'${DocumentDateFormatter.format(d.updatedAt)}${d.pageCount > 1 ? ' · ${d.pageCount} sayfa' : ''}'` and `'${f.documentCount} belge'`.
- `library_tile_frame.dart`: `LibraryTileFrame` (StatefulWidget) with
  `({required Widget cover, required Widget info, required VoidCallback onTap, required VoidCallback onLongPress, bool isSelected = false,
  bool isSelectionMode = false, List<Widget> Function(Rect board) overlays = _none})`. Layout: `Column[Expanded(LayoutBuilder → box
  w = min(maxW, maxH*3/4), h = 4w/3, Align.bottomCenter → Stack(clipBehavior: Clip.none)[backdrop, GestureDetector(cover), ...overlays(board),
  if selectionMode Positioned checkbox at board top-right inset sm])), info]`. Board = `CoverGeometry.of(box).cover`.
  Backdrop: `Positioned(-sm …)` `AnimatedContainer` (fast, enter), radius lg, selected → accentContainer fill + 1.5 accent border; keyboard
  focus (`FocusableActionDetector`, `ActivateIntent` → onTap) → border only. Press: `AnimatedScale(0.97, instant, AppCurves.enter)` via
  onTapDown/Up/Cancel (a tile, not ink, so local setState is fine).
- Tests: checkbox colours light+dark (find the `AnimatedContainer` under `LibrarySelectionCheckbox`); `LibraryMeta.document` with
  pageCount 1 → no "sayfa"; info hit area height ≥ 48 (`tester.getSize(find.byType(LibraryTileInfo))`); frame tap → onTap, long-press → onLongPress.

### Step 6: DocumentCard restyle
Files: `.../widgets/document_card.dart`, `.../widgets/document_card_helpers.dart`; test `document_card_test.dart` (update).
- `DocumentCard` keeps its constructor. Build = `LibraryTileFrame(cover: hasCover && CoverRegistry.byId != null ?
  CoverPreviewWidget(cover:, title: document.title, showBorder: false) : LibraryPageThumbnail(document:), info: LibraryTileInfo(title, LibraryMeta.document,
  onTap: onMorePressed, showCaret: onMorePressed != null), overlays: fav badge (only isFavorite && !isSelectionMode; disc inset sm from board right/bottom),
  trash days badge (bottom-left inset sm))`. **No `ref.watch` in build** (the test pumps without ProviderScope). Long-press logic stays in the callback.
- Helpers: delete `DocumentSelectionCheckbox`, `DocumentFavoriteButton`, `DocumentPageCountBadge`. Restyle `DocumentDaysLeftBadge`
  (≤7 days `danger`/`onDanger`, else `surfaceElevated`/`textMuted`, `labelMedium`, radius xs). Keep `DocumentPaperColors` and `DocumentDateFormatter`.
  Delete the spiral and whiteboard-frame code.
- Test updates: wrap the helper in `ProviderScope`; `Icons.star` → `ElyanotesIcons.libraryStarFill`; replace the "star_outline when not favorited" test with
  "no favorite badge when not favorited" (`findsNothing`); the favorite-toggle test uses a favorite doc and taps `libraryStarFill`; the more test taps
  `libraryCaretDown`. Add: an 8-tile `GridView` with `LibraryGridMetrics` at `textScaler: TextScaler.linear(1.3)` → `tester.takeException()` is null;
  long title has `maxLines 1` + ellipsis.

### Step 7: FolderCard restyle + library golden test
Files: `.../widgets/folder_card.dart`; test `folder_card_test.dart` (update); new `example_app/test/features/documents/presentation/screens/library_fixtures.dart`,
`.../screens/library_golden_test.dart`; `example_app/test/helpers/font_loader.dart` (add `loadManifestFonts()`).
- `FolderCard`: `LibraryTileFrame(cover: CustomPaint(painter: FolderTileArt(color: Color(folder.colorValue), palette: context.palette)),
  info: LibraryTileInfo(folder.name, LibraryMeta.folder, caretKey: const Key('folder_card_more_button'), showCaret: onMorePressed != null && !isSelectionMode),
  overlays: fav badge when favorite (toggle via `foldersControllerProvider.notifier.toggleFavorite` in the callback))`. Delete `_FavoriteButton`, `_SelectionCheckbox`.
- folder_card_test: replace the `Icons.folder_rounded` tests with "art uses folder colour" (`CustomPaint` whose painter `is FolderTileArt` and has
  `.color == Color(testFolder.colorValue)`). Checkbox tests: find via `LibrarySelectionCheckbox` with the new colours (off: surfaceElevated@0.92 / ring textMuted;
  on: accent + `libraryCheck`). Name/meta colour, tap, key and ellipsis tests stay.
- `loadManifestFonts()`: read `FontManifest.json` via `rootBundle.loadString`, `FontLoader(family)` for every family/asset (`rootBundle.load`).
  This renders Phosphor/Material icon glyphs and ComicRelief in goldens.
- `library_fixtures.dart`: `final libraryFolders`, `final libraryRootDocuments` exactly as in spec §11 (ids `f-ders`, `f-projeler`, `f-okuma`, `f-biyoloji`
  (parentId f-ders); `doc-1`…`doc-8`; colours `AppColors.folderColors[i].toARGB32()`; `updatedAt` 2026-10-21 minus (i-1) days; covered docs use
  `coverId` + `hasCover: true`; docs 4/6/7 use `hasCover: false, coverId: null`; doc 6 `documentType: DocumentType.whiteboard`; doc 7 `isPortrait: false`;
  doc 4 `paperColor: 'Krem kağıt'`). `List<Override> libraryOverrides({bool empty = false, bool selection = false})` with **synchronous** values:
  `foldersProvider.overrideWith((ref) => folders)`, `documentsProvider.overrideWith((ref, folderId) => folderId == null ? docs : const <DocumentInfo>[])`,
  `favoriteDocumentsProvider`, `favoriteFoldersProvider`, `totalDocumentCountProvider.overrideWith((ref) => 8)`,
  `featureFlagsProvider.overrideWithValue(FeatureFlags.allOff)`; selection → `selectionModeProvider.overrideWith((ref) => true)`,
  `selectedDocumentsProvider.overrideWith((ref) => {'doc-1', 'doc-4'})`, `selectedFoldersProvider.overrideWith((ref) => {'f-projeler'})`.
- Golden test: `setUpAll` → `loadAppTestFonts()`, `loadManifestFonts()`, `CoverTextureStore.ensureLoaded()`. Per case: `SharedPreferences.setMockInitialValues`
  (`{StorageKeys.viewMode: 'list'}` for #5, else `{}`), `tester.view.physicalSize`, `devicePixelRatio = 1`, `addTearDown(tester.view.reset)`,
  pump `ProviderScope(overrides:, child: MaterialApp(theme:, debugShowCheckedModeBanner: false, home: DocumentsScreen()))`, `pumpAndSettle`,
  `matchesGoldenFile('goldens/<name>.png')` for the 7 names in spec §11. No PDF fixture. This also proves the screen pumps without GetIt/Drift.
- Verify: dispatch update-goldens (example_app). Read the 7 PNGs and get a ui-designer review of the **tiles only** (header/sidebar are restyled in slice 2).
  Then open PR 1 (`refs #51`, not closes).

---
## PR slice 2: branch `claude/51-library-chrome` from main after PR 1 merges (Steps 8–14)

### Step 8: header widgets
Files: `.../widgets/documents_header.dart` (rewrite), new `.../widgets/library_header_parts.dart`, `.../widgets/sort_popup_button.dart`;
test `documents_header_test.dart` (update).
- Keep the class name `DocumentsHeader` (less churn). New optional params: `String title = ''`, `Widget? breadcrumb`, `VoidCallback? onSettingsTap`,
  `VoidCallback? onMenuTap` (phone drawer), `VoidCallback? onSidebarToggle` (non-null only while collapsed). Existing params stay.
- Build: `AnimatedSwitcher(fast, AppCurves.fade)` between `SelectionModeHeader` and `LayoutBuilder` → `maxWidth >= 720` wide : compact (spec §3 table).
  Wide padding `fromLTRB(xl, md, xl, lg - sm)`. Compact: row 1 `fromLTRB(xs, sm, xs, 0)`, gap xs, row 2 `fromLTRB(lg, 0, lg, md - sm)`.
  Title: `breadcrumb ?? Text(title, displayMedium | headlineLarge, textPrimary, 1 line ellipsis)`.
- Parts (public, in `library_header_parts.dart`): `LibrarySearchField` (Consumer; `AppSearchField(hint: DocumentsStrings.search,
  text: ref.watch(searchQueryProvider), onChanged: → provider)`; hidden in trash), `LibraryViewActions` (sort, view toggle `libraryRows`/`libraryGrid`,
  select `librarySelect`; `AppIconButton` ghost **small** = 48 hit / md icon), `LibraryNewButton({required bool compact, required bool isLocked, required VoidCallback onPressed, super.key})`
  (wide: `AppButton(label: 'Yeni', leadingIcon: isLocked ? libraryLock : libraryPlus, trailingIcon: libraryCaretDown)` in `ConstrainedBox(minHeight: 48)`;
  compact: `AppIconButton` filled `libraryPlus`). `newButtonKey` goes on `LibraryNewButton`. `LibraryTrashInfo` (surface, 1dp border, radius md, `libraryInfo` textMuted, 'Çöpü Boşalt' kept).
- Sort popup: trigger = `AppIconButton` ghost small `librarySort`, tooltip 'Sıralama'. It opens `showMenu<String>` positioned from the button's `RenderBox`
  (same maths as `PopupMenuButton`), `color: surfaceElevated`, `shape: RoundedRectangleBorder(radius lg, side: BorderSide(color: border))`, `elevation: 0`,
  items `height: 48`, labels `labelLarge textPrimary`, current option has a trailing `libraryCheck` in `accent`. Pin uses `palette.accent`. The menu content and `onSelected` logic are unchanged.
- Tests: `Icons.add` → `ElyanotesIcons.libraryPlus` (tap → onNewPressed); 800 wide → one `AppSearchField` + one `AppButton`; at
  `physicalSize 600x800` → compact, `find.byType(AppButton)` none; typing 'bio' + `pump(300ms)` → `searchQueryProvider` == 'bio'
  (`ProviderScope.containerOf(tester.element(find.byType(DocumentsHeader)))`); selection override → `SelectionModeHeader` shown, no search.

### Step 9: screen wiring
Files: `.../screens/documents_screen.dart`, `.../screens/documents_screen_helpers.dart`; new test `.../screens/documents_screen_test.dart` (uses `library_fixtures.dart`).
- Delete `_MobileTopBar`, `_DesktopTopBar`, `_buildSoftDivider`, `_buildMobileTitle`, `_buildDesktopTitle`. Pass title/breadcrumb/onSettingsTap
  (`context.push('/settings')`)/onMenuTap (`_scaffoldKey.currentState?.openDrawer()`, new `GlobalKey<ScaffoldState>`)/onSidebarToggle (tablet && collapsed) to `DocumentsHeader`.
- `didChangeDependencies`: once (`bool _sidebarInitialised`), `_isSidebarCollapsed = MediaQuery.sizeOf(context).width < AppBreakpoints.expanded`.
  Sidebar `AnimatedContainer(duration: AppDurations.fast, curve: _isSidebarCollapsed ? AppCurves.exit : AppCurves.enter)`.
- Decision: `getSectionTitle` returns the sidebar labels 'Tüm Notlar' / 'Favoriler' / 'Son Silinenler' (the spec wireframe shows 'Tüm Notlar'; the old 'Belgeler'/'Çöp' disagree with the sidebar).
- Tests: at 1180×820, `find.byTooltip('Kenar çubuğunu aç')` findsNothing; at 820×1180, findsOneWidget; header shows 'Tüm Notlar'.

### Step 10: selection mode header
File: `.../widgets/selection_mode_header.dart`. One 48 row, padding supplied by `DocumentsHeader`: `[libraryClose] '{n} seçildi' (titleMedium accent) Spacer
[Tümü: TextButton.icon NoSplash, minimumSize 48, labelLarge textMuted, libraryCheckSquare/librarySquare] [libraryCopy] [libraryMove] [libraryTrash, iconColor: hasSelection ? danger : null]`.
All `AppIconButtonSize.medium`. Action logic unchanged. Test: new `selection_mode_header_test.dart`: 'Tümü' selects all ids; delete icon colour = danger when there is a selection.

### Step 11: sidebar
Files: `documents_sidebar.dart`, `sidebar_item.dart`, delete `sidebar_tile.dart`, fix the `[SidebarTile]` doc ref in `menu_tile.dart`; new test `documents_sidebar_test.dart`.
- Spec §8 exactly. `SidebarItem` keeps its constructor: 48 high, margin h sm, padding h md (+lg if subfolder), radius md, icon md, gap md,
  `labelLarge`. Selected: accentContainer fill, accent icon/label w600. No left bar. Nav: `libraryNotebook(Fill)`, `libraryStar(Fill)`, `libraryTrash(Fill)`.
  Folders: `libraryFolderFill` in the folder colour, count caption textMuted tabular. Container: surface + right 1dp border. Remove the nav `AppCard`, dividers and 'Etiketler'.
  Logo/wordmark unchanged (the fallback icon colour → `palette.accent`). Collapse: `librarySidebar` / drawer `libraryClose`, ghost small.
- Test (override `foldersProvider` with fixtures): the three nav labels, no 'Etiketler', tap 'Favoriler' → `onSectionChanged(SidebarSection.favorites)`, 'Biyoloji' subfolder row present.

### Step 12: list view
Files: `documents_list_view.dart`, `document_list_tile.dart`, new `folder_list_tile.dart` (move `FolderListTile` out); tests `documents_list_view_test.dart`, `document_list_tile_test.dart`.
- Spec §7: 64 rows, flat `Material(color: selected ? accentContainer : transparent, radius md)` + NoSplash `InkWell`. Thumb 36×48: cover →
  `CoverPreviewWidget(title: '', showBorder: false)`, else `LibraryPageThumbnail`; folder → `FolderTileArt`. Text `titleLarge` / `LibraryMeta`. Trailing favourite star
  (Fill, textMuted, sm, 48 hit) when favourite and not selecting; then `libraryCaretRight` sm textDisabled, or `LibrarySelectionCheckbox` in selection mode.
  Dividers 1dp `border`, indent 60, between rows of a section. Section labels per spec. List padding `fromLTRB(pad, sm, pad, xxl)`.
  Delete `SelectionCheckbox`, `CompactDocumentThumbnail`, spiral/whiteboard helpers, `_FolderIcon`, `_FolderCountBadge`.
- Tests: rows are 64 high (doc and folder); selection mode → checkbox present and caret absent; existing text finders still pass.

### Step 13: empty states, content view, folder menu
Files: `documents_empty_states.dart`, `documents_content_view.dart`, `folder_menus.dart`, `documents_screen.dart` (pass `onCreateNew`); tests `documents_empty_states_test.dart`, new `folder_menus_test.dart`.
- `DocumentsEmptyState({super.key, this.onCreateNew})` per spec §9 (`CoverPreviewWidget(cover: CoverFamily.linenSand)` 120×160). CTA only when non-null.
  `DocumentsContentView` gets `VoidCallback? onCreateNew`, passed only in the root branch (`parentFolderId == null`, no query).
  Grid/list switch wrapped in `AnimatedSwitcher(fast, AppCurves.fade)` keyed by `ViewMode`.
- Search-empty: icons `librarySearch`/`libraryClose`. The clear button also clears the field (it works through the `text:` sync from Step 2/8).
- Folder menu: add a `MenuTile` after 'Taşı': `folder.isFavorite ? Icons.star : Icons.star_outline`, `DocumentsStrings.addToFavorites`/'Favorilerden Kaldır'
  (match the document menu's copy), → `foldersControllerProvider.notifier.toggleFavorite(folder.id)`.
- Tests: new copy 'Yeni bir defter oluşturun ya da bir PDF içe aktarın.'; 'Yeni not' tap calls onCreateNew; no button when null;
  the folder menu shows 'Favorilere Ekle' for a non-favourite and 'Favorilerden Kaldır' for a favourite.

### Step 14: design loop and PR 2
Dispatch update-goldens and read all 7 PNGs. ui-designer reviews them against the spec §11 checklist (≤3 rounds). Fix, re-render, open PR 2 (`closes #51`).
Follow-up issues: retint `AppShadows`; trash grid on `LibraryGridMetrics`; `AppIconButton` tonal/outline palette; editor icon weight (Light vs BRIEF).

## Risks and YAGNI
- Phosphor names unverified offline (Step 1 isolates this). The Riverpod 2.6 family `overrideWith((ref, arg) => …)` and sync FutureProvider overrides are standard APIs.
- Goldens change on every slice-2 step. Reviewers diff the PNGs; the update-goldens run is the only test runner.
- Filled `AppIconButton` turns from green to ink blue app-wide (settings, manage folders, move dialog). This is intended per the BRIEF; check it in the PR.
- Folder art sits on the box bottom while the cover board ends 0.06w higher. Verify the baseline alignment in the review; if it is off, align the body bottom to `board.bottom`.
- Out: trash/trashed-page restyle, `sidebar.dart` (legacy, unused), menus restyle, logo/wordmark, tonal/outline buttons, alchemist.

## Reference check
The spec §12 check stands (GoodNotes: caret-next-to-name menu, grid/list toggle, select mode; Flexcil: left panel + grid; StarNote: folder lists + search).
Plan-level decisions: the header title repeats the selected sidebar label (GoodNotes "Documents"/folder name pattern). Search is hidden in trash because there it filters nothing visible.
The folder favourite moves into the item menu, like documents (GoodNotes puts favourite in the item menu, not on the thumbnail).
