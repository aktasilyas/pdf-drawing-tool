/// Use case for getting the current synchronization status.
///
/// This use case retrieves the current sync status including whether
/// sync is in progress, pending changes count, and last sync time.
library;

import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import '../entities/sync_status.dart';
import '../repositories/sync_repository.dart';

/// Use case for getting sync status
class GetSyncStatusUseCase {
  final SyncRepository _repository;

  /// Creates a get sync status use case
  const GetSyncStatusUseCase(this._repository);

  /// Executes the use case
  ///
  /// Returns [Either] with [Failure] on error or [SyncStatus] on success
  Future<Either<Failure, SyncStatus>> call() {
    return _repository.getSyncStatus();
  }

  /// Watches sync status changes as a stream
  ///
  /// Returns a stream of [SyncStatus] updates
  Stream<SyncStatus> watch() {
    return _repository.watchSyncStatus();
  }
}
