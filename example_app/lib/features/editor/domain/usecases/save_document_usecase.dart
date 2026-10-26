import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/domain/usecases/document_json_slicer.dart';
import 'package:drawing_core/drawing_core.dart';

@injectable
class SaveDocumentUseCase {
  final DocumentRepository _repository;

  final DocumentJsonSlicer _slicer;

  SaveDocumentUseCase(
    this._repository, {
    DocumentJsonSlicer slicer = const DocumentJsonSlicer(),
  }) : _slicer = slicer;

  /// Saves run strictly one after another: slicing yields to the event loop,
  /// so a slow save of an older large document must not reach the datasource
  /// after a newer one (keeps the #214 ordering guard).
  static Future<void> _tail = Future<void>.value();

  Future<Either<Failure, void>> call(DrawingDocument document) {
    final run = _tail.then((_) => _save(document));
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<Either<Failure, void>> _save(DrawingDocument document) async {
    try {
      // 1. Clean cover pages (remove drawings from cover pages)
      final cleanedPages = document.pages.map((page) {
        if (page.isCover) {
          return page.clearDrawings();
        }
        return page;
      }).toList();

      // Create cleaned document
      final cleanedDocument = document.copyWith(
        pages: cleanedPages,
        updatedAt: DateTime.now(),
      );

      // 2. Serialize document to JSON
      // Large documents are converted page by page, yielding to frames.
      final content = await _slicer.toJson(cleanedDocument);

      // 3. Extract coverId from cover page for metadata sync
      final coverPage = document.pages.where((p) => p.isCover).firstOrNull;
      final coverId = coverPage?.background.coverId;

      // 4. Save to DB
      final result = await _repository.saveDocumentContent(
        id: document.id,
        content: content,
        pageCount: document.pageCount,
        updatedAt: DateTime.now(),
        coverId: coverId,
        updateCover: true,
        title: document.title,
      );

      result.fold(
        (failure) => logger.e('Save document failed', error: failure.message),
        (_) => logger.i('Document saved: ${document.id}'),
      );

      return result;
    } catch (e) {
      logger.e('Save document exception',
          error: e, stackTrace: StackTrace.current);
      return Left(CacheFailure('Failed to save document: $e'));
    }
  }
}
