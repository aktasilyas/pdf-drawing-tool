# 390 — Bulk library actions survive partial failures

Issue: #390. Size S–M, example_app only.

## Reference check
GoodNotes and Flexcil apply multi-select actions per item and report failures
without undoing the successful ones → same: every id is tried, successes stay,
only failed items stay selected, one message says how many failed.

## Steps
1. `BulkResult` (presentation/providers): `succeeded`, `failed`, `total`,
   `hasFailures`. Exported from `documents.dart`.
2. `DocumentsBulkOperations`: `moveDocumentsToTrash`,
   `permanentlyDeleteDocuments`, `duplicateDocuments` (and the deprecated
   `deleteDocuments`) run through one `_runBulk` helper: try every id (a
   `Left` or a thrown error marks the id failed), refresh the lists once,
   set `AsyncError` + report the first failure with counts, return the
   result. Nothing is thrown.
3. `LibraryError` gains optional `failedCount` / `totalCount`;
   `message()` wraps the usual text in the new `libraryErrorBulkPartial`
   string ("… (1 of 3 failed)" / "… (3 belgeden 1 tanesi başarısız)").
4. `SelectionModeHeader`: on failures keep only `result.failed` selected
   (folders cleared, selection mode stays); on full success unchanged.
5. Tests: controller tests with a failing middle id per action and a
   throwing repository; `LibraryError` message in en/tr; header widget test
   for partial failure and full success.

`moveDocumentsToFolder` is out of scope (not listed in the issue).
