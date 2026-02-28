import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/data/datasources/document_local_datasource.dart';
import 'package:example_app/features/documents/data/datasources/folder_local_datasource.dart';
import 'package:example_app/features/documents/data/models/document_model.dart';

@Injectable(as: DocumentRepository)
class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDatasource _localDatasource;
  final FolderLocalDatasource _folderDatasource;
  final Uuid _uuid;

  DocumentRepositoryImpl(
    this._localDatasource,
    this._folderDatasource, [
    Uuid? uuid,
  ]) : _uuid = uuid ?? const Uuid();

  @override
  Future<Either<Failure, List<DocumentInfo>>> getDocuments({
    String? folderId,
  }) async {
    try {
      final documents = await _localDatasource.getDocuments(folderId: folderId);
      final nonTrashDocs = documents
          .where((doc) => !doc.isInTrash)
          .map((model) => model.toEntity())
          .toList();
      
      // Return unsorted list - UI will handle sorting based on user preference
      return Right(nonTrashDocs);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get documents: $e'));
    }
  }

  @override
  Future<Either<Failure, DocumentInfo>> getDocument(String id) async {
    try {
      final document = await _localDatasource.getDocument(id);
      return Right(document.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get document: $e'));
    }
  }

  @override
  Future<Either<Failure, DocumentInfo>> createDocument({
    required String title,
    required String templateId,
    String? folderId,
    String paperColor = 'Sarı kağıt',
    bool isPortrait = true,
    DocumentType documentType = DocumentType.notebook,
    String? coverId,
    bool hasCover = true,
    double paperWidthMm = 210.0,
    double paperHeightMm = 297.0,
  }) async {
    try {
      final now = DateTime.now();
      final document = DocumentModel(
        id: _uuid.v4(),
        title: title,
        templateId: templateId,
        folderId: folderId,
        createdAt: now,
        updatedAt: now,
        pageCount: 1,
        isFavorite: false,
        isInTrash: false,
        syncState: SyncState.local.index,
        paperColor: paperColor,
        isPortrait: isPortrait,
        documentType: documentType.name,
        coverId: coverId,
        hasCover: hasCover,
        paperWidthMm: paperWidthMm,
        paperHeightMm: paperHeightMm,
      );

      final created = await _localDatasource.createDocument(document);
      return Right(created.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to create document: $e'));
    }
  }

  @override
  Future<Either<Failure, DocumentInfo>> updateDocument({
    required String id,
    String? title,
    String? folderId,
    String? thumbnailPath,
    int? pageCount,
  }) async {
    try {
      final document = await _localDatasource.getDocument(id);
      
      // Manually create updated document to handle null folderId correctly
      final updated = DocumentModel(
        id: document.id,
        title: title ?? document.title,
        folderId: folderId, // Explicitly use the passed folderId (can be null)
        templateId: document.templateId,
        createdAt: document.createdAt,
        updatedAt: DateTime.now(),
        thumbnailPath: thumbnailPath ?? document.thumbnailPath,
        pageCount: pageCount ?? document.pageCount,
        isFavorite: document.isFavorite,
        isInTrash: document.isInTrash,
        syncState: document.syncState,
        paperColor: document.paperColor,
        isPortrait: document.isPortrait,
        documentType: document.documentType,
        coverId: document.coverId,
        hasCover: document.hasCover,
        paperWidthMm: document.paperWidthMm,
        paperHeightMm: document.paperHeightMm,
      );

      final result = await _localDatasource.updateDocument(updated);
      return Right(result.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to update document: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDocument(String id) async {
    try {
      await _localDatasource.deleteDocument(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to delete document: $e'));
    }
  }

  @override
  Future<Either<Failure, DocumentInfo>> duplicateDocument(String id) async {
    try {
      // Get the original document
      final original = await _localDatasource.getDocument(id);
      
      // Create a copy with new ID and updated timestamps
      final now = DateTime.now();
      final duplicate = original.copyWith(
        id: _uuid.v4(),
        title: '${original.title} (kopya)',
        createdAt: now,
        updatedAt: now,
        isFavorite: false, // Don't copy favorite status
      );

      // Save the duplicate
      final created = await _localDatasource.createDocument(duplicate);
      
      // Copy document content if exists
      try {
        final content = await _localDatasource.getDocumentContent(id);
        if (content != null) {
          await _localDatasource.saveDocumentContent(created.id, content);
        }
      } catch (e) {
        // Content copy failed, but document is created
        debugPrint('Failed to copy document content: $e');
      }

      return Right(created.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to duplicate document: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> moveDocument(String id, String? folderId) async {
    try {
      final document = await _localDatasource.getDocument(id);
      final updated = document.copyWith(
        folderId: folderId,
        updatedAt: DateTime.now(),
      );
      await _localDatasource.updateDocument(updated);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to move document: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavorite(String id) async {
    try {
      final document = await _localDatasource.getDocument(id);
      final updated = document.copyWith(
        isFavorite: !document.isFavorite,
        updatedAt: DateTime.now(),
      );
      await _localDatasource.updateDocument(updated);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to toggle favorite: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DocumentInfo>>> getFavorites() async {
    try {
      final documents = await _localDatasource.getAllDocuments();
      final favorites = documents
          .where((doc) => doc.isFavorite && !doc.isInTrash)
          .map((model) => model.toEntity())
          .toList();
      
      // Sort by updated date (most recent first)
      favorites.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return Right(favorites);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get favorites: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DocumentInfo>>> getRecent({int limit = 10}) async {
    try {
      final documents = await _localDatasource.getAllDocuments();
      final recent = documents
          .where((doc) => !doc.isInTrash)
          .map((model) => model.toEntity())
          .toList();
      
      // Sort by updated date (most recent first)
      recent.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return Right(recent.take(limit).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get recent documents: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DocumentInfo>>> search(String query) async {
    try {
      final documents = await _localDatasource.getAllDocuments();
      final lowerQuery = query.toLowerCase();
      final results = documents
          .where((doc) =>
              !doc.isInTrash &&
              doc.title.toLowerCase().contains(lowerQuery))
          .map((model) => model.toEntity())
          .toList();
      
      // Sort by relevance (exact match first, then by updated date)
      results.sort((a, b) {
        final aExact = a.title.toLowerCase() == lowerQuery;
        final bExact = b.title.toLowerCase() == lowerQuery;
        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      
      return Right(results);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to search documents: $e'));
    }
  }

  @override
  Stream<List<DocumentInfo>> watchDocuments({String? folderId}) {
    return _localDatasource
        .watchDocuments(folderId: folderId)
        .map((documents) {
      final nonTrashDocs = documents
          .where((doc) => !doc.isInTrash)
          .map((model) => model.toEntity())
          .toList();
      
      // Sort by updated date (most recent first)
      nonTrashDocs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return nonTrashDocs;
    });
  }

  @override
  Future<Either<Failure, List<DocumentInfo>>> getTrash() async {
    try {
      // Get ALL documents (not filtered by folderId)
      final documents = await _localDatasource.getAllDocuments();
      final trash = documents
          .where((doc) => doc.isInTrash)
          .map((model) => model.toEntity())
          .toList();
      
      // Sort by updated date (most recent first)
      trash.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return Right(trash);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get trash: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> moveToTrash(String id) async {
    try {
      final document = await _localDatasource.getDocument(id);
      final updated = document.copyWith(
        isInTrash: true,
        updatedAt: DateTime.now(),
      );
      await _localDatasource.updateDocument(updated);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to move to trash: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> restoreFromTrash(String id) async {
    try {
      final document = await _localDatasource.getDocument(id);

      // Check if the original folder still exists
      String? restoredFolderId = document.folderId;
      if (restoredFolderId != null) {
        try {
          await _folderDatasource.getFolder(restoredFolderId);
        } on CacheException {
          // Folder no longer exists — move document to root
          restoredFolderId = null;
        }
      }

      final updated = DocumentModel(
        id: document.id,
        title: document.title,
        folderId: restoredFolderId,
        templateId: document.templateId,
        createdAt: document.createdAt,
        updatedAt: DateTime.now(),
        thumbnailPath: document.thumbnailPath,
        pageCount: document.pageCount,
        isFavorite: document.isFavorite,
        isInTrash: false,
        syncState: document.syncState,
        paperColor: document.paperColor,
        isPortrait: document.isPortrait,
        documentType: document.documentType,
        coverId: document.coverId,
        hasCover: document.hasCover,
        paperWidthMm: document.paperWidthMm,
        paperHeightMm: document.paperHeightMm,
      );
      await _localDatasource.updateDocument(updated);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to restore from trash: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> permanentlyDelete(String id) async {
    try {
      await _localDatasource.deleteDocument(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to permanently delete: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getDocumentContent(String id) async {
    try {
      final content = await _localDatasource.getDocumentContent(id);
      return Right(content);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get document content: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveDocumentContent({
    required String id,
    required Map<String, dynamic> content,
    int? pageCount,
    DateTime? updatedAt,
    String? coverId,
    bool updateCover = false,
  }) async {
    try {
      // Save content
      await _localDatasource.saveDocumentContent(id, content);

      // Update metadata if provided
      if (pageCount != null || updatedAt != null || updateCover) {
        final document = await _localDatasource.getDocument(id);
        // Build updated model manually to allow setting coverId to null
        final updated = DocumentModel(
          id: document.id,
          title: document.title,
          folderId: document.folderId,
          templateId: document.templateId,
          createdAt: document.createdAt,
          updatedAt: updatedAt ?? DateTime.now(),
          thumbnailPath: document.thumbnailPath,
          pageCount: pageCount ?? document.pageCount,
          isFavorite: document.isFavorite,
          isInTrash: document.isInTrash,
          syncState: document.syncState,
          paperColor: document.paperColor,
          isPortrait: document.isPortrait,
          documentType: document.documentType,
          coverId: updateCover ? coverId : document.coverId,
          hasCover: updateCover ? (coverId != null) : document.hasCover,
          paperWidthMm: document.paperWidthMm,
          paperHeightMm: document.paperHeightMm,
        );
        await _localDatasource.updateDocument(updated);
      }

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to save document content: $e'));
    }
  }
}
