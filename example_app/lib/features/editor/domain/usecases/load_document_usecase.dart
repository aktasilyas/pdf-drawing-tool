import 'package:flutter/foundation.dart';
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
              // #region agent log
              debugPrint('🔍 [DEBUG] LoadDocumentUseCase - hasContent: ${content != null}');
              debugPrint('🔍 [DEBUG] LoadDocumentUseCase - templateId: ${docInfo.templateId}');
              // #endregion
              
              if (content == null) {
                // New document - create with template background
                final background = _getBackgroundForTemplate(
                  docInfo.templateId,
                  paperColor: docInfo.paperColor,
                );
                
                debugPrint('📄 [LOAD] Creating NEW document (empty)');
                
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
                
                debugPrint('✅ [LOAD] Document loaded - id: ${doc.id}, strokes: ${doc.currentPage?.layers.firstOrNull?.strokes.length ?? 0}');
                
                return Right(doc);
              } catch (e, stackTrace) {
                debugPrint('❌ JSON Parse Error: $e');
                debugPrint('❌ Stack Trace: $stackTrace');
                debugPrint('❌ Raw JSON (first 1000 chars): ${content.toString().substring(0, content.toString().length > 1000 ? 1000 : content.toString().length)}');
                
                // Try to identify which field failed
                if (content.containsKey('pages')) {
                  final pages = content['pages'] as List?;
                  debugPrint('❌ Pages count: ${pages?.length}');
                  if (pages != null && pages.isNotEmpty) {
                    debugPrint('❌ First page sample: ${pages[0]}');
                  }
                }
                
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
    
    // Try to get template from registry
    final template = TemplateRegistry.getById(templateId);
    
    if (template == null) {
      debugPrint('⚠️ [LOAD] Template not found: $templateId, using blank');
      return PageBackground(
        type: BackgroundType.blank,
        color: bgColor,
      );
    }
    
    // Use template-based background for ALL patterns
    // This ensures all 16 patterns render correctly
    return PageBackground(
      type: BackgroundType.template,
      color: bgColor,
      lineColor: template.defaultLineColor,
      templatePattern: template.pattern,
      templateSpacingMm: template.spacingMm,
      templateLineWidth: template.lineWidth,
    );
  }
  
  /// Convert paper color string to hex color
  int _getPaperColor(String paperColor) {
    switch (paperColor) {
      case 'Beyaz kağıt':
        return 0xFFFFFFFF; // Pure white
      case 'Siyah kağıt':
        return 0xFF1A1A1A; // Black (dark mode)
      case 'Krem kağıt':
        return 0xFFFFF8E7; // Cream
      case 'Gri kağıt':
        return 0xFFF5F5F5; // Light gray
      case 'Yeşil kağıt':
        return 0xFFE8F5E9; // Light green
      case 'Mavi kağıt':
        return 0xFFE3F2FD; // Light blue
      case 'Sarı kağıt':
        return 0xFFFFFDE7; // Cream/yellow tint (legacy)
      default:
        return 0xFFFFFFFF; // Default to white
    }
  }
}
