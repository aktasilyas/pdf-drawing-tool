/// Use case for resolving synchronization conflicts.
///
/// This use case handles conflicts that occur when the same entity
/// has been modified both locally and remotely. It applies the chosen
/// resolution strategy.
library;

import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import 'package:example_app/features/sync/domain/entities/sync_conflict.dart';
import 'package:example_app/features/sync/domain/repositories/sync_repository.dart';

/// Parameters for resolving a conflict
class ResolveConflictParams {
  /// ID of the document in conflict
  final String documentId;

  /// Resolution strategy to apply
  final ConflictResolution resolution;

  /// Creates resolve conflict parameters
  const ResolveConflictParams({
    required this.documentId,
    required this.resolution,
  });
}

/// Use case for resolving sync conflicts
class ResolveConflictUseCase {
  final SyncRepository _repository;

  /// Creates a resolve conflict use case
  const ResolveConflictUseCase(this._repository);

  /// Executes the use case
  ///
  /// [params] Parameters containing document ID and resolution strategy
  /// Returns [Either] with [Failure] on error or void on success
  Future<Either<Failure, void>> call(ResolveConflictParams params) {
    return _repository.resolveConflict(
      documentId: params.documentId,
      resolution: params.resolution,
    );
  }

  /// Gets list of current conflicts
  ///
  /// Returns [Either] with [Failure] on error or list of conflicts on success
  Future<Either<Failure, List<SyncConflict>>> getConflicts() {
    return _repository.getConflicts();
  }
}
