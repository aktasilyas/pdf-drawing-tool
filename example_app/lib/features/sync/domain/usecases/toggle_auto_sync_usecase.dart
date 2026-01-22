/// Use case for toggling automatic synchronization.
///
/// This use case enables or disables automatic sync. When enabled,
/// the app will automatically sync changes in the background.
library;

import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import '../repositories/sync_repository.dart';

/// Parameters for toggling auto sync
class ToggleAutoSyncParams {
  /// Whether to enable or disable auto sync
  final bool enabled;

  /// Creates toggle auto sync parameters
  const ToggleAutoSyncParams({required this.enabled});
}

/// Use case for toggling automatic sync
class ToggleAutoSyncUseCase {
  final SyncRepository _repository;

  /// Creates a toggle auto sync use case
  const ToggleAutoSyncUseCase(this._repository);

  /// Executes the use case
  ///
  /// [params] Parameters containing the enabled state
  /// Returns [Either] with [Failure] on error or void on success
  Future<Either<Failure, void>> call(ToggleAutoSyncParams params) {
    return _repository.setAutoSync(params.enabled);
  }

  /// Gets current auto sync state
  ///
  /// Returns true if auto sync is enabled, false otherwise
  Future<bool> isEnabled() {
    return _repository.isAutoSyncEnabled();
  }
}
