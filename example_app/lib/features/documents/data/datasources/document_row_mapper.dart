import 'package:drift/drift.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/models/document_model.dart';

/// Maps a Drift documents row to the data-layer model.
extension DocumentRowMapper on DocumentRow {
  DocumentModel toModel() => DocumentModel(
        id: id,
        title: title,
        folderId: folderId,
        templateId: templateId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        thumbnailPath: thumbnailPath,
        pageCount: pageCount,
        isFavorite: isFavorite,
        isInTrash: isInTrash,
        deletedAt: deletedAt,
        syncState: syncState,
        paperColor: paperColor,
        isPortrait: isPortrait,
        documentType: documentType,
        coverId: coverId,
        hasCover: hasCover,
        paperWidthMm: paperWidthMm,
        paperHeightMm: paperHeightMm,
      );
}

/// Maps the data-layer model to a full Drift documents companion.
extension DocumentModelCompanion on DocumentModel {
  DocumentsCompanion toCompanion() => DocumentsCompanion(
        id: Value(id),
        title: Value(title),
        folderId: Value(folderId),
        templateId: Value(templateId),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        thumbnailPath: Value(thumbnailPath),
        pageCount: Value(pageCount),
        isFavorite: Value(isFavorite),
        isInTrash: Value(isInTrash),
        deletedAt: Value(deletedAt),
        syncState: Value(syncState),
        paperColor: Value(paperColor),
        isPortrait: Value(isPortrait),
        documentType: Value(documentType),
        coverId: Value(coverId),
        hasCover: Value(hasCover),
        paperWidthMm: Value(paperWidthMm),
        paperHeightMm: Value(paperHeightMm),
      );
}
