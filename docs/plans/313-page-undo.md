# 313 — Undo for add/duplicate/paste/move page; fresh ids on duplicate

## Acceptance
- Add (panel, template picker, image page, swipe-add), duplicate, paste and move go through
  `PageStructureActions`; `pageManagerProvider` synced via `_apply`.
- Each shows the delete-style snackbar ('Geri al'); undo restores the previous page order,
  page set and current page (by id). Page *contents* edited since are kept (deliberate: restoring
  old `Page` objects would drop strokes drawn on other pages meanwhile).
- Duplicated/pasted pages: fresh page, layer and element ids (strokes, shapes, texts, images,
  sticky notes and their inner strokes/shapes); elementOrder remapped. Test proves no shared id.
- Unit tests per op + undo; analyze + drawing_core + drawing_ui tests green.

## drawing_core
1. `String? id` in copyWith of Shape, TextElement, ImageElement, StickyNote.
2. `models/page_copy.dart`: `extension PageCopy on Page { Page copyWithFreshIds() }`.
   Page id `page_${ElementIds.next()}`, layer ids + all element ids via `ElementIds.next()`,
   elementOrder remapped (unknown ids dropped), isCover/isBookmarked false, thumbnail null,
   fresh createdAt/updatedAt. Exported from the barrels. Test `test/models/page_copy_test.dart`.
3. `DocumentPageOps.replacePages(List<Page>, {String? currentPageId})` over `_withPages`.

## drawing_ui
4. `providers/page_structure_actions.dart`: `PageStructureChange {documentId, previousOrder,
   previousCurrentId, insertedPageId?}`. `insertPage(int index, Page page)` (selects it),
   `insertCopy(int afterIndex, Page source)` (copyWithFreshIds at afterIndex+1, selects it),
   `movePage` returns `PageStructureChange?`. `bool undo(change)`: false if doc id differs or
   current id set != previousOrder ∪ {insertedPageId}; else rebuild in previousOrder from current
   Page objects, restore current by id, `_apply`.
5. `panels/page_structure_undo.dart`: `showPageUndoSnackBar(messenger, actions, change, message)`
   (hideCurrentSnackBar + SnackBar + 'Geri al').
6. Callers (capture actions + messenger BEFORE closing popovers): page_options_actions
   duplicate/paste (delete `_insertDeepCopy`); add_page_panel `_insertNewPage`/`_openTemplatePicker`;
   drawing_screen_navigation `_addPageAfterLast`; page_sidebar reorder.
   Strings (Turkish until the editor l10n slice of #201): 'Sayfa eklendi/çoğaltıldı/yapıştırıldı/taşındı'.

## Tests
- `test/providers/page_structure_actions_test.dart`: insert/insertCopy/move + undo each;
  undo keeps edits on other pages; undo is a no-op after an unrelated delete / doc switch;
  history undo of an entry on the removed inserted page leaves the doc unchanged.
- Widget test: duplicate from page options shows snackbar; tapping 'Geri al' restores the pages.

## Risks / out of scope
- Undoing an add removes a page the user may have drawn on during the snackbar window (no trash). Accepted.
- Undoing an image-page add leaves the copied file in elyanotes_images (orphan); follow-up if needed.
- No redo, no page-level history stack (v1.0).

## Reference check
GoodNotes: page add/duplicate/move are undoable via editor undo. Flexcil and StarNote: page
add/duplicate can be reversed right after the action. → We use our existing transient undo
snackbar for every page-structure change: one pattern, no history stack for pages in v1.0.
