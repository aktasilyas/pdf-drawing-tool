# 208 — Document content and Drift off the UI isolate

Issue: #208. Small, contained change (no architect round needed beyond the
issue's own design): 3 production files, tests and a benchmark.

## Design
- `AppDatabase._openConnection()` opens the file with
  `NativeDatabase.createInBackground` (drift's documented setup, including
  `applyWorkaroundToOpenSqlite3OnOldAndroidVersions()` on Android). Tests keep
  injecting `NativeDatabase.memory()`.
- New `DocumentContentCodec` (documents/data): `encode`/`decode` of content
  JSON. Payloads above a threshold (content weight >= 5000 pages+strokes+points,
  or JSON >= 128 KiB) run in `Isolate.run`; smaller ones stay inline because
  spawning an isolate costs more than encoding a few pages. Decoded maps come
  back via `Isolate.exit` (no copy). `DocumentContentCodec.inline()` is the
  benchmark baseline.
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
