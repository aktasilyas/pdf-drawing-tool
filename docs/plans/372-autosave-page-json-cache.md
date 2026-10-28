# #372 Autosave: cache encoded page JSON by Page identity

Reference check: not applicable (internal save performance; stored format and
UX unchanged, as stated in the issue).

## 1. Problem and acceptance criteria
Every autosave (3 s debounce, `AutoSaveNotifier`) runs `DocumentJsonSlicer.toJson`
over the whole document (`page.toJson()` x N) and then `DocumentContentCodec.encode`
runs `jsonEncode` over every page again. Cost tracks document size, not the edit.
Held to:
- AC1 Encoded page JSON is cached by `Page` identity (`Expando`), scoped to the
  editor session; unchanged pages are neither converted nor encoded again.
- AC2 Stored string is byte-identical to the uncached path (existing codec /
  slicer tests stay green + new equality test over a multi-page doc).
- AC3 Save after changing one page of a 300-page doc: <= 1 page encode
  (counted through an injected encoder); an unchanged re-save: 0.
- AC4 Cache is dropped when the editor session ends and reset when a different
  document id is saved (no growth across documents).

## 2. Affected files
- `example_app/lib/features/documents/domain/entities/encoded_json.dart` (new):
  `EncodedJson` value type = already-encoded JSON text. Exported in `documents.dart`.
- `example_app/lib/features/documents/data/datasources/document_content_codec.dart`:
  write `EncodedJson` page entries verbatim; any pre-encoded page forces the
  stitched path.
- `example_app/lib/features/editor/domain/usecases/page_json_cache.dart` (new):
  `PageJsonCache` (Expando + encoder seam). Exported in `editor.dart`.
- `.../editor/domain/usecases/document_json_slicer.dart`: optional `cache`;
  pages come from the cache, header built without encoding a real page.
- `.../editor/domain/usecases/save_document_usecase.dart`: owns a `PageJsonCache`
  (constructor-injected), resets it on document-id change; cover cleaning keeps
  page identity when the cover has no drawings.
- `example_app/lib/core/di/injection.dart`: no change needed (default cache
  created by the constructor); only touched if the reviewer wants it explicit.
- `.../editor/presentation/screens/editor_screen.dart`: `ref.invalidate(
  saveDocumentUseCaseProvider)` next to `ref.invalidate(autoSaveProvider)`.
- Tests: see section 4.

## 3. Design
```dart
// documents/domain/entities/encoded_json.dart
final class EncodedJson {
  const EncodedJson(this.text);
  final String text;                 // output of jsonEncode(...)
  /// Safety net: a plain jsonEncode of a map holding this still yields the
  /// same bytes (slow path), so no consumer can silently corrupt content.
  Object? toJson() => jsonDecode(text);
}

// editor/domain/usecases/page_json_cache.dart
typedef PageEncoder = String Function(Page page);
class PageJsonCache {
  PageJsonCache({PageEncoder? encoder}) : _encoder = encoder ?? defaultEncoder;
  static String defaultEncoder(Page page) => jsonEncode(page.toJson());
  EncodedJson encode(Page page);     // _entries[page] ??= EncodedJson(_encoder(page))
  void retainFor(String documentId); // clear() when id differs from the last one
  void clear();                      // _entries = Expando<EncodedJson>('page-json')
}

// DocumentJsonSlicer
Future<Map<String, dynamic>> toJson(DrawingDocument d, {PageJsonCache? cache});
// SaveDocumentUseCase
SaveDocumentUseCase(this._repository,
    {DocumentJsonSlicer slicer = const DocumentJsonSlicer(), PageJsonCache? pageCache});
```
Data flow: `AutoSaveNotifier` -> `SaveDocumentUseCase.call(doc)` (signature
unchanged, so the 6 test files stubbing `save(any())` are untouched) ->
`_pageCache.retainFor(doc.id)` -> slicer builds `{..header, 'pages': [EncodedJson...]}`
-> repository -> datasource -> `codec.encode` stitches `{"k":v,...,"pages":[text,text]}`.
- Slicer with a cache: multi-page docs always go page by page (no weight
  threshold); header = `document.copyWith(pages: [pages.first.copyWith(layers: const [])])
  .toJson()` so key order is preserved and no real page is converted; the
  `pages` entry is replaced. Stopwatch yielding stays (misses can be heavy).
  Single-page (V1) docs: unchanged `document.toJson()`.
