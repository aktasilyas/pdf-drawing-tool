import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/data/datasources/document_local_datasource.dart';
import 'package:example_app/features/documents/data/models/document_model.dart';

@Injectable(as: DocumentRepository)
class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDatasource _localDatasource;
  final Uuid _uuid;

  DocumentRepositoryImpl(
    this._localDatasource, [
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
      
      // Sort by updated date (most recent first)
      nonTrashDocs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
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
      final updated = document.copyWith(
        title: title,
        folderId: folderId,
        thumbnailPath: thumbnailPath,
        pageCount: pageCount,
        updatedAt: DateTime.now(),
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
      final documents = await _localDatasource.getDocuments();
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
      final documents = await _localDatasource.getDocuments();
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
      final documents = await _localDatasource.getDocuments();
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
      final documents = await _localDatasource.getDocuments();
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
      final updated = document.copyWith(
        isInTrash: false,
        updatedAt: DateTime.now(),
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
  }) async {
    try {
      // Save content
      await _localDatasource.saveDocumentContent(id, content);
      
      // Update metadata if provided
      if (pageCount != null || updatedAt != null) {
        final document = await _localDatasource.getDocument(id);
        final updated = document.copyWith(
          pageCount: pageCount,
          updatedAt: updatedAt ?? DateTime.now(),
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
