import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/editor/domain/usecases/document_json_slicer.dart';

/// Changes the cover of a notebook from the library.
///
/// Only the cover page background (and the row's `coverId`) change; layers,
/// strokes and text on the cover page are kept.
class ChangeCoverUseCase {
  ChangeCoverUseCase(
    this._repository, {
    DocumentJsonSlicer slicer = const DocumentJsonSlicer(),
  }) : _slicer = slicer;

  final DocumentRepository _repository;
  final DocumentJsonSlicer _slicer;

  Future<Either<Failure, void>> call(String documentId, String coverId) async {
    final cover = CoverRegistry.byId(coverId);
    if (cover == null) {
      return Left(ValidationFailure('Unknown cover: $coverId'));
    }
    try {
      final info = await _repository.getDocument(documentId);
      final infoFailure = info.fold<Failure?>((f) => f, (_) => null);
      if (infoFailure != null) return Left(infoFailure);
      final hasCover = info.fold<bool>((_) => false, (i) => i.hasCover);
      if (!hasCover) {
        return const Left(ValidationFailure('Document has no cover'));
      }

      final stored = await _repository.getDrawingDocument(documentId);
      final storedFailure = stored.fold<Failure?>((f) => f, (_) => null);
      if (storedFailure != null) return Left(storedFailure);
      final doc = stored.fold<DrawingDocument?>((_) => null, (d) => d);

      // Never opened: LoadDocumentUseCase builds the cover page from the row.
      if (doc == null || doc.pages.isEmpty) {
        return _repository.updateCover(documentId, coverId);
      }

      final updated = _withCover(doc, cover);
      final content = await _slicer.toJson(updated);
      return _repository.saveDocumentContent(
        id: documentId,
        content: content,
        pageCount: updated.pageCount,
        updatedAt: DateTime.now(),
        coverId: coverId,
        updateCover: true,
      );
    } catch (e) {
      return Left(CacheFailure('Failed to change cover: $e'));
    }
  }

  /// Same background the editor builds when its cover is changed.
  DrawingDocument _withCover(DrawingDocument doc, Cover cover) {
    final background = PageBackground(
      type: BackgroundType.cover,
      coverId: cover.id,
      color: cover.primaryColor,
    );
    final pages = List<Page>.from(doc.pages);
    final index = pages.indexWhere((p) => p.isCover);
    if (index >= 0) {
      pages[index] = pages[index].copyWith(background: background);
    } else {
      pages.insert(
        0,
        Page.createCover(
          index: 0,
          size: doc.pages.first.size,
          background: background,
        ),
      );
    }
    return doc.replacePages(pages);
  }
}
