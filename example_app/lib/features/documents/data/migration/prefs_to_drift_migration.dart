import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/models/document_model.dart';
import 'package:example_app/features/documents/data/models/folder_model.dart';
import 'package:example_app/features/documents/data/models/trashed_page_model.dart';

/// One-time import of the legacy SharedPreferences library into Drift.
///
/// Rows are inserted with insert-or-ignore in a single transaction, then the
/// flag [flagKey] is stored in `SyncMetadata` so the import never runs twice.
/// Entries that cannot be parsed are skipped and their prefs key is kept so
/// the raw data is never lost.
class PrefsToDriftMigration {
  static const String flagKey = 'migration.prefs_documents_v1';
  static const String _contentPrefix = 'document_content_';

  final AppDatabase _db;
  final SharedPreferences _prefs;

  PrefsToDriftMigration(this._db, this._prefs);

  Future<void> run() async {
    final flag = await (_db.select(_db.syncMetadata)
          ..where((t) => t.key.equals(flagKey)))
        .getSingleOrNull();
    if (flag != null) return;

    final removable = <String>[];
    await _db.transaction(() async {
      if (await _importList('documents', _importDocument)) {
        removable.add('documents');
      }
      if (await _importList('folders', _importFolder)) {
        removable.add('folders');
      }
      if (await _importList('trashed_pages', _importTrashedPage)) {
        removable.add('trashed_pages');
      }
      for (final key in _prefs.getKeys().toList()) {
        if (key.startsWith(_contentPrefix) && await _importContent(key)) {
          removable.add(key);
        }
      }
      await _db.into(_db.syncMetadata).insertOnConflictUpdate(
            SyncMetadataCompanion.insert(
              key: flagKey,
              value: DateTime.now().toIso8601String(),
            ),
          );
    });

    for (final key in removable) {
      await _prefs.remove(key);
    }
  }

  /// Imports a JSON list stored under [key]. Returns true when every entry
  /// was imported (or the key is absent), so the key may be removed.
  Future<bool> _importList(
    String key,
    Future<void> Function(Map<String, dynamic>) importOne,
  ) async {
    final raw = _prefs.getString(key);
    if (raw == null) return false;
    List<dynamic> list;
    try {
      list = json.decode(raw) as List<dynamic>;
    } catch (_) {
      return false;
    }
    var allOk = true;
    for (final entry in list) {
      try {
        await importOne(entry as Map<String, dynamic>);
      } catch (_) {
        allOk = false;
      }
    }
    return allOk;
  }

  Future<void> _importDocument(Map<String, dynamic> j) async {
    final d = DocumentModel.fromJson(j);
    await _db.into(_db.documents).insert(
          DocumentsCompanion(
            id: Value(d.id),
            title: Value(d.title),
            folderId: Value(d.folderId),
            templateId: Value(d.templateId),
            createdAt: Value(d.createdAt),
            updatedAt: Value(d.updatedAt),
            thumbnailPath: Value(d.thumbnailPath),
            pageCount: Value(d.pageCount),
            isFavorite: Value(d.isFavorite),
            isInTrash: Value(d.isInTrash),
            deletedAt: Value(d.deletedAt),
            syncState: Value(d.syncState),
            paperColor: Value(d.paperColor),
            isPortrait: Value(d.isPortrait),
            documentType: Value(d.documentType),
            coverId: Value(d.coverId),
            hasCover: Value(d.hasCover),
            paperWidthMm: Value(d.paperWidthMm),
            paperHeightMm: Value(d.paperHeightMm),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importFolder(Map<String, dynamic> j) async {
    final f = FolderModel.fromJson(j);
    await _db.into(_db.folders).insert(
          FoldersCompanion(
            id: Value(f.id),
            name: Value(f.name),
            parentId: Value(f.parentId),
            colorValue: Value(f.colorValue),
            sortOrder: Value(f.sortOrder),
            isFavorite: Value(f.isFavorite),
            createdAt: Value(f.createdAt),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _importTrashedPage(Map<String, dynamic> j) async {
    final p = TrashedPageModel.fromJson(j);
    await _db.into(_db.trashedPages).insert(
          TrashedPagesCompanion(
            id: Value(p.id),
            pageId: Value(p.pageId),
            sourceDocumentId: Value(p.sourceDocumentId),
            sourceDocumentTitle: Value(p.sourceDocumentTitle),
            originalPageIndex: Value(p.originalPageIndex),
            deletedAt: Value(p.deletedAt),
            pageData: Value(json.encode(p.pageData)),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<bool> _importContent(String key) async {
    final raw = _prefs.getString(key);
    if (raw == null) return false;
    try {
      json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return false;
    }
    await _db.into(_db.documentContents).insert(
          DocumentContentsCompanion(
            documentId: Value(key.substring(_contentPrefix.length)),
            data: Value(raw),
            updatedAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return true;
  }
}
