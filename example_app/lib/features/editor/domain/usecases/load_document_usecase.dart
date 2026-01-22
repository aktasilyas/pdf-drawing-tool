import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:drawing_core/drawing_core.dart';

@injectable
class LoadDocumentUseCase {
  final DocumentRepository _repository;

  LoadDocumentUseCase(this._repository);

  Future<Either<Failure, DrawingDocument>> call(String documentId) async {
    // 1. Get document info from DB
    final result = await _repository.getDocument(documentId);
    
    return result.fold(
      (failure) => Left(failure),
      (docInfo) async {
        // 2. Load document content (blob) and deserialize
        try {
          final contentResult = await _repository.getDocumentContent(documentId);
          
          return contentResult.fold(
            (failure) => Left(failure),
            (content) {
              if (content == null) {
                // New document - create empty
                return Right(DrawingDocument.multiPage(
                  id: docInfo.id,
                  title: docInfo.title,
                  pages: [Page.create(index: 0)],
                ));
              }
              // Deserialize from JSON
              try {
                final doc = DrawingDocument.fromJson(content);
                return Right(doc);
              } catch (e) {
                return Left(CacheFailure('Document corrupted: $e'));
              }
            },
          );
        } catch (e) {
          return Left(CacheFailure('Failed to load document: $e'));
        }
      },
    );
  }
}
