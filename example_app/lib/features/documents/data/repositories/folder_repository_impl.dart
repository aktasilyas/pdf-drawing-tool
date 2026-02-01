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
      final folders = await _localDatasource.getFolders(parentId: parentId);
      final documents = await _documentDatasource.getAllDocuments(); // Get ALL documents
      
      // Calculate document count for each folder
      final entities = folders.map((model) {
        final docCount = documents.where((doc) => doc.folderId == model.id && !doc.isInTrash).length;
        return model.copyWith(documentCount: docCount).toEntity();
      }).toList();
      
      // Sort by name
      entities.sort((a, b) => a.name.compareTo(b.name));
      
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
  }) async {
    try {
      final folder = await _localDatasource.getFolder(id);
      final updated = folder.copyWith(
        name: name,
        colorValue: colorValue,
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
  Future<Either<Failure, void>> deleteFolder(
    String id, {
    bool deleteContents = false,
  }) async {
    try {
      // TODO: If deleteContents is false, check if folder has documents
      // and return error if it does. This will be implemented when
      // we have proper folder-document relationship tracking.
      
      await _localDatasource.deleteFolder(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to delete folder: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> moveFolder(
    String id,
    String? newParentId,
  ) async {
    try {
      final folder = await _localDatasource.getFolder(id);
      
      // Check for circular reference
      if (newParentId != null) {
        final isCircular = await _checkCircularReference(id, newParentId);
        if (isCircular) {
          return const Left(
            ValidationFailure('Klasör kendi alt klasörüne taşınamaz'),
          );
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
      
      // Sort by name
      entities.sort((a, b) => a.name.compareTo(b.name));
      
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
