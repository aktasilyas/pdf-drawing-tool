# Plan: #369 library tile preview without storage work on rebuild

## Design
1. `DocumentContentCodec.decodeFirstPageBackground(String)`: decodes the JSON
   (background isolate above `decodeOffloadLength`) and returns only
   `pages[0].background` of V2 content; null for V1/empty/odd shapes; throws on
   invalid JSON. Page and stroke models are not built.
2. `DocumentLocalDatasource.getFirstPageBackground(id)`: missing row → null,
   decode/parse error → `CacheException('Document corrupted: …')`.
3. `DocumentRepository.getFirstPageBackground(id)` →
   `Either<Failure, PageBackground?>`, implemented in the `DocumentQueries`
   mixin (the impl file is at the 300-line limit).
4. `documentPreviewBackgroundProvider`: `FutureProvider.autoDispose.family`
   keyed by `({String id, DateTime updatedAt})`; Left → null.
5. `DocumentPreview` watches the provider: loading → spinner, null/error →
   plain paper (`SizedBox.shrink`), else image / PDF thumbnail as before.
   Drops the cross-feature `editor_provider` import.

## Trade-offs
- autoDispose, not keepAlive: image backgrounds hold their bytes; scrolling a
  tile back in re-queries one row and decodes the background only.
- The whole content string is still `jsonDecode`d; a streaming/partial parse
  is left out until profiling asks for it.
- No schema change (no denormalised cover-background column).

## Tests
- `test/features/documents/data/first_page_background_test.dart`: codec
  (V2, isolate path with image bytes, V1/odd shapes, invalid JSON) and
  repository over in-memory Drift (stored, missing → null, corrupt → Left).
- `test/features/documents/presentation/widgets/document_preview_test.dart`:
  two pumps → one repository call; new `updatedAt` → reload; Left / null →
  no spinner, no image.

## Reference check
GoodNotes, StarNote and Flexcil show the first page as the library thumbnail
and blank paper while loading or on failure. Behaviour unchanged here; only
the data path changes.
