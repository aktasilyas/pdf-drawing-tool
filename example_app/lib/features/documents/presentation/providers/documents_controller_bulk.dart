import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/presentation/providers/bulk_result.dart';
import 'package:example_app/features/documents/presentation/providers/documents_invalidation.dart';
import 'package:example_app/features/documents/presentation/providers/library_error.dart';

/// Bulk (multi-selection) document operations of the documents controller.
mixin DocumentsBulkOperations on StateNotifier<AsyncValue<void>> {
  @protected
  DocumentRepository get repository;

  @protected
  Ref get ref;

  /// Moves every id to the trash (soft delete); failed ids do not stop
  /// the rest and are returned in [BulkResult.failed].
  Future<BulkResult> moveDocumentsToTrash(List<String> ids) => _runBulk(
        ids,
        repository.moveToTrash,
        action: LibraryAction.trashDocuments,
        refresh: () => invalidateTrashMove(ref),
      );

  /// Permanently deletes every id (trash only); see [moveDocumentsToTrash].
  Future<BulkResult> permanentlyDeleteDocuments(List<String> ids) => _runBulk(
        ids,
        repository.permanentlyDelete,
        action: LibraryAction.deleteDocumentsForever,
        refresh: () =>
            invalidateDocumentLists(ref, trash: true, documentCount: true),
      );

  // Legacy method - kept for backward compatibility but deprecated
  @Deprecated('Use moveDocumentsToTrash or permanentlyDeleteDocuments instead')
  Future<BulkResult> deleteDocuments(List<String> ids) =>
      moveDocumentsToTrash(ids);

  /// Duplicates every id; see [moveDocumentsToTrash].
  Future<BulkResult> duplicateDocuments(
    List<String> ids, {
    required String Function(String title) copyTitle,
  }) =>
      _runBulk(
        ids,
        (id) => repository.duplicateDocument(id, copyTitle: copyTitle),
        action: LibraryAction.duplicateDocuments,
        refresh: () => invalidateAllDocumentLists(ref),
      );

  /// Applies [operation] to every id, refreshes the lists once and reports
  /// the first failure with the failed/total counts.
  Future<BulkResult> _runBulk<T>(
    List<String> ids,
    Future<Either<Failure, T>> Function(String id) operation, {
    required LibraryAction action,
    required void Function() refresh,
  }) async {
    state = const AsyncLoading();
    final succeeded = <String>[];
    final failed = <String>[];
    Failure? firstFailure;
    for (final id in ids) {
      Failure? failure;
      try {
        failure = (await operation(id)).fold((f) => f, (_) => null);
      } catch (e) {
        failure = UnknownFailure(e.toString());
      }
      if (failure == null) {
        succeeded.add(id);
      } else {
        failed.add(id);
        firstFailure ??= failure;
      }
    }
    // Successful ids changed the lists even when others failed.
    refresh();
    if (firstFailure == null) {
      state = const AsyncData(null);
    } else {
      state = AsyncError(firstFailure, StackTrace.current);
      reportLibraryFailure(
        ref,
        firstFailure,
        action,
        failedCount: failed.length,
        totalCount: ids.length,
      );
    }
    return BulkResult(succeeded: succeeded, failed: failed);
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
        final failure = result.fold((f) => f, (_) => null);
        if (failure != null) {
          state = AsyncError(failure, StackTrace.current);
          reportLibraryFailure(ref, failure, LibraryAction.moveDocuments);
          invalidateAllDocumentLists(ref);
          return false;
        }
      }
      invalidateAllDocumentLists(ref);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      reportLibraryError(ref, e, LibraryAction.moveDocuments);
      return false;
    }
  }
}
