import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/models/folder_model.dart';

abstract class FolderLocalDatasource {
  Future<List<FolderModel>> getFolders({String? parentId});
  Future<FolderModel> getFolder(String id);
  Future<FolderModel> createFolder(FolderModel folder);
  Future<FolderModel> updateFolder(FolderModel folder);
  Future<void> deleteFolder(String id);
  Stream<List<FolderModel>> watchFolders({String? parentId});
}

/// Drift-backed folder storage.
@Injectable(as: FolderLocalDatasource)
class FolderLocalDatasourceImpl implements FolderLocalDatasource {
  final AppDatabase _db;

  FolderLocalDatasourceImpl(this._db);

  SimpleSelectStatement<$FoldersTable, FolderRow> _query(String? parentId) {
    final q = _db.select(_db.folders);
    if (parentId != null) q.where((t) => t.parentId.equals(parentId));
    return q;
  }

  @override
  Future<List<FolderModel>> getFolders({String? parentId}) async {
    try {
      final rows = await _query(parentId).get();
      return rows.map(_toModel).toList();
    } catch (e) {
      throw CacheException('Failed to get folders: $e');
    }
  }

  @override
  Future<FolderModel> getFolder(String id) async {
    try {
      final row = await (_db.select(_db.folders)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row == null) throw const CacheException('Folder not found');
      return _toModel(row);
    } catch (e) {
      throw CacheException('Failed to get folder: $e');
    }
  }

  @override
  Future<FolderModel> createFolder(FolderModel folder) async {
    try {
      await _db.into(_db.folders).insert(_toCompanion(folder));
      return folder;
    } catch (e) {
      throw CacheException('Failed to create folder: $e');
    }
  }

  @override
  Future<FolderModel> updateFolder(FolderModel folder) async {
    try {
      final count = await (_db.update(_db.folders)
            ..where((t) => t.id.equals(folder.id)))
          .write(_toCompanion(folder));
      if (count == 0) throw const CacheException('Folder not found');
      return folder;
    } catch (e) {
      throw CacheException('Failed to update folder: $e');
    }
  }

  @override
  Future<void> deleteFolder(String id) async {
    try {
      await (_db.delete(_db.folders)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw CacheException('Failed to delete folder: $e');
    }
  }

  @override
  Stream<List<FolderModel>> watchFolders({String? parentId}) {
    return _query(parentId).watch().map((rows) => rows.map(_toModel).toList());
  }

  FolderModel _toModel(FolderRow r) => FolderModel(
        id: r.id,
        name: r.name,
        parentId: r.parentId,
        colorValue: r.colorValue,
        sortOrder: r.sortOrder,
        createdAt: r.createdAt,
        isFavorite: r.isFavorite,
      );

  FoldersCompanion _toCompanion(FolderModel f) => FoldersCompanion(
        id: Value(f.id),
        name: Value(f.name),
        parentId: Value(f.parentId),
        colorValue: Value(f.colorValue),
        sortOrder: Value(f.sortOrder),
        isFavorite: Value(f.isFavorite),
        createdAt: Value(f.createdAt),
      );
}
