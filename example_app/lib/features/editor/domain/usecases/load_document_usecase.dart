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

    return await result.fold(
      (failure) async => Left(failure),
      (docInfo) async {
        // 2. Load document content (blob) and deserialize
        try {
          final contentResult =
              await _repository.getDrawingDocument(documentId);

          return await contentResult.fold(
            (failure) => Left(failure),
            (stored) {
              if (stored == null) {
                // New document - create with template background
                // CRITICAL: Create page size that fills viewport at 1.0 zoom
                // Use aspect ratio from paper dimensions, but scale to reasonable screen size
                final aspectRatio =
                    docInfo.paperWidthMm / docInfo.paperHeightMm;

                // Standard viewport height (portrait tablet ~1024px)
                // Page will fill viewport height at 1.0 zoom
                const targetHeight = 1024.0;
                final targetWidth = targetHeight * aspectRatio;

                final pageSize = PageSize(
                  width: targetWidth,
                  height: targetHeight,
                );

                final List<Page> pages = [];

                // If document has a cover, create cover page first
                if (docInfo.hasCover && docInfo.coverId != null) {
                  final coverBackground = _getBackgroundForCover(
                    docInfo.coverId!,
                    paperColor: docInfo.paperColor,
                  );
                  pages.add(Page.createCover(
                    index: 0,
                    size: pageSize,
                    background: coverBackground,
                  ));
                }

                // Add template page
                final templateBackground = _getBackgroundForTemplate(
                  docInfo.templateId,
                  paperColor: docInfo.paperColor,
                );
                pages.add(Page.create(
                  index: pages.length,
                  size: pageSize,
                  background: templateBackground,
                ));

                logger.i(
                    'Created new document: ${docInfo.id} with ${pages.length} pages');

                return Right(DrawingDocument.multiPage(
                  id: docInfo.id,
                  title: docInfo.title,
                  pages: pages,
                  createdAt: docInfo.createdAt,
                  updatedAt: docInfo.updatedAt,
                  documentType: docInfo.documentType,
                ));
              }
              // Library metadata owns the title and the id; stored content may
              // be stale (or carry the source's id, for pre-fix duplicates).
              final doc =
                  stored.copyWith(id: documentId, title: docInfo.title);
              logger.i('Document loaded: ${doc.id}');
              return Right(doc);
            },
          );
        } catch (e) {
          return Left(CacheFailure('Failed to load document: $e'));
        }
      },
    );
  }

  /// Convert template ID to PageBackground
  PageBackground _getBackgroundForTemplate(String templateId,
      {String paperColor = 'Sarı kağıt'}) {
    // Convert paper color string to hex
    final bgColor = _getPaperColor(paperColor);

    // Try to get template from registry
    final template = TemplateRegistry.getById(templateId);

    if (template == null) {
      logger.w('Template not found: $templateId, using blank');
      return PageBackground(
        type: BackgroundType.blank,
        color: bgColor,
      );
    }

    // Use template-based background for ALL patterns
    // This ensures all 16 patterns render correctly
    return PageBackground.fromTemplate(template, color: bgColor);
  }

  /// Convert cover ID to PageBackground
  PageBackground _getBackgroundForCover(String coverId,
      {String paperColor = 'Sarı kağıt'}) {
    // Try to get cover from registry
    final cover = CoverRegistry.byId(coverId);

    if (cover == null) {
      logger.w('Cover not found: $coverId, using blank black');
      return const PageBackground(
        type: BackgroundType.blank,
        color: 0xFF000000, // Black fallback
      );
    }

    // Use cover type to render proper background on canvas
    return PageBackground(
      type: BackgroundType.cover,
      color: cover.primaryColor,
      coverId: coverId,
    );
  }

  /// Paper colour for a stored value in either spelling; white if unknown.
  int _getPaperColor(String paperColor) =>
      (PaperColor.tryParse(paperColor) ?? PaperColor.white).argb;
}
