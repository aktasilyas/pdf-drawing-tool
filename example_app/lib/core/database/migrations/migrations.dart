import 'package:drift/drift.dart';
import 'package:example_app/core/database/app_database.dart';

/// Applies every schema step above [from], in order.
Future<void> runMigrations(AppDatabase db, Migrator m, int from) async {
  if (from < 2) await migrateToV2(db);
  if (from < 3) await migrateToV3(db);
  if (from < 4) await migrateToV4(db);
  if (from < 5) await migrateToV5(db, m);
  if (from < 6) await migrateToV6(db, m);
}

/// v2: paper color and orientation on documents.
Future<void> migrateToV2(AppDatabase db) async {
  await db.customStatement(
    'ALTER TABLE documents ADD COLUMN paper_color TEXT NOT NULL DEFAULT "Sarı kağıt"',
  );
  await db.customStatement(
    'ALTER TABLE documents ADD COLUMN is_portrait INTEGER NOT NULL DEFAULT 1',
  );
}

/// v3: document type.
Future<void> migrateToV3(AppDatabase db) async {
  await db.customStatement(
    'ALTER TABLE documents ADD COLUMN document_type TEXT NOT NULL DEFAULT "notebook"',
  );
}

/// v4: cover and paper size.
Future<void> migrateToV4(AppDatabase db) async {
  await db.customStatement('ALTER TABLE documents ADD COLUMN cover_id TEXT');
  await db.customStatement(
    'ALTER TABLE documents ADD COLUMN has_cover INTEGER NOT NULL DEFAULT 1',
  );
  await db.customStatement(
    'ALTER TABLE documents ADD COLUMN paper_width_mm REAL NOT NULL DEFAULT 210.0',
  );
  await db.customStatement(
    'ALTER TABLE documents ADD COLUMN paper_height_mm REAL NOT NULL DEFAULT 297.0',
  );
}

/// v5: local AI conversation tables.
Future<void> migrateToV5(AppDatabase db, Migrator m) async {
  await m.createTable(db.aiConversationsLocal);
  await m.createTable(db.aiMessagesLocal);
}

/// v6: trash timestamps, folder ordering, content and trashed-page tables.
Future<void> migrateToV6(AppDatabase db, Migrator m) async {
  await m.addColumn(db.documents, db.documents.deletedAt);
  await m.addColumn(db.folders, db.folders.sortOrder);
  await m.addColumn(db.folders, db.folders.isFavorite);
  await m.createTable(db.documentContents);
  await m.createTable(db.trashedPages);
  await m.createIndex(db.trashedPagesSourceDocumentIdx);
}
