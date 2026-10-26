/// Application database using Drift (SQLite).
///
/// This database stores documents, folders, sync queue, and sync metadata.
/// Platform-specific connections are handled in native_database.dart and web_database.dart.
library;

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

/// Documents table schema
@DataClassName('DocumentRow')
class Documents extends Table {
  /// Unique document ID
  TextColumn get id => text()();

  /// Document title
  TextColumn get title => text()();

  /// Parent folder ID (nullable for root documents)
  TextColumn get folderId => text().nullable()();

  /// Template ID used for this document
  TextColumn get templateId => text()();

  /// When the document was created
  DateTimeColumn get createdAt => dateTime()();

  /// When the document was last updated
  DateTimeColumn get updatedAt => dateTime()();

  /// Path to thumbnail image
  TextColumn get thumbnailPath => text().nullable()();

  /// Number of pages in the document
  IntColumn get pageCount => integer().withDefault(const Constant(1))();

  /// Whether document is marked as favorite
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Whether document is in trash
  BoolColumn get isInTrash => boolean().withDefault(const Constant(false))();

  /// Sync state: 0=local, 1=syncing, 2=synced, 3=error
  IntColumn get syncState => integer().withDefault(const Constant(0))();

  /// When the document was moved to trash (null if not trashed)
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Legacy content blob, unused since v6 (see [DocumentContents]).
  BlobColumn get content => blob().nullable()();

  /// Paper color: 'Beyaz kağıt', 'Sarı kağıt', 'Gri kağıt'
  TextColumn get paperColor =>
      text().withDefault(const Constant('Sarı kağıt'))();

  /// Orientation: true=portrait, false=landscape
  BoolColumn get isPortrait => boolean().withDefault(const Constant(true))();

  /// Document type: 'notebook', 'whiteboard', 'quickNote', etc.
  TextColumn get documentType =>
      text().withDefault(const Constant('notebook'))();

  /// Cover ID (nullable - references CoverRegistry)
  TextColumn get coverId => text().nullable()();

  /// Whether document has a cover page
  BoolColumn get hasCover => boolean().withDefault(const Constant(true))();

  /// Paper width in millimeters (default A4: 210mm)
  RealColumn get paperWidthMm => real().withDefault(const Constant(210.0))();

  /// Paper height in millimeters (default A4: 297mm)
  RealColumn get paperHeightMm => real().withDefault(const Constant(297.0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Folders table schema
@DataClassName('FolderRow')
class Folders extends Table {
  /// Unique folder ID
  TextColumn get id => text()();

  /// Folder name
  TextColumn get name => text()();

  /// Parent folder ID (nullable for root folders)
  TextColumn get parentId => text().nullable()();

  /// Folder color as integer value
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF2196F3))();

  /// Manual sort position
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Whether the folder is marked as favorite
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// When the folder was created
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Serialized drawing content of a document (one row per document).
class DocumentContents extends Table {
  /// Owning document ID
  TextColumn get documentId => text()();

  /// Content as JSON text
  TextColumn get data => text()();

  /// When the content was last written
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {documentId};
}

/// Pages removed from a document, kept until restored or purged.
@TableIndex(
    name: 'trashed_pages_source_document_idx', columns: {#sourceDocumentId})
class TrashedPages extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text()();
  TextColumn get sourceDocumentId => text()();
  TextColumn get sourceDocumentTitle => text()();
  IntColumn get originalPageIndex => integer()();
  DateTimeColumn get deletedAt => dateTime()();

  /// Page JSON
  TextColumn get pageData => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync queue table schema
class SyncQueue extends Table {
  /// Unique queue item ID
  TextColumn get id => text()();

  /// ID of the entity being synced
  TextColumn get entityId => text()();

  /// Type of entity: 0=document, 1=folder
  IntColumn get entityType => integer()();

  /// Action to perform: 0=create, 1=update, 2=delete
  IntColumn get action => integer()();

  /// When this item was added to the queue
  DateTimeColumn get createdAt => dateTime()();

  /// Number of retry attempts
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Error message from last attempt
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync metadata table schema
class SyncMetadata extends Table {
  /// Metadata key
  TextColumn get key => text()();

  /// Metadata value
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Local AI conversation storage.
class AiConversationsLocal extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text().withDefault(const Constant('Yeni Sohbet'))();
  TextColumn get documentId => text().nullable()();
  TextColumn get taskType => text().withDefault(const Constant('chat'))();
  IntColumn get totalInputTokens => integer().withDefault(const Constant(0))();
  IntColumn get totalOutputTokens => integer().withDefault(const Constant(0))();
  IntColumn get messageCount => integer().withDefault(const Constant(0))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local AI message storage.
class AiMessagesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId =>
      text().references(AiConversationsLocal, #id)();
  TextColumn get role => text()(); // 'user', 'assistant', 'system'
  TextColumn get content => text()();
  TextColumn get model => text().nullable()();
  TextColumn get provider => text().nullable()();
  IntColumn get inputTokens => integer().withDefault(const Constant(0))();
  IntColumn get outputTokens => integer().withDefault(const Constant(0))();
  BoolColumn get hasImage => boolean().withDefault(const Constant(false))();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Application database
@DriftDatabase(tables: [
  Documents,
  Folders,
  DocumentContents,
  TrashedPages,
  SyncQueue,
  SyncMetadata,
  AiConversationsLocal,
  AiMessagesLocal,
])
class AppDatabase extends _$AppDatabase {
  /// Creates the database; pass [e] to use a custom executor (tests).
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await customStatement(
            'ALTER TABLE documents ADD COLUMN paper_color TEXT NOT NULL DEFAULT "Sarı kağıt"',
          );
          await customStatement(
            'ALTER TABLE documents ADD COLUMN is_portrait INTEGER NOT NULL DEFAULT 1',
          );
        }
        if (from < 3) {
          await customStatement(
            'ALTER TABLE documents ADD COLUMN document_type TEXT NOT NULL DEFAULT "notebook"',
          );
        }
        if (from < 4) {
          await customStatement(
            'ALTER TABLE documents ADD COLUMN cover_id TEXT',
          );
          await customStatement(
            'ALTER TABLE documents ADD COLUMN has_cover INTEGER NOT NULL DEFAULT 1',
          );
          await customStatement(
            'ALTER TABLE documents ADD COLUMN paper_width_mm REAL NOT NULL DEFAULT 210.0',
          );
          await customStatement(
            'ALTER TABLE documents ADD COLUMN paper_height_mm REAL NOT NULL DEFAULT 297.0',
          );
        }
        if (from < 5) {
          await m.createTable(aiConversationsLocal);
          await m.createTable(aiMessagesLocal);
        }
        if (from < 6) {
          await m.addColumn(documents, documents.deletedAt);
          await m.addColumn(folders, folders.sortOrder);
          await m.addColumn(folders, folders.isFavorite);
          await m.createTable(documentContents);
          await m.createTable(trashedPages);
          await m.createIndex(trashedPagesSourceDocumentIdx);
        }
      },
    );
  }

  /// Opens the on-disk database on a background isolate, so queries and
  /// writes of large document content never block UI frames.
  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      if (Platform.isAndroid) {
        // Drift's recommended setup for sqlite3_flutter_libs (Android <= 6).
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      }
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'elyanotes.db'));
      return NativeDatabase.createInBackground(
        file,
        // Android has no writable /tmp for sqlite's temp files (large sorts,
        // migrations); keep them in memory instead.
        setup: (db) => db.execute('PRAGMA temp_store = MEMORY'),
      );
    });
  }
}
