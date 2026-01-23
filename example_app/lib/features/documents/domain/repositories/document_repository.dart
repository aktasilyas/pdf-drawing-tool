import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';

abstract class DocumentRepository {
  /// Get all documents, optionally filtered by folder
  Future<Either<Failure, List<DocumentInfo>>> getDocuments({String? folderId});

  /// Get single document by ID
  Future<Either<Failure, DocumentInfo>> getDocument(String id);

  /// Create new document
  Future<Either<Failure, DocumentInfo>> createDocument({
    required String title,
    required String templateId,
    String? folderId,
  });

  /// Update document metadata
  Future<Either<Failure, DocumentInfo>> updateDocument({
    required String id,
    String? title,
    String? folderId,
    String? thumbnailPath,
    int? pageCount,
  });

  /// Delete document
  Future<Either<Failure, void>> deleteDocument(String id);

  /// Move document to folder
  Future<Either<Failure, void>> moveDocument(String id, String? folderId);

  /// Toggle favorite status
  Future<Either<Failure, void>> toggleFavorite(String id);

  /// Get favorite documents
  Future<Either<Failure, List<DocumentInfo>>> getFavorites();

  /// Get recently opened documents
  Future<Either<Failure, List<DocumentInfo>>> getRecent({int limit = 10});

  /// Search documents by title
  Future<Either<Failure, List<DocumentInfo>>> search(String query);

  /// Watch documents list (reactive)
  Stream<List<DocumentInfo>> watchDocuments({String? folderId});

  /// Get documents in trash
  Future<Either<Failure, List<DocumentInfo>>> getTrash();

  /// Move document to trash
  Future<Either<Failure, void>> moveToTrash(String id);

  /// Restore document from trash
  Future<Either<Failure, void>> restoreFromTrash(String id);

  /// Permanently delete document
  Future<Either<Failure, void>> permanentlyDelete(String id);

  /// Get document content (drawing data as JSON)
  Future<Either<Failure, Map<String, dynamic>?>> getDocumentContent(String id);

  /// Save document content (drawing data as JSON)
  Future<Either<Failure, void>> saveDocumentContent({
    required String id,
    required Map<String, dynamic> content,
    int? pageCount,
    DateTime? updatedAt,
  });
}
