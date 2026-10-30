import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/paper_color.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/presentation/providers/documents_invalidation.dart';
import 'package:example_app/features/documents/presentation/providers/imported_document_content.dart';
import 'package:example_app/features/documents/presentation/providers/library_error.dart';

/// PDF import: creates a document from pre-rendered pages, and never leaves
/// a half-imported (empty) notebook behind.
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

    String? createdId;
    final paper = importedPaperFromPages(pages);
    try {
      // 1. Create the document with a blank template.
      final result = await repository.createDocument(
        title: title,
        templateId: 'blank', // PDF needs no template
        folderId: folderId,
        paperColor: PaperColor.white.storageKey, // PDF default
        isPortrait: paper.isPortrait,
        documentType: documentType,
        paperWidthMm: paper.widthMm,
        paperHeightMm: paper.heightMm,
      );

      return await result.fold(
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
          reportLibraryFailure(ref, failure, LibraryAction.importDocument);
          return null;
        },
        (document) async {
          createdId = document.id;
          // 2. Save the V2 content with the imported pages.
          final content = buildImportedDocumentContent(
            document: document,
            pages: pages,
            documentType: documentType,
          );

          final saveResult = await repository.saveDocumentContent(
            id: document.id,
            content: content,
            pageCount: pageCount,
          );

          if (saveResult.isLeft()) {
            // Never leave an empty ghost notebook behind.
            await _discardHalfImported(document.id);
          }
          return saveResult.fold(
            (failure) {
              state = AsyncValue.error(failure, StackTrace.current);
              reportLibraryFailure(ref, failure, LibraryAction.importDocument);
              return null;
            },
            (_) {
              state = const AsyncValue.data(null);
              invalidateAllDocumentLists(ref);
              return document.id;
            },
          );
        },
      );
    } catch (e) {
      final id = createdId;
      if (id != null) await _discardHalfImported(id);
      state = AsyncValue.error(e, StackTrace.current);
      reportLibraryError(ref, e, LibraryAction.importDocument);
      return null;
    }
  }

  /// Best-effort removal of a document row whose imported content was not saved.
  Future<void> _discardHalfImported(String id) async {
    try {
      await repository.permanentlyDelete(id);
    } catch (_) {
      // Nothing more to do; the original failure is reported by the caller.
    }
  }
}
