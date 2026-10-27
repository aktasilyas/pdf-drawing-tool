import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/paper_color.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/presentation/providers/document_list_providers.dart';
import 'package:example_app/features/documents/presentation/providers/documents_controller_bulk.dart';
import 'package:example_app/features/documents/presentation/providers/documents_controller_empty_trash.dart';
import 'package:example_app/features/documents/presentation/providers/documents_controller_page_trash.dart';
import 'package:example_app/features/documents/presentation/providers/documents_invalidation.dart';
import 'package:example_app/features/documents/presentation/providers/imported_document_content.dart';
import 'package:example_app/features/documents/presentation/providers/library_error.dart';

/// Mutations on notebooks: create, rename, move, favourite, trash, restore,
/// duplicate and delete. Bulk and page-trash operations live in mixins.
class DocumentsController extends StateNotifier<AsyncValue<void>>
    with
        DocumentsBulkOperations,
        DocumentsPageTrashOperations,
        DocumentsEmptyTrashOperation {
  @override
  final DocumentRepository repository;
  @override
  final Ref ref;

  DocumentsController(this.repository, this.ref)
      : super(const AsyncValue.data(null));

  Future<String?> createDocument({
    required String title,
    required String templateId,
    String? folderId,
    String? paperColor,
    bool isPortrait = true,
    DocumentType documentType = DocumentType.notebook,
    String? coverId,
    bool hasCover = true,
    double paperWidthMm = 210.0,
    double paperHeightMm = 297.0,
  }) async {
    state = const AsyncValue.loading();
    final result = await repository.createDocument(
      title: title,
      templateId: templateId,
      folderId: folderId,
      paperColor: paperColor ?? PaperColor.yellow.storageKey,
      isPortrait: isPortrait,
      documentType: documentType,
      coverId: coverId,
      hasCover: hasCover,
      paperWidthMm: paperWidthMm,
      paperHeightMm: paperHeightMm,
    );
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        reportLibraryFailure(ref, failure, LibraryAction.createDocument);
        return null;
      },
      (document) {
        state = const AsyncValue.data(null);
        invalidateAllDocumentLists(ref);
        return document.id;
      },
    );
  }

  /// Create document with pre-rendered pages (for PDF import).
  Future<String?> createDocumentWithPages({
    required String title,
    String? folderId,
    required DocumentType documentType,
    required List<Map<String, dynamic>> pages,
    required int pageCount,
  }) async {
    state = const AsyncValue.loading();

    try {
      // 1. Create the document with a blank template.
      final result = await repository.createDocument(
        title: title,
        templateId: 'blank', // PDF needs no template
        folderId: folderId,
        paperColor: PaperColor.white.storageKey, // PDF default
        isPortrait: true,
        documentType: documentType,
      );

      return await result.fold(
        (failure) {
          state = AsyncValue.error(failure, StackTrace.current);
          reportLibraryFailure(ref, failure, LibraryAction.importDocument);
          return null;
        },
        (document) async {
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
      state = AsyncValue.error(e, StackTrace.current);
      reportLibraryError(ref, e, LibraryAction.importDocument);
      return null;
    }
  }

  Future<bool> moveDocument(String documentId, String? targetFolderId) async {
    state = const AsyncValue.loading();
    final result = await repository.moveDocument(documentId, targetFolderId);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        reportLibraryFailure(ref, failure, LibraryAction.moveDocument);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        invalidateAllDocumentLists(ref);
        return true;
      },
    );
  }

  Future<bool> toggleFavorite(String documentId) async {
    final result = await repository.toggleFavorite(documentId);
    return result.fold(
      (failure) {
        reportLibraryFailure(ref, failure, LibraryAction.toggleFavorite);
        return false;
      },
      (_) {
        // Only invalidate favorites and the documents list
        invalidateDocumentLists(ref, documents: true, favorites: true);
        return true;
      },
    );
  }

  Future<bool> moveToTrash(String documentId) async {
    final result = await repository.moveToTrash(documentId);
    return result.fold(
      (failure) {
        reportLibraryFailure(ref, failure, LibraryAction.trashDocument);
        return false;
      },
      (_) {
        // Invalidate documents, trash, and folders (for counts)
        invalidateTrashMove(ref);
        return true;
      },
    );
  }

  Future<bool> deleteDocument(String documentId) async {
    final result = await repository.deleteDocument(documentId);
    return result.fold(
      (failure) {
        reportLibraryFailure(ref, failure, LibraryAction.deleteDocument);
        return false;
      },
      (_) {
        invalidateAllDocumentLists(ref);
        return true;
      },
    );
  }

  Future<bool> renameDocument(String documentId, String newTitle) async {
    final result =
        await repository.updateDocument(id: documentId, title: newTitle);
    return result.fold(
      (failure) {
        reportLibraryFailure(ref, failure, LibraryAction.renameDocument);
        return false;
      },
      (_) {
        // Only invalidate documents list (rename doesn't affect favorites/trash)
        invalidateDocumentLists(ref, documents: true);
        return true;
      },
    );
  }

  // Single document restore from trash
  Future<bool> restoreFromTrash(String id) async {
    try {
      final result = await repository.restoreFromTrash(id);
      return await result.fold(
        (failure) {
          state = AsyncError(failure, StackTrace.current);
          reportLibraryFailure(ref, failure, LibraryAction.restoreDocument);
          return false;
        },
        (_) {
          // Invalidate documents, trash, and folders
          invalidateTrashMove(ref);
          return true;
        },
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      reportLibraryError(ref, e, LibraryAction.restoreDocument);
      return false;
    }
  }

  // Single document duplicate
  Future<bool> duplicateDocument(String id) async {
    try {
      final result = await repository.duplicateDocument(id);
      return await result.fold(
        (failure) {
          state = AsyncError(failure, StackTrace.current);
          reportLibraryFailure(ref, failure, LibraryAction.duplicateDocument);
          return false;
        },
        (_) {
          invalidateAllDocumentLists(ref);
          return true;
        },
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      reportLibraryError(ref, e, LibraryAction.duplicateDocument);
      return false;
    }
  }

  // Single document permanent delete
  Future<bool> permanentlyDeleteDocument(String id) async {
    try {
      final result = await repository.permanentlyDelete(id);
      return await result.fold(
        (failure) {
          state = AsyncError(failure, StackTrace.current);
          reportLibraryFailure(
              ref, failure, LibraryAction.deleteDocumentForever);
          return false;
        },
        (_) {
          invalidateDocumentLists(ref, trash: true, documentCount: true);
          return true;
        },
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      reportLibraryError(ref, e, LibraryAction.deleteDocumentForever);
      return false;
    }
  }
}

final documentsControllerProvider =
    StateNotifierProvider<DocumentsController, AsyncValue<void>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return DocumentsController(repository, ref);
});
