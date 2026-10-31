import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/paper_color.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/presentation/providers/documents_invalidation.dart';
import 'package:example_app/features/documents/presentation/providers/imported_document_content.dart';
import 'package:example_app/features/documents/presentation/providers/library_error.dart';

/// PDF import: creates a document from pre-rendered pages in one write, so it
/// never leaves a half-imported (empty) notebook behind.
mixin DocumentsImportOperation on StateNotifier<AsyncValue<void>> {
  @protected
  DocumentRepository get repository;

  @protected
  Ref get ref;

  /// Create document with pre-rendered pages (for PDF import).
  Future<String?> createDocumentWithPages({
    required String title,
    String? folderId,
    required DocumentType documentType,
    required List<Map<String, dynamic>> pages,
    required int pageCount,
  }) async {
    state = const AsyncValue.loading();

    final paper = importedPaperFromPages(pages);
    try {
      // Row and imported content are written in one transaction, so a failed
      // save or the app closing mid-import leaves no blank notebook (#602).
      final result = await repository.createDocumentWithContent(
        title: title,
        templateId: 'blank', // PDF needs no template
        folderId: folderId,
        paperColor: PaperColor.white.storageKey, // PDF default
        isPortrait: paper.isPortrait,
        documentType: documentType,
        paperWidthMm: paper.widthMm,
        paperHeightMm: paper.heightMm,
        pageCount: pageCount,
        buildContent: (document) => buildImportedDocumentContent(
          document: document,
          pages: pages,
          documentType: documentType,
        ),
      );

      return result.fold<String?>(
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
          reportLibraryFailure(ref, failure, LibraryAction.importDocument);
          return null;
        },
        (document) {
          state = const AsyncValue.data(null);
          invalidateAllDocumentLists(ref);
          return document.id;
        },
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      reportLibraryError(ref, e, LibraryAction.importDocument);
      return null;
    }
  }
}
