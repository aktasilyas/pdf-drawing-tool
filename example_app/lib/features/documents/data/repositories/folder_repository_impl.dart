import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/domain/repositories/folder_repository.dart';
import 'package:example_app/features/documents/data/datasources/folder_local_datasource.dart';
import 'package:example_app/features/documents/data/datasources/document_local_datasource.dart';
import 'package:example_app/features/documents/data/models/folder_model.dart';

@Injectable(as: FolderRepository)
class FolderRepositoryImpl implements FolderRepository {
  final FolderLocalDatasource _localDatasource;
  final DocumentLocalDatasource _documentDatasource;
  final Uuid _uuid;

  FolderRepositoryImpl(
    this._localDatasource,
    this._documentDatasource, [
    Uuid? uuid,
  ]) : _uuid = uuid ?? const Uuid();

  @override
  Future<Either<Failure, List<Folder>>> getFolders({String? parentId}) async {
    try {
      // Always fetch all folders to compute recursive document counts
      final allFolders = await _localDatasource.getFolders();
      final documents = await _documentDatasource.getAllDocuments();
      final nonTrashedDocs = documents.where((doc) => !doc.isInTrash).toList();

      // Filter to requested scope
      final targetFolders = parentId == null
          ? allFolders
          : allFolders.where((f) => f.parentId == parentId).toList();

      // Calculate recursive document count (includes subfolder documents)
      final entities = targetFolders.map((model) {
        final folderIds = {model.id, ..._getDescendantIds(model.id, allFolders)};
        final docCount =
            nonTrashedDocs.where((doc) => folderIds.contains(doc.folderId)).length;
        return model.copyWith(documentCount: docCount).toEntity();
      }).toList();

      // Sort by sortOrder first, then by name
      entities.sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (orderCompare != 0) return orderCompare;
        return a.name.compareTo(b.name);
      });

