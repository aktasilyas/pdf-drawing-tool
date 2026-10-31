import 'dart:typed_data';

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

  /// Creates a document and stores its first content in one transaction, so
  /// a failed write or the app closing mid-import never leaves a row without
  /// content (a blank "ghost" notebook, #602). [buildContent] receives the new
  /// document (id, dates) and returns the content to store for it.
  Future<Either<Failure, DocumentInfo>> createDocumentWithContent({
    required String title,
    required String templateId,
    String? folderId,
    String paperColor = 'Sarı kağıt',
    bool isPortrait = true,
    DocumentType documentType = DocumentType.notebook,
    double paperWidthMm = 210.0,
    double paperHeightMm = 297.0,
    required int pageCount,
    required Map<String, dynamic> Function(DocumentInfo document) buildContent,
  });

  /// Update document metadata
  Future<Either<Failure, DocumentInfo>> updateDocument({
    required String id,
    String? title,
    String? folderId,
    String? thumbnailPath,
    int? pageCount,
  });

  /// Sets the cover of [id] (hasCover = true) and bumps updatedAt; stored
  /// content is untouched.
  Future<Either<Failure, void>> updateCover(String id, String coverId);

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

  /// Stores [png] as the library thumbnail of [id] and returns the stored
  /// relative path. Does not change the edited date or the folder.
  Future<Either<Failure, String>> saveThumbnail(String id, Uint8List png);

  /// Permanently deletes every document in the trash; returns how many.
  Future<Either<Failure, int>> emptyTrash();

  /// Permanently deletes documents trashed before `now - retention`.
  /// Legacy trashed documents without a deletion time get `now` stamped
  /// instead (they start their retention period). Returns the purge count.
  Future<Either<Failure, int>> purgeExpiredTrash({
    required DateTime now,
    Duration retention = trashRetention,
  });

  /// Deletes app-managed files (copied PDFs, images) that no notebook, trashed
  /// page, thumbnail or chat message references and that last changed before
  /// [olderThan]. Returns how many files were deleted.
  Future<Either<Failure, int>> sweepOrphanedFiles({
    required DateTime olderThan,
  });

  /// Get document content (drawing data as JSON)
  Future<Either<Failure, Map<String, dynamic>?>> getDocumentContent(String id);

  /// Document content as a model; null when nothing is stored yet. Large
  /// documents are parsed off the UI isolate.
  Future<Either<Failure, DrawingDocument?>> getDrawingDocument(String id);

  /// Background of the first page of [id] (for library thumbnails), or null
  /// when nothing is stored yet. Cheaper than [getDrawingDocument]: page and
  /// stroke models are not built.
  Future<Either<Failure, PageBackground?>> getFirstPageBackground(String id);

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
