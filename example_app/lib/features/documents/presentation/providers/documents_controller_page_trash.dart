import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/presentation/providers/document_list_providers.dart';
import 'package:example_app/features/documents/presentation/providers/documents_invalidation.dart';
import 'package:example_app/features/documents/presentation/providers/library_error.dart';
import 'package:example_app/features/documents/presentation/providers/trash_providers.dart';

/// Page-trash operations of the documents controller.
mixin DocumentsPageTrashOperations on StateNotifier<AsyncValue<void>> {
  @protected
  Ref get ref;

  /// Returns the trash entry id, or null when the move failed.
  Future<String?> movePageToTrash({
    required String documentId,
    required String documentTitle,
    required int pageIndex,
    required Map<String, dynamic> pageData,
  }) async {
    final repo = ref.read(pageTrashRepositoryProvider);
    String? trashId;
    try {
      final result = await repo.movePageToTrash(
        documentId: documentId,
        documentTitle: documentTitle,
        pageIndex: pageIndex,
        pageData: pageData,
      );
      trashId = result.fold((failure) {
        reportLibraryFailure(ref, failure, LibraryAction.trashPage);
        return null;
      }, (id) => id);
    } catch (e) {
      reportLibraryError(ref, e, LibraryAction.trashPage);
    }
    invalidatePageTrash(ref);
    return trashId;
  }

  Future<bool> restorePageFromTrash(String trashedPageId) async {
    final repo = ref.read(pageTrashRepositoryProvider);
    var restored = false;
    try {
      final result = await repo.restorePageFromTrash(trashedPageId);
      restored = result.fold((failure) {
        logger.w('Page restore failed: ${failure.message}');
        return false;
      }, (ok) => ok);
    } catch (e) {
      logger.w('Page restore failed: $e');
    }
    invalidatePageTrash(ref);
    ref.invalidate(documentsProvider);
    return restored;
  }

  Future<void> permanentlyDeletePage(String trashedPageId) async {
    final repo = ref.read(pageTrashRepositoryProvider);
    try {
      final result = await repo.permanentlyDeletePage(trashedPageId);
      result.fold((failure) {
        reportLibraryFailure(ref, failure, LibraryAction.deletePageForever);
      }, (_) {});
    } catch (e) {
      reportLibraryError(ref, e, LibraryAction.deletePageForever);
    }
    invalidatePageTrash(ref);
  }

  Future<bool> trashedPageDocumentExists(String documentId) async {
    final repo = ref.read(pageTrashRepositoryProvider);
    final result = await repo.documentExists(documentId);
    return result.getOrElse(() => false);
  }
}
