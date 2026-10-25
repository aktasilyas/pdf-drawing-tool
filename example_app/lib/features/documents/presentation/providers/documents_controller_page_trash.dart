import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/presentation/providers/document_list_providers.dart';
import 'package:example_app/features/documents/presentation/providers/documents_invalidation.dart';
import 'package:example_app/features/documents/presentation/providers/trash_providers.dart';

/// Page-trash operations of the documents controller.
mixin DocumentsPageTrashOperations on StateNotifier<AsyncValue<void>> {
  @protected
  Ref get ref;

  Future<void> movePageToTrash({
    required String documentId,
    required String documentTitle,
    required int pageIndex,
    required Map<String, dynamic> pageData,
  }) async {
    final repo = ref.read(pageTrashRepositoryProvider);
    await repo.movePageToTrash(
      documentId: documentId,
      documentTitle: documentTitle,
      pageIndex: pageIndex,
      pageData: pageData,
    );
    invalidatePageTrash(ref);
  }

  Future<bool> restorePageFromTrash(String trashedPageId) async {
    final repo = ref.read(pageTrashRepositoryProvider);
    final result = await repo.restorePageFromTrash(trashedPageId);
    invalidatePageTrash(ref);
    ref.invalidate(documentsProvider);
    return result;
  }

  Future<void> permanentlyDeletePage(String trashedPageId) async {
    final repo = ref.read(pageTrashRepositoryProvider);
    await repo.permanentlyDeletePage(trashedPageId);
    invalidatePageTrash(ref);
  }

  Future<bool> trashedPageDocumentExists(String documentId) async {
    final repo = ref.read(pageTrashRepositoryProvider);
    return repo.documentExists(documentId);
  }
}
