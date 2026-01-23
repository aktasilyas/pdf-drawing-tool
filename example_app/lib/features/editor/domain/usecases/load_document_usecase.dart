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
                final background = _getBackgroundForTemplate(
                  docInfo.templateId,
                  paperColor: docInfo.paperColor,
                );
                return Right(DrawingDocument.multiPage(
                  id: docInfo.id,
                  title: docInfo.title,
                  pages: [Page.create(index: 0, background: background)],
                  createdAt: docInfo.createdAt,
                  updatedAt: docInfo.updatedAt,
                  documentType: docInfo.documentType,
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
  PageBackground _getBackgroundForTemplate(String templateId, {String paperColor = 'Sarı kağıt'}) {
    // Convert paper color string to hex
    final bgColor = _getPaperColor(paperColor);
    
    switch (templateId) {
      case 'blank':
        return PageBackground(
          type: BackgroundType.blank,
          color: bgColor,
        );
        
      case 'thin_lined':
        return PageBackground(
          type: BackgroundType.lined,
          color: bgColor,
          lineSpacing: 20,
          lineColor: 0xFFE8E8E8,
        );
        
      case 'thick_lined':
        return PageBackground(
          type: BackgroundType.lined,
          color: bgColor,
          lineSpacing: 32,
          lineColor: 0xFFD0D0D0,
        );
        
      case 'small_grid':
        return PageBackground(
          type: BackgroundType.grid,
          color: bgColor,
          gridSpacing: 16,
          lineColor: 0xFFE8E8E8,
        );
        
      case 'large_grid':
        return PageBackground(
          type: BackgroundType.grid,
          color: bgColor,
          gridSpacing: 32,
          lineColor: 0xFFD0D0D0,
        );
        
      case 'dotted':
        return PageBackground(
          type: BackgroundType.dotted,
          color: bgColor,
          gridSpacing: 20,
          lineColor: 0xFFCCCCCC,
        );
        
      case 'cornell':
        // Cornell uses lined with special layout (handled by UI)
        return PageBackground(
          type: BackgroundType.lined,
          color: bgColor,
          lineSpacing: 24,
          lineColor: 0xFFE0E0E0,
        );
        
      default:
        return PageBackground(
          type: BackgroundType.blank,
          color: bgColor,
        );
    }
  }
  
  /// Convert paper color string to hex color
  int _getPaperColor(String paperColor) {
    switch (paperColor) {
      case 'Beyaz kağıt':
        return 0xFFFFFFFF; // Pure white
      case 'Sarı kağıt':
        return 0xFFFFFDE7; // Cream/yellow tint
      case 'Gri kağıt':
        return 0xFFF5F5F5; // Light gray
      default:
        return 0xFFFFFDE7; // Default to cream
    }
  }
}
