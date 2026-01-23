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
                // New document - create with template background
                final background = _getBackgroundForTemplate(docInfo.templateId);
                return Right(DrawingDocument.multiPage(
                  id: docInfo.id,
                  title: docInfo.title,
                  pages: [Page.create(index: 0, background: background)],
                  createdAt: docInfo.createdAt,
                  updatedAt: docInfo.updatedAt,
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

  /// Convert template ID to PageBackground
  PageBackground _getBackgroundForTemplate(String templateId) {
    switch (templateId) {
      case 'blank':
        return PageBackground.blank;
        
      case 'thin_lined':
        return const PageBackground(
          type: BackgroundType.lined,
          lineSpacing: 20,
          lineColor: 0xFFE8E8E8,
        );
        
      case 'thick_lined':
        return const PageBackground(
          type: BackgroundType.lined,
          lineSpacing: 32,
          lineColor: 0xFFD0D0D0,
        );
        
      case 'small_grid':
        return const PageBackground(
          type: BackgroundType.grid,
          gridSpacing: 16,
          lineColor: 0xFFE8E8E8,
        );
        
      case 'large_grid':
        return const PageBackground(
          type: BackgroundType.grid,
          gridSpacing: 32,
          lineColor: 0xFFD0D0D0,
        );
        
      case 'dotted':
        return const PageBackground(
          type: BackgroundType.dotted,
          gridSpacing: 20,
          lineColor: 0xFFCCCCCC,
        );
        
      case 'cornell':
        // Cornell uses lined with special layout (handled by UI)
        return const PageBackground(
          type: BackgroundType.lined,
          lineSpacing: 24,
          lineColor: 0xFFE0E0E0,
        );
        
      default:
        return PageBackground.blank;
    }
  }
}
