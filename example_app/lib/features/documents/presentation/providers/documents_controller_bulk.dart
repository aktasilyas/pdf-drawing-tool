import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/presentation/providers/documents_invalidation.dart';

/// Bulk (multi-selection) document operations of the documents controller.
mixin DocumentsBulkOperations on StateNotifier<AsyncValue<void>> {
  @protected
  DocumentRepository get repository;

  @protected
  Ref get ref;

  // Bulk move to trash (soft delete)
  Future<void> moveDocumentsToTrash(List<String> ids) async {
    state = const AsyncLoading();
    try {
      for (final id in ids) {
        final result = await repository.moveToTrash(id);
        result.fold(
          (failure) => throw Exception(failure.message),
          (_) {},
        );
      }
      // Invalidate documents, trash, and folders
      invalidateTrashMove(ref);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  // Bulk permanent delete (hard delete) - for trash only
  Future<void> permanentlyDeleteDocuments(List<String> ids) async {
    state = const AsyncLoading();
    try {
      for (final id in ids) {
        final result = await repository.permanentlyDelete(id);
        result.fold(
          (failure) => throw Exception(failure.message),
          (_) {},
        );
      }
      invalidateDocumentLists(ref, trash: true, documentCount: true);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  // Legacy method - kept for backward compatibility but deprecated
  @Deprecated('Use moveDocumentsToTrash or permanentlyDeleteDocuments instead')
  Future<void> deleteDocuments(List<String> ids) async {
    return moveDocumentsToTrash(ids);
  }

  // Bulk duplicate documents
  Future<void> duplicateDocuments(List<String> ids) async {
    state = const AsyncLoading();
    try {
      for (final id in ids) {
        final result = await repository.duplicateDocument(id);
        result.fold(
          (failure) => throw Exception(failure.message),
          (_) {},
        );
      }
      invalidateAllDocumentLists(ref);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  // Move documents to folder (bulk)
  Future<bool> moveDocumentsToFolder(
      List<String> docIds, String? folderId) async {
    state = const AsyncLoading();
    try {
      for (final id in docIds) {
        final result = await repository.updateDocument(
          id: id,
          folderId: folderId,
        );
        result.fold(
          (failure) {
            throw Exception(failure.message);
          },
          (_) {},
        );
      }
      invalidateAllDocumentLists(ref);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}
