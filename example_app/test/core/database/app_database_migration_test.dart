import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/core.dart';

/// Opens an in-memory database that looks like a v5 install.
NativeDatabase _v5Database() {
  return NativeDatabase.memory(
    setup: (raw) {
      raw.execute('''
        CREATE TABLE documents (
          id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL,
          folder_id TEXT, template_id TEXT NOT NULL,
          created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
          thumbnail_path TEXT, page_count INTEGER NOT NULL DEFAULT 1,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          is_in_trash INTEGER NOT NULL DEFAULT 0,
          sync_state INTEGER NOT NULL DEFAULT 0, content BLOB,
          paper_color TEXT NOT NULL DEFAULT 'Sarı kağıt',
          is_portrait INTEGER NOT NULL DEFAULT 1,
          document_type TEXT NOT NULL DEFAULT 'notebook',
          cover_id TEXT, has_cover INTEGER NOT NULL DEFAULT 1,
          paper_width_mm REAL NOT NULL DEFAULT 210.0,
          paper_height_mm REAL NOT NULL DEFAULT 297.0)''');
      raw.execute('''
        CREATE TABLE folders (
          id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, parent_id TEXT,
          color_value INTEGER NOT NULL DEFAULT 4280391411,
          created_at INTEGER NOT NULL)''');
      raw.execute(
        "INSERT INTO documents (id, title, template_id, created_at, updated_at)"
        " VALUES ('d1', 'Old', 'blank', 1700000000, 1700000000)",
      );
      raw.execute(
        "INSERT INTO folders (id, name, created_at)"
        " VALUES ('f1', 'Old folder', 1700000000)",
      );
      raw.execute('PRAGMA user_version = 5');
    },
  );
}

void main() {
  test('v5 to v6 keeps rows and adds the new columns and tables', () async {
    final db = AppDatabase(_v5Database());
    addTearDown(db.close);

    final doc = await (db.select(db.documents)..where((t) => t.id.equals('d1')))
        .getSingle();
    expect(doc.title, 'Old');
    expect(doc.deletedAt, isNull);

    final folder = await db.select(db.folders).getSingle();
    expect(folder.name, 'Old folder');
    expect(folder.sortOrder, 0);
    expect(folder.isFavorite, isFalse);

    expect(await db.select(db.documentContents).get(), isEmpty);
    expect(await db.select(db.trashedPages).get(), isEmpty);

    final indexes = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND tbl_name = 'trashed_pages'",
        )
        .get();
    expect(
      indexes.map((r) => r.read<String>('name')),
      contains('trashed_pages_source_document_idx'),
    );
  });

  test('a fresh database is created at schema v6', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 6);
    expect(await db.select(db.trashedPages).get(), isEmpty);
  });
}
