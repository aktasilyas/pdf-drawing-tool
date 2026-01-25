import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('💿 [DB] Saving document ${document.id}');
      
      // 1. Serialize document to JSON
      final content = document.toJson();
      
      // 2. Save to DB
      final result = await _repository.saveDocumentContent(
        id: document.id,
        content: content,
        pageCount: document.pageCount,
        updatedAt: DateTime.now(),
      );
      
      result.fold(
        (failure) => debugPrint('❌ [DB] Save failed: ${failure.message}'),
        (_) => debugPrint('✅ [DB] Saved successfully'),
      );
      
      return result;
    } catch (e) {
      debugPrint('❌ [DB] Exception: $e');
      return Left(CacheFailure('Failed to save document: $e'));
    }
  }
}
