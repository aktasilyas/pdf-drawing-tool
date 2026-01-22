/// Use case for syncing a specific document to the remote server.
///
/// This use case triggers sync for a single document. It's useful when
/// the user wants to ensure a specific document is synced immediately.
library;

import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import '../repositories/sync_repository.dart';

/// Parameters for syncing a document
class SyncDocumentParams {
  /// ID of the document to sync
  final String documentId;

  /// Creates sync document parameters
  const SyncDocumentParams({required this.documentId});
}

/// Use case for syncing a specific document
class SyncDocumentUseCase {
  final SyncRepository _repository;

  /// Creates a sync document use case
  const SyncDocumentUseCase(this._repository);

  /// Executes the use case
  ///
  /// [params] Parameters containing the document ID to sync
  /// Returns [Either] with [Failure] on error or void on success
  Future<Either<Failure, void>> call(SyncDocumentParams params) {
    return _repository.syncDocument(params.documentId);
  }
}
