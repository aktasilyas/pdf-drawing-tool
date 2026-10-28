import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/presentation/providers/documents_invalidation.dart';
import 'package:example_app/features/documents/presentation/providers/library_error.dart';
import 'package:example_app/features/documents/presentation/providers/trash_providers.dart';

/// "Empty trash": permanently deletes trashed documents and trashed pages.
mixin DocumentsEmptyTrashOperation on StateNotifier<AsyncValue<void>> {
  @protected
  DocumentRepository get repository;

  @protected
  Ref get ref;

  /// Returns true when everything in the trash was deleted.
  Future<bool> emptyTrash() async {
    var success = true;
    try {
      final documents = await repository.emptyTrash();
      documents.fold((failure) {
        success = false;
        reportLibraryFailure(ref, failure, LibraryAction.emptyTrash);
      }, (_) {});
      final pages = await ref.read(pageTrashRepositoryProvider).emptyTrash();
      pages.fold((failure) {
        success = false;
        reportLibraryFailure(ref, failure, LibraryAction.emptyTrash);
      }, (_) {});
    } catch (e) {
      success = false;
      reportLibraryError(ref, e, LibraryAction.emptyTrash);
    }
    invalidateDocumentLists(ref, trash: true, documentCount: true);
    invalidatePageTrash(ref);
    return success;
  }
}
