import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:drawing_core/drawing_core.dart';

@injectable
class SaveDocumentUseCase {
  final DocumentRepository _repository;

  SaveDocumentUseCase(this._repository);

  Future<Either<Failure, void>> call(DrawingDocument document) async {
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
      final content = cleanedDocument.toJson();

      // 3. Extract coverId from cover page for metadata sync
      final coverPage = document.pages
          .where((p) => p.isCover)
          .firstOrNull;
      final coverId = coverPage?.background.coverId;

      // 4. Save to DB
      final result = await _repository.saveDocumentContent(
        id: document.id,
        content: content,
        pageCount: document.pageCount,
        updatedAt: DateTime.now(),
        coverId: coverId,
        updateCover: true,
      );

      result.fold(
        (failure) => logger.e('Save document failed', error: failure.message),
        (_) => logger.i('Document saved: ${document.id}'),
      );

      return result;
    } catch (e) {
      logger.e('Save document exception', error: e, stackTrace: StackTrace.current);
      return Left(CacheFailure('Failed to save document: $e'));
    }
  }
}