- Codec: `encode` takes the stitched path when `pages` holds any `EncodedJson`
  (weight check otherwise unchanged); in the loop
  `out.write(p is EncodedJson ? p.text : jsonEncode(p))`.
- Cover pages: today `clearDrawings()` makes a new Page (and bumps `updatedAt`)
  every save -> guaranteed miss. Change to clear only when the cover actually
  holds strokes/shapes/texts (private `_hasDrawings(page)` in the use case).
- State ownership: the cache lives in the `SaveDocumentUseCase` instance held by
  `saveDocumentUseCaseProvider` (one per editor session). Lifetime ends via
  `ref.invalidate(saveDocumentUseCaseProvider)` in `_handleBack`; `retainFor`
  covers other leave paths. Expando keys are weak, so replaced pages are
  collectable even mid-session. Saves are serialised by `_tail`, so the cache
  is never mutated concurrently.
- Layer rules: domain (`editor`) produces `EncodedJson`, data (`documents`)
  consumes it through the documents domain barrel: `presentation -> domain <- data`
  holds. `EncodedJson` sits in domain because the repository contract already
  carries a JSON map. No rule bent. All new files well under 300 lines.

## 4. Test plan (TDD, mocktail where mocks are needed)
- `test/features/documents/data/datasources/document_content_codec_test.dart`:
  + content with `EncodedJson` pages encodes to the same string as `jsonEncode`
  of the plain maps, small and above `encodeSliceWeight`; + `jsonEncode` of a
  map holding `EncodedJson` equals the plain encoding (safety net).
- `test/features/editor/domain/usecases/page_json_cache_test.dart` (new):
  same Page twice -> 1 encoder call; new Page instance -> miss; `clear` and
  `retainFor(otherId)` drop entries, `retainFor(sameId)` keeps them.
- `test/features/editor/domain/usecases/document_json_slicer_test.dart`:
  + `codec.encode(await slicer.toJson(doc, cache: c))` == `jsonEncode(doc.toJson())`
  for a multi-page doc with strokes (AC2); + header keys/order equal `doc.toJson()`.
- `test/features/editor/domain/usecases/save_document_usecase_test.dart`
  (or new `save_document_page_cache_test.dart` if >300 lines):
  300-page doc with a counting `PageEncoder`; first save 300 calls, re-save 0,
  save after `replacePages` of one page 1 (AC3); cover without drawings keeps
  identity (0 calls on re-save); different document id resets (AC4).
  Repository: real `DocumentContentCodec` via `LibraryFixture` (in-memory) for one
  end-to-end byte check, mocks elsewhere.
- `test/features/editor/presentation/...`: no new widget test; behaviour is
  not visible. Invalidate line covered by existing editor_screen tests.

## 5. Steps (one implementer run each)
1. `EncodedJson` + codec support. Files: encoded_json.dart, documents.dart,
   document_content_codec.dart, codec test. Verify:
   `cd example_app && flutter test test/features/documents/data/datasources/document_content_codec_test.dart`
2. `PageJsonCache` with encoder seam. Files: page_json_cache.dart, editor.dart,
   page_json_cache_test.dart. Verify: `flutter test test/features/editor/domain/usecases/page_json_cache_test.dart`
3. Slicer `cache` parameter + header without page conversion + equality test.
   Verify: `flutter test test/features/editor/domain/usecases/document_json_slicer_test.dart`
4. Use case: inject cache, `retainFor`, cover identity, 300-page counting test.
   Verify: `flutter test test/features/editor/domain/usecases/`
5. Session end: invalidate `saveDocumentUseCaseProvider` in `_handleBack`.
   Verify: `flutter test test/features/editor/` then `./scripts/check.sh analyze`
   and `./scripts/check.sh test example_app`.

## 6. Risks and left out
- Risk: an editor op that rebuilds every Page (e.g. renumber after inserting at
  the front, template change on all pages) re-encodes those pages; correct, just
  no saving. Acceptable.
- Risk: a future consumer reading `content['pages'][i]` as a Map before
  encoding gets `EncodedJson`; mitigated by `toJson()` fallback and the existing
  `save_document_usecase_test` check (`pages is List`), which still passes.
- Risk: cover `updatedAt` no longer bumps on every save (only when drawings are
  cleared). Not read anywhere for covers; intended.
- Left out (YAGNI): per-page DB rows / partial row updates (datasource still
  writes the full string; the string is cheap to stitch), caching the header,
  isolate offload, any change to load/decode, LRU size limits (Expando + weak keys
  + session reset suffice).
