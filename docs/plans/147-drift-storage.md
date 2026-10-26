# Plan: move documents, folders, content and trashed pages to Drift (#147)

## Decision
Metadata and content both live in Drift (SQLite). One database makes the content + metadata write atomic and gives crash safety. Datasource interfaces stay; implementations become Drift-backed.

## Schema v6
- `Documents`: add nullable `deletedAt`; `@DataClassName('DocumentRow')`; legacy `content` blob column unused.
- `Folders`: add `sortOrder`, `isFavorite`; `@DataClassName('FolderRow')`.
- New `DocumentContents(documentId pk, data json text, updatedAt)`.
- New `TrashedPages(id pk, pageId, sourceDocumentId, sourceDocumentTitle, originalPageIndex, deletedAt, pageData)` + index on sourceDocumentId.
- `AppDatabase([QueryExecutor? e])` for tests. No foreign keys; content rows deleted explicitly in the same transaction.

## Transactions
`LocalTransactionRunner` (data layer) wraps `db.transaction`. Used by saveDocumentContent, duplicate, permanent delete, restore page from trash, deleteFolder. Duplicate becomes all-or-nothing.

## Prefs migration
`PrefsToDriftMigration` imports `documents`, `folders`, `trashed_pages`, `document_content_<id>` with insertOrIgnore in one transaction, sets flag `migration.prefs_documents_v1` in SyncMetadata, then removes keys. Corrupt entries are skipped and kept. Idempotent.

## DI order
prefs -> AppDatabase singleton -> runner -> migration -> datasources -> repositories. `appDatabaseProvider` returns the GetIt instance (single DB).

## Steps
1. Schema v6 + migration test + build_runner.
2. Runner, core barrel export, single DB instance.
3. Drift Folder + TrashedPage datasources.
4. Drift Document datasource (+ `hasDocumentContent`).
5. Prefs migration.
6. Transactional DocumentRepositoryImpl (+ AC3 rollback, AC4 50-page round trip).
7. PageTrash + Folder repositories on the runner, no prefs.
8. Repository behaviour suite (rename, move, restore, permanent delete, duplicate, folder delete).
9. DI wiring; rewrite prefs-mocking tests.

## Reference check
GoodNotes, Flexcil and StarNote keep notebooks in an on-device structured store; portable files are only export/backup. We use Drift as CLAUDE.md requires.
