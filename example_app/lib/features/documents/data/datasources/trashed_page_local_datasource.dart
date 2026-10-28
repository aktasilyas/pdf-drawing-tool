import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/features/documents/data/models/trashed_page_model.dart';

abstract class TrashedPageLocalDatasource {
  /// Readable rows only; rows whose page data cannot be decoded are skipped.
  Future<List<TrashedPageModel>> getTrashedPages();

  /// Id and deletion time of rows whose page data cannot be decoded.
  Future<List<({String id, DateTime deletedAt})>> getUnreadableTrashedPages();

  /// Null when the row is missing or unreadable.
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
      return [
        for (final r in rows)
          if (_tryToModel(r) case final model?) model,
      ];
    } catch (e) {
      throw CacheException('Failed to get trashed pages: $e');
    }
  }

  @override
  Future<List<({String id, DateTime deletedAt})>>
      getUnreadableTrashedPages() async {
    try {
      final rows = await _db.select(_db.trashedPages).get();
      return [
        for (final r in rows)
          if (_tryToModel(r) == null) (id: r.id, deletedAt: r.deletedAt),
      ];
    } catch (e) {
      throw CacheException('Failed to get unreadable trashed pages: $e');
    }
  }

  @override
  Future<TrashedPageModel?> getTrashedPage(String id) async {
    try {
      final row = await (_db.select(_db.trashedPages)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      return row == null ? null : _tryToModel(row);
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

  TrashedPageModel? _tryToModel(TrashedPage r) {
    try {
      return _toModel(r);
    } catch (e) {
      logger.w('Skipping unreadable trashed page ${r.id}: $e');
      return null;
    }
  }

  TrashedPageModel _toModel(TrashedPage r) => TrashedPageModel(
        id: r.id,
        pageId: r.pageId,
        sourceDocumentId: r.sourceDocumentId,
        sourceDocumentTitle: r.sourceDocumentTitle,
        originalPageIndex: r.originalPageIndex,
        deletedAt: r.deletedAt,
        pageData: json.decode(r.pageData) as Map<String, dynamic>,
      );
}
