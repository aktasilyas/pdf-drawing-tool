/// Use case for syncing all pending changes to the remote server.
///
/// This use case triggers a full sync of all pending changes in the queue.
/// It should be called when the user manually requests sync or when
/// conditions are met for automatic sync.
library;

import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import '../repositories/sync_repository.dart';

/// Use case for syncing all pending changes
class SyncAllUseCase {
  final SyncRepository _repository;

  /// Creates a sync all use case
  const SyncAllUseCase(this._repository);

  /// Executes the use case
  ///
  /// Returns [Either] with [Failure] on error or void on success
  Future<Either<Failure, void>> call() {
    return _repository.syncAll();
  }
}
