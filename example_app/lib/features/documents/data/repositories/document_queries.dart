import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/data/datasources/document_local_datasource.dart';
import 'package:example_app/features/documents/data/models/document_model.dart';

/// Read-only queries of [DocumentRepositoryImpl].
mixin DocumentQueries {
  DocumentLocalDatasource get localDatasource;

  Future<Either<Failure, List<DocumentInfo>>> getDocuments({
    String? folderId,
  }) async {
    try {
      final documents = await localDatasource.getDocuments(folderId: folderId);
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

  Future<Either<Failure, int>> getDocumentCount({
    DocumentType? documentType,
    bool includeTrash = false,
  }) async {
    try {
      final documents = await localDatasource.getAllDocuments();
      Iterable<DocumentModel> filtered = documents;
      if (!includeTrash) {
        filtered = filtered.where((doc) => !doc.isInTrash);
      }
      if (documentType != null) {
        filtered =
            filtered.where((doc) => doc.documentType == documentType.name);
      }
      return Right(filtered.length);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get document count: $e'));
    }
  }

  Future<Either<Failure, DocumentInfo>> getDocument(String id) async {
    try {
      final document = await localDatasource.getDocument(id);
      return Right(document.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get document: $e'));
    }
  }

  Future<Either<Failure, List<DocumentInfo>>> getFavorites() async {
    try {
      final documents = await localDatasource.getAllDocuments();
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

  Future<Either<Failure, List<DocumentInfo>>> getRecent(
      {int limit = 10}) async {
    try {
      final documents = await localDatasource.getAllDocuments();
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

  Future<Either<Failure, List<DocumentInfo>>> search(String query) async {
    try {
      final documents = await localDatasource.getAllDocuments();
      final lowerQuery = query.toLowerCase();
      final results = documents
          .where((doc) =>
              !doc.isInTrash && doc.title.toLowerCase().contains(lowerQuery))
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

  Stream<List<DocumentInfo>> watchDocuments({String? folderId}) {
    return localDatasource.watchDocuments(folderId: folderId).map((documents) {
      final nonTrashDocs = documents
          .where((doc) => !doc.isInTrash)
          .map((model) => model.toEntity())
          .toList();

      // Sort by updated date (most recent first)
      nonTrashDocs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return nonTrashDocs;
    });
  }

  Future<Either<Failure, List<DocumentInfo>>> getTrash() async {
    try {
      // Get ALL documents (not filtered by folderId)
      final documents = await localDatasource.getAllDocuments();
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
}
