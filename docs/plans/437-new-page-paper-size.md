# Plan: #437 new pages use the notebook's paper size

## Reference check
GoodNotes, StarNote, Flexcil: a new page inherits the notebook's (current
page's) paper size and orientation; changing size is an explicit page-format
choice. → We match: new pages inherit.

## Steps
1. `LoadDocumentUseCase`: new notebooks get
   `settings.defaultPageSize = <first page size>` (portrait/landscape tests).
2. `drawing_ui/services/new_page_size.dart` — `resolveNewPageSize(doc, i)`:
   non-A4-fallback settings win; legacy A4 settings → current template page
   size, else last template page (not cover/PDF/image), else the default.
   PDF-only notebooks therefore keep the A4 default (unit tests).
3. Use it at every "new page" site: add page panel (quick template, template
   picker, import default), swipe-to-add, add-page preview.
4. Widget test: landscape notebook, quick-template add and import default.
