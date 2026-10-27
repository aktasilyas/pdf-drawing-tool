import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';

/// How long trashed items are kept before they are purged.
const Duration trashRetention = Duration(days: 30);

abstract class DocumentRepository {
  /// Get all documents, optionally filtered by folder
  Future<Either<Failure, List<DocumentInfo>>> getDocuments({String? folderId});

  /// Get total document count (across all folders).
  /// By default excludes trash; set [includeTrash] to count all documents.
  /// Optionally filter by [documentType].
  Future<Either<Failure, int>> getDocumentCount({
    DocumentType? documentType,
    bool includeTrash = false,
  });

  /// Get single document by ID
  Future<Either<Failure, DocumentInfo>> getDocument(String id);

  /// Create new document
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

  /// Duplicate document (create a copy).
  ///
  /// [copyTitle] builds the title of the copy from the original title; the
  /// presentation layer supplies the localized "(copy)" suffix.
  Future<Either<Failure, DocumentInfo>> duplicateDocument(
    String id, {
    required String Function(String title) copyTitle,
  });

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

  /// Permanently deletes every document in the trash; returns how many.
  Future<Either<Failure, int>> emptyTrash();

  /// Permanently deletes documents trashed before `now - retention`.
  /// Legacy trashed documents without a deletion time get `now` stamped
  /// instead (they start their retention period). Returns the purge count.
  Future<Either<Failure, int>> purgeExpiredTrash({
    required DateTime now,
    Duration retention = trashRetention,
  });

  /// Get document content (drawing data as JSON)
  Future<Either<Failure, Map<String, dynamic>?>> getDocumentContent(String id);

  /// Document content as a model; null when nothing is stored yet. Large
  /// documents are parsed off the UI isolate.
  Future<Either<Failure, DrawingDocument?>> getDrawingDocument(String id);

  /// Save document content (drawing data as JSON)
  Future<Either<Failure, void>> saveDocumentContent({
    required String id,
    required Map<String, dynamic> content,
    int? pageCount,
    DateTime? updatedAt,
    String? coverId,
    bool updateCover = false,
    String? title,
  });
}
