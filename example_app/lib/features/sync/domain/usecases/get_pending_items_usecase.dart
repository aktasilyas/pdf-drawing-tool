/// Use case for getting pending sync queue items.
///
/// This use case retrieves all items currently in the sync queue
/// waiting to be synced to the remote server.
library;

import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import 'package:example_app/features/sync/domain/entities/sync_queue_item.dart';
import 'package:example_app/features/sync/domain/repositories/sync_repository.dart';

/// Use case for getting pending sync items
class GetPendingItemsUseCase {
  final SyncRepository _repository;

  /// Creates a get pending items use case
  const GetPendingItemsUseCase(this._repository);

  /// Executes the use case
  ///
  /// Returns [Either] with [Failure] on error or list of pending items on success
  Future<Either<Failure, List<SyncQueueItem>>> call() {
    return _repository.getPendingItems();
  }
}
