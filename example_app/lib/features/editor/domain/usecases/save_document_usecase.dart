import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/domain/usecases/document_json_slicer.dart';
import 'package:example_app/features/editor/domain/usecases/page_json_cache.dart';
import 'package:drawing_core/drawing_core.dart';

@injectable
class SaveDocumentUseCase {
  final DocumentRepository _repository;

  final DocumentJsonSlicer _slicer;

  /// Encoded page JSON of the editor session this instance lives in.
  final PageJsonCache _pageCache;

  SaveDocumentUseCase(
    this._repository, {
    DocumentJsonSlicer slicer = const DocumentJsonSlicer(),
    PageJsonCache? pageCache,
  })  : _slicer = slicer,
        _pageCache = pageCache ?? PageJsonCache();

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
      _pageCache.retainFor(document.id);

      // Cover pages are saved like any other page: ink, shapes and text
      // written on a cover are user content (#423).
      final updated = document.copyWith(updatedAt: DateTime.now());

      // 1. Serialize document to JSON
      // Large documents are converted page by page, yielding to frames.
      final content = await _slicer.toJson(updated, cache: _pageCache);

      // 2. Extract coverId from cover page for metadata sync
      final coverPage = document.pages.where((p) => p.isCover).firstOrNull;
      final coverId = coverPage?.background.coverId;

      // 3. Save to DB
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
      return Left(cacheFailureFor(e, 'Failed to save document: $e'));
    }
  }
}
