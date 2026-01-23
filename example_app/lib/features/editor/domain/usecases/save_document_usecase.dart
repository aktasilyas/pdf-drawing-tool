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
      // 1. Serialize document to JSON
      final content = document.toJson();
      
      // 2. Save to DB
      return await _repository.saveDocumentContent(
        id: document.id,
        content: content,
        pageCount: document.pageCount,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      return Left(CacheFailure('Failed to save document: $e'));
    }
  }
}