      return Right(entities);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get folders: $e'));
    }
  }

  @override
  Future<Either<Failure, Folder>> getFolder(String id) async {
    try {
      final folder = await _localDatasource.getFolder(id);
      return Right(folder.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get folder: $e'));
    }
  }

  @override
  Future<Either<Failure, Folder>> createFolder({
    required String name,
    String? parentId,
    int? colorValue,
  }) async {
    try {
      // 2 seviye max kuralı: Parent klasör zaten alt klasörse engelle
      if (parentId != null) {
        final parentFolder = await _localDatasource.getFolder(parentId);
        if (parentFolder.parentId != null) {
          // Parent zaten bir alt klasör - 3. seviye yasak
          return const Left(
            ValidationFailure('Alt klasörlerin altına klasör oluşturulamaz'),
          );
        }
      }

      final folder = FolderModel(
        id: _uuid.v4(),
        name: name,
        parentId: parentId,
        colorValue: colorValue ?? 0xFF2196F3,
        createdAt: DateTime.now(),
        documentCount: 0,
      );

      final created = await _localDatasource.createFolder(folder);
      return Right(created.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to create folder: $e'));
    }
  }

  @override
  Future<Either<Failure, Folder>> updateFolder({
    required String id,
    String? name,
    int? colorValue,
    int? sortOrder,
  }) async {
    try {
      final folder = await _localDatasource.getFolder(id);
      final updated = folder.copyWith(
        name: name,
        colorValue: colorValue,
        sortOrder: sortOrder,
      );

      final result = await _localDatasource.updateFolder(updated);
      return Right(result.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to update folder: $e'));
    }
  }

  @override
  Future<Either<Failure, Folder>> toggleFavorite(String id) async {
    try {
      final folder = await _localDatasource.getFolder(id);
      final updated = folder.copyWith(isFavorite: !folder.isFavorite);
      final result = await _localDatasource.updateFolder(updated);
      return Right(result.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to toggle favorite: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFolder(
    String id, {
    bool deleteContents = false,
  }) async {
    try {
      // Move all documents in this folder to trash
      await _moveDocumentsToTrash(id);

      // Recursively handle subfolders
      final subfolders = await _localDatasource.getFolders(parentId: id);
      for (final subfolder in subfolders) {
        await _moveDocumentsToTrash(subfolder.id);
        await _localDatasource.deleteFolder(subfolder.id);
      }

      // Delete the folder itself
      await _localDatasource.deleteFolder(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to delete folder: $e'));
    }
  }

  /// Moves all non-trashed documents in a folder to trash.
  Future<void> _moveDocumentsToTrash(String folderId) async {
    final allDocs = await _documentDatasource.getAllDocuments();
    final folderDocs = allDocs.where(
      (doc) => doc.folderId == folderId && !doc.isInTrash,
    );
    for (final doc in folderDocs) {
      final updated = doc.copyWith(
        isInTrash: true,
        deletedAt: DateTime.now(),
      );
      await _documentDatasource.updateDocument(updated);
    }
  }

  @override
  Future<Either<Failure, void>> moveFolder(
    String id,
    String? newParentId,
  ) async {
    try {
      final folder = await _localDatasource.getFolder(id);

      if (newParentId != null) {
        // Check for circular reference
        final isCircular = await _checkCircularReference(id, newParentId);
        if (isCircular) {
          return const Left(
            ValidationFailure('Klasör kendi alt klasörüne taşınamaz'),
          );
        }

        // 2 seviye max kuralı: Hedef klasör zaten alt klasörse engelle
        final targetFolder = await _localDatasource.getFolder(newParentId);
        if (targetFolder.parentId != null) {
          return const Left(
            ValidationFailure('Alt klasörlerin altına klasör taşınamaz'),
          );
        }

        // Taşınan klasörün alt klasörleri varsa ve hedef root değilse engelle
        if (folder.parentId == null) {
          // Root klasör taşınıyor - alt klasörleri var mı kontrol et
          final subfolders = await _localDatasource.getFolders(parentId: id);
          if (subfolders.isNotEmpty) {
            return const Left(
              ValidationFailure(
                'Alt klasörleri olan bir klasör başka klasörün altına taşınamaz',
              ),
            );
          }
        }
      }

      final updated = folder.copyWith(parentId: newParentId);
      await _localDatasource.updateFolder(updated);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to move folder: $e'));
    }
  }

  @override
  Stream<List<Folder>> watchFolders({String? parentId}) {
    return _localDatasource.watchFolders(parentId: parentId).map((folders) {
      final entities = folders.map((model) => model.toEntity()).toList();

      // Sort by sortOrder first, then by name
      entities.sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (orderCompare != 0) return orderCompare;
        return a.name.compareTo(b.name);
      });

      return entities;
    });
  }

  @override
  Future<Either<Failure, List<Folder>>> getFolderPath(String folderId) async {
    try {
      final path = <FolderModel>[];
      String? currentId = folderId;

      while (currentId != null) {
        final folder = await _localDatasource.getFolder(currentId);
        path.insert(0, folder);
        currentId = folder.parentId;
      }

      return Right(path.map((model) => model.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get folder path: $e'));
    }
  }

  /// Returns all descendant folder IDs for recursive document counting.
  Set<String> _getDescendantIds(String folderId, List<FolderModel> allFolders) {
    final descendants = <String>{};
    final children = allFolders.where((f) => f.parentId == folderId);
    for (final child in children) {
      descendants.add(child.id);
      descendants.addAll(_getDescendantIds(child.id, allFolders));
    }
    return descendants;
  }

  Future<bool> _checkCircularReference(
    String folderId,
    String newParentId,
  ) async {
    try {
      String? currentId = newParentId;

      while (currentId != null) {
        if (currentId == folderId) {
          return true;
        }
        final folder = await _localDatasource.getFolder(currentId);
        currentId = folder.parentId;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
