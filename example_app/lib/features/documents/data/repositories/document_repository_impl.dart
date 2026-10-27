import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/data/datasources/document_local_datasource.dart';
import 'package:example_app/features/documents/data/datasources/folder_local_datasource.dart';
import 'package:example_app/features/documents/data/models/document_model.dart';
import 'package:example_app/features/documents/data/repositories/document_queries.dart';

@Injectable(as: DocumentRepository)
class DocumentRepositoryImpl
    with DocumentQueries
    implements DocumentRepository {
  final DocumentLocalDatasource _localDatasource;
  final FolderLocalDatasource _folderDatasource;
  final LocalTransactionRunner _runner;
  final Uuid _uuid;

  DocumentRepositoryImpl(
    this._localDatasource,
    this._folderDatasource,
    this._runner, [
    Uuid? uuid,
  ]) : _uuid = uuid ?? const Uuid();

  @override
  DocumentLocalDatasource get localDatasource => _localDatasource;

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

  /// Runs [action] in one transaction and maps errors to a [Failure].
  Future<Either<Failure, T>> _guard<T>(
    String what,
    Future<T> Function() action,
  ) async {
    try {
      return Right(await _runner.run(action));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to $what: $e'));
    }
  }

  /// Loads a document, applies [change] and stores the result.
  Future<Either<Failure, DocumentModel>> _modify(
    String id,
    String what,
    DocumentModel Function(DocumentModel doc) change,
  ) {
    return _guard(what, () async {
      final document = await _localDatasource.getDocument(id);
      return _localDatasource.updateDocument(change(document));
    });
  }

  @override
  Future<Either<Failure, DocumentInfo>> updateDocument({
    required String id,
    String? title,
    String? folderId,
    String? thumbnailPath,
    int? pageCount,
  }) async {
    // The passed folderId is used as is, so null moves to the root.
    final result = await _modify(
      id,
      'update document',
      (doc) => doc
          .copyWith(
            title: title,
            thumbnailPath: thumbnailPath,
            pageCount: pageCount,
            updatedAt: DateTime.now(),
          )
          .withFolderId(folderId),
    );
    return result.map((m) => m.toEntity());
  }

  @override
  Future<Either<Failure, void>> deleteDocument(String id) =>
      _guard('delete document', () => _localDatasource.deleteDocument(id));

  @override
  Future<Either<Failure, void>> permanentlyDelete(String id) =>
      _guard('permanently delete', () => _localDatasource.deleteDocument(id));

  @override
  Future<Either<Failure, DocumentInfo>> duplicateDocument(
    String id, {
    required String Function(String title) copyTitle,
  }) async {
    // Document row and content are copied in one transaction.
    final result = await _guard('duplicate document', () async {
      final original = await _localDatasource.getDocument(id);
      final now = DateTime.now();
      final duplicate = original.copyWith(
        id: _uuid.v4(),
        title: copyTitle(original.title),
        createdAt: now,
        updatedAt: now,
        isFavorite: false, // Don't copy favorite status
      );
      final created = await _localDatasource.createDocument(duplicate);
      final content = await _localDatasource.getDocumentContent(id);
      if (content != null) {
        await _localDatasource.saveDocumentContent(created.id, content);
      }
      return created;
    });
    return result.map((m) => m.toEntity());
  }

  @override
  Future<Either<Failure, void>> moveDocument(
      String id, String? folderId) async {
    final result = await _modify(
      id,
      'move document',
      (doc) => doc.copyWith(updatedAt: DateTime.now()).withFolderId(folderId),
    );
    return result.map((_) {});
  }

  @override
  Future<Either<Failure, void>> toggleFavorite(String id) async {
    final result = await _modify(
      id,
      'toggle favorite',
      (doc) => doc.copyWith(
        isFavorite: !doc.isFavorite,
        updatedAt: DateTime.now(),
      ),
    );
    return result.map((_) {});
  }

  @override
  Future<Either<Failure, void>> moveToTrash(String id) async {
    final result = await _modify(
      id,
      'move to trash',
      (doc) => _trashed(doc, DateTime.now()),
    );
    return result.map((_) {});
  }

  DocumentModel _trashed(DocumentModel doc, DateTime now) =>
      doc.copyWith(isInTrash: true, deletedAt: now, updatedAt: now);

  @override
  Future<Either<Failure, int>> emptyTrash() {
    return _guard('empty trash', () async {
      final trashed =
          (await _localDatasource.getAllDocuments()).where((d) => d.isInTrash);
      var count = 0;
      for (final doc in trashed) {
        await _localDatasource.deleteDocument(doc.id);
        count++;
      }
      return count;
    });
  }

  @override
  Future<Either<Failure, int>> purgeExpiredTrash({
    required DateTime now,
    Duration retention = trashRetention,
  }) {
    final cutoff = now.subtract(retention);
    return _guard('purge expired trash', () async {
      var purged = 0;
      final trashed =
          (await _localDatasource.getAllDocuments()).where((d) => d.isInTrash);
      for (final doc in trashed) {
        final deletedAt = doc.deletedAt;
        if (deletedAt == null) {
          // Legacy row: start its retention period now, never purge at once.
          await _localDatasource.updateDocument(doc.copyWith(deletedAt: now));
        } else if (deletedAt.isBefore(cutoff)) {
          await _localDatasource.deleteDocument(doc.id);
          purged++;
        }
      }
      return purged;
    });
  }

  @override
  Future<Either<Failure, void>> restoreFromTrash(String id) {
    return _guard('restore from trash', () async {
      final document = await _localDatasource.getDocument(id);

      // Check if the original folder still exists
      String? restoredFolderId = document.folderId;
      if (restoredFolderId != null) {
        try {
          await _folderDatasource.getFolder(restoredFolderId);
        } on CacheException {
          // Folder no longer exists - move document to root
          restoredFolderId = null;
        }
      }

      await _localDatasource.updateDocument(
        document.restored(restoredFolderId, DateTime.now()),
      );
    });
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getDocumentContent(
    String id,
  ) async {
    try {
      return Right(await _localDatasource.getDocumentContent(id));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get document content: $e'));
    }
  }

  @override
  Future<Either<Failure, DrawingDocument?>> getDrawingDocument(
    String id,
  ) async {
    try {
      return Right(await _localDatasource.getDrawingDocument(id));
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
    String? title,
  }) {
    // Content and metadata are written atomically.
    return _guard('save document content', () async {
      await _localDatasource.saveDocumentContent(id, content);
      if (pageCount == null &&
          updatedAt == null &&
          !updateCover &&
          title == null) {
        return;
      }
      final document = await _localDatasource.getDocument(id);
      var updated = document.copyWith(
        title: title,
        pageCount: pageCount,
        updatedAt: updatedAt ?? DateTime.now(),
      );
      if (updateCover) updated = updated.withCover(coverId);
      await _localDatasource.updateDocument(updated);
    });
  }
}
