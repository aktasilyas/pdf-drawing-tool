import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';

abstract class FolderRepository {
  /// Get all folders, optionally filtered by parent
  Future<Either<Failure, List<Folder>>> getFolders({String? parentId});

  /// Get folder by ID
  Future<Either<Failure, Folder>> getFolder(String id);

  /// Create new folder
  Future<Either<Failure, Folder>> createFolder({
    required String name,
    String? parentId,
    int? colorValue,
  });

  /// Update folder
  Future<Either<Failure, Folder>> updateFolder({
    required String id,
    String? name,
    int? colorValue,
    int? sortOrder,
  });

  /// Delete folder (and optionally contents)
  Future<Either<Failure, void>> deleteFolder(
    String id, {
    bool deleteContents = false,
  });

  /// Move folder to new parent
  Future<Either<Failure, void>> moveFolder(String id, String? newParentId);

  /// Watch folders list (reactive)
  Stream<List<Folder>> watchFolders({String? parentId});

  /// Get folder path (breadcrumb)
  Future<Either<Failure, List<Folder>>> getFolderPath(String folderId);
}
