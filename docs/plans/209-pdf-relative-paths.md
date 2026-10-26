# Plan: #209 — container-relative PDF paths, missing-source state, no orphans

## Acceptance
- AC1: new pages store `pdfs/<name>.pdf`; reads resolve against the current documents
  root; a legacy absolute path whose parent dir is `pdfs` resolves to `<root>/pdfs/<name>`
  (test: `/data/user/0/old.pkg/app_flutter/pdfs/a.pdf` + a different temp root).
- AC2: a missing source PDF shows "Kaynak PDF bulunamadı" instead of the generic
  "PDF Sayfası" placeholder (widget test); an existing file that fails to render keeps
  the generic placeholder.
- AC3: no file remains in `pdfs/` after a failed copy, a failed lazy import or a failed
  document insert (temp-dir tests).

## Design
- `drawing_core`: pure-Dart `PdfPathResolver(documentsRoot)` with `toStored(abs)` and
  `resolve(stored)`, `passthrough` (root null → unchanged), handles `/` and `\`.
- Paths are resolved only where a file is opened: `pdfPageRasterizerProvider`,
  `renderThumbnail`, `PDFExporter`, `ThumbnailGenerator`, datasource `_deleteFile`.
  Cache keys and `currentPdfFilePathProvider` keep the stored string.
- `drawing_ui`: `pdfPathResolverProvider` (default passthrough, overridden by example_app
  with the documents root) and `pdfSourceMissingProvider.family` (checked only after a
  null render). No painter/widget calls path_provider.
- Import: one store-and-import wrapper in `pdf_import_storage.dart` deletes the copied
  file on any failure; `commitPdfImport` in example_app deletes the stored PDFs when
  `createDocumentWithPages` returns null or throws.
- Label: `PdfBackgroundStrings` const class with Turkish defaults, injectable by the
  drawing_ui l10n slice after #201.
- No DB migration: legacy absolute paths are resolved when read.
- `document_local_datasource.dart`: constructor field + `_deleteFile` only (#214 overlap).

## Left out
DB rewrite of old paths, "relink PDF", startup orphan sweep, splitting
`thumbnail_generator.dart` (505 lines).

## Reference check
GoodNotes, StarNote and Flexcil copy imported PDFs into the app container and reference
them relative to it, and show a missing-file state rather than a blank page → same here.
