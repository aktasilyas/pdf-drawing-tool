# #475 Clipboard file references

Reference check: GoodNotes, StarNote and Flexcil paste pages/images between notebooks with their content regardless of the source still existing -> we keep clipboard-referenced files alive and refuse to paste a broken page.

## Design (option a from the issue)
1. `drawing_ui`: `clipboardFileRefsProvider` (`Provider<Set<String>>`) = stored file paths (PDF background, image background, image elements) of `copiedPageProvider` + `selectionClipboardProvider`. Exported via the barrel.
2. `example_app` core: `ClipboardFileRefs` (lazy singleton, GetIt) holding `Set<String> Function() paths` (default empty). `ManagedFileCleanup` treats a path in it as referenced, so `deleteDocument`, page-trash purge and `deleteUnreferencedFiles` skip it. Startup sweep runs with an empty clipboard, so files are collected later (no permanent leak).
3. App root wires `ClipboardFileRefs.paths` to `container.read(clipboardFileRefsProvider)`.
4. Paste guard in `drawing_ui`: before page paste / selection paste, check that referenced files exist (via `pdfPathResolverProvider`); if not, clear nothing, insert nothing, show localized SnackBar.

## Tests
- unit: cleanup keeps clipboard-referenced files on deleteDocument, trash purge, selection image; deletes after supplier returns empty.
- widget: pasting a page with missing files shows SnackBar, inserts nothing.
