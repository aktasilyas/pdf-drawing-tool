import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/datasources/document_local_datasource.dart';
import 'package:example_app/features/documents/data/models/document_model.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:uuid/uuid.dart';

/// Creating, importing and duplicating documents for [DocumentRepositoryImpl].
mixin DocumentCreation {
  DocumentLocalDatasource get localDatasource;

  Uuid get uuid;

  /// Runs [action] in one transaction and maps errors to a [Failure].
  Future<Either<Failure, T>> guard<T>(
    String what,
    Future<T> Function() action,
  );

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
      final document = _newDocument(
        title: title,
        templateId: templateId,
        folderId: folderId,
        paperColor: paperColor,
        isPortrait: isPortrait,
        documentType: documentType,
        coverId: coverId,
        hasCover: hasCover,
        paperWidthMm: paperWidthMm,
        paperHeightMm: paperHeightMm,
        pageCount: 1,
      );
      final created = await localDatasource.createDocument(document);
      return Right(created.toEntity());
    } on CacheException catch (e) {
      return Left(cacheFailureFor(e, e.message));
    } catch (e) {
      return Left(cacheFailureFor(e, 'Failed to create document: $e'));
    }
  }

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
  }) {
    // Row and content are written in one transaction: if the content write
    // fails, or the app dies before it commits, the row is not kept (#602).
    return guard('import document', () async {
      final document = _newDocument(
        title: title,
        templateId: templateId,
        folderId: folderId,
        paperColor: paperColor,
        isPortrait: isPortrait,
        documentType: documentType,
        coverId: null,
        hasCover: true,
        paperWidthMm: paperWidthMm,
        paperHeightMm: paperHeightMm,
        pageCount: pageCount,
      );
      final created = await localDatasource.createDocument(document);
      final entity = created.toEntity();
      await localDatasource.saveDocumentContent(
        created.id,
        buildContent(entity),
      );
      return entity;
    });
  }

  Future<Either<Failure, DocumentInfo>> duplicateDocument(
    String id, {
    required String Function(String title) copyTitle,
  }) async {
    // Document row and content are copied in one transaction.
    final result = await guard('duplicate document', () async {
      final original = await localDatasource.getDocument(id);
      final now = DateTime.now();
      final duplicate = original.copyWith(
        id: uuid.v4(),
        title: copyTitle(original.title),
        createdAt: now,
        updatedAt: now,
        isFavorite: false, // Don't copy favorite status
      );
      final created = await localDatasource.createDocument(duplicate);
      final content = await localDatasource.getDocumentContent(id);
      if (content != null) {
        // The content carries its own id; it must follow the copy's row id,
        // or edits to the copy would be saved over the original.
        await localDatasource
            .saveDocumentContent(created.id, {...content, 'id': created.id});
      }
      return created;
    });
    return result.map((m) => m.toEntity());
  }

  DocumentModel _newDocument({
    required String title,
    required String templateId,
    required String? folderId,
    required String paperColor,
    required bool isPortrait,
    required DocumentType documentType,
    required String? coverId,
    required bool hasCover,
    required double paperWidthMm,
    required double paperHeightMm,
    required int pageCount,
  }) {
    final now = DateTime.now();
    return DocumentModel(
      id: uuid.v4(),
      title: title,
      templateId: templateId,
      folderId: folderId,
      createdAt: now,
      updatedAt: now,
      pageCount: pageCount,
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
  }
}
