import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/models/trashed_page_model.dart';

abstract class TrashedPageLocalDatasource {
  Future<List<TrashedPageModel>> getTrashedPages();
  Future<TrashedPageModel?> getTrashedPage(String id);
  Future<void> addTrashedPage(TrashedPageModel page);
  Future<void> removeTrashedPage(String id);
}

/// Drift-backed trashed page storage.
class TrashedPageLocalDatasourceImpl implements TrashedPageLocalDatasource {
  final AppDatabase _db;

  TrashedPageLocalDatasourceImpl(this._db);

  @override
  Future<List<TrashedPageModel>> getTrashedPages() async {
    try {
      final rows = await _db.select(_db.trashedPages).get();
      return rows.map(_toModel).toList();
    } catch (e) {
      throw CacheException('Failed to get trashed pages: $e');
    }
  }

  @override
  Future<TrashedPageModel?> getTrashedPage(String id) async {
    try {
      final row = await (_db.select(_db.trashedPages)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      return row == null ? null : _toModel(row);
    } catch (e) {
      throw CacheException('Failed to get trashed page: $e');
    }
  }

  @override
  Future<void> addTrashedPage(TrashedPageModel page) async {
    try {
      await _db.into(_db.trashedPages).insertOnConflictUpdate(
            TrashedPagesCompanion(
              id: Value(page.id),
              pageId: Value(page.pageId),
              sourceDocumentId: Value(page.sourceDocumentId),
              sourceDocumentTitle: Value(page.sourceDocumentTitle),
              originalPageIndex: Value(page.originalPageIndex),
              deletedAt: Value(page.deletedAt),
              pageData: Value(json.encode(page.pageData)),
            ),
          );
    } catch (e) {
      throw CacheException('Failed to add trashed page: $e');
    }
  }

  @override
  Future<void> removeTrashedPage(String id) async {
    try {
      await (_db.delete(_db.trashedPages)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw CacheException('Failed to remove trashed page: $e');
    }
  }

  TrashedPageModel _toModel(TrashedPagesData r) => TrashedPageModel(
        id: r.id,
        pageId: r.pageId,
        sourceDocumentId: r.sourceDocumentId,
        sourceDocumentTitle: r.sourceDocumentTitle,
        originalPageIndex: r.originalPageIndex,
        deletedAt: r.deletedAt,
        pageData: json.decode(r.pageData) as Map<String, dynamic>,
      );
}
