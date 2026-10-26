# 208 — Document content and Drift off the UI isolate

Issue: #208. Small, contained change (no architect round needed beyond the
issue's own design): 3 production files, tests and a benchmark.

## Design
- `AppDatabase._openConnection()` opens the file with
  `NativeDatabase.createInBackground` (drift's documented setup, including
  `applyWorkaroundToOpenSqlite3OnOldAndroidVersions()` on Android). Tests keep
  injecting `NativeDatabase.memory()`.
- New `DocumentContentCodec` (documents/data). Small payloads are handled in
  one go (spawning an isolate costs more than encoding a few pages).
  - Decode of JSON >= 128 KiB runs in `Isolate.run`: the string goes in
    cheaply, the map comes back via `Isolate.exit` without a copy.
  - Encode of content weight >= 5000 (pages + strokes + points) runs page by
    page on the calling isolate, yielding to the event loop every 4 ms.
    First attempt used `Isolate.run` for encode too, but the benchmark showed
    the synchronous copy of the map graph into the isolate (331 ms for 300
    pages) costs more than encoding it, so encode is time-sliced instead.
  - `DocumentContentCodec.inline()` is the benchmark baseline.
- `DocumentLocalDatasourceImpl` takes the codec (optional, defaults to the
  offloading one) for `getDocumentContent`, `saveDocumentContent` and the PDF
  path scan on delete. Errors still become `CacheException`, so the
  repositories' `Either<Failure, T>` contract is unchanged.

## Not in this change
`DrawingDocument.toJson()` / `fromJson()` in the save/load use cases still run
on the UI isolate (the benchmark prints its cost). Moving them needs the
repository API to take a document instead of a map; follow-up if the numbers
warrant it.

## Tests
- `document_content_codec_test.dart`: weight estimate, inline vs isolate
  output equality, errors on the isolate path, 300-page round-trip through the
  datasource, corrupt content → `CacheException`.
- `document_content_save_benchmark_test.dart`: longest event-loop stall per
  save/load, before vs after; printed as `[content-bench]` in the CI log.
