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
      trashId = await repo.movePageToTrash(
        documentId: documentId,
        documentTitle: documentTitle,
        pageIndex: pageIndex,
        pageData: pageData,
      );
    } catch (e) {
      reportLibraryError(ref, e, 'Sayfa çöpe taşınamadı');
    }
    invalidatePageTrash(ref);
    return trashId;
  }

  Future<bool> restorePageFromTrash(String trashedPageId) async {
    final repo = ref.read(pageTrashRepositoryProvider);
    var result = false;
    try {
      result = await repo.restorePageFromTrash(trashedPageId);
    } catch (e) {
      logger.w('Page restore failed: $e');
    }
    invalidatePageTrash(ref);
    ref.invalidate(documentsProvider);
    return result;
  }

  Future<void> permanentlyDeletePage(String trashedPageId) async {
    final repo = ref.read(pageTrashRepositoryProvider);
    try {
      await repo.permanentlyDeletePage(trashedPageId);
    } catch (e) {
      reportLibraryError(ref, e, 'Sayfa kalıcı olarak silinemedi');
    }
    invalidatePageTrash(ref);
  }

  Future<bool> trashedPageDocumentExists(String documentId) async {
    final repo = ref.read(pageTrashRepositoryProvider);
    return repo.documentExists(documentId);
  }
}
