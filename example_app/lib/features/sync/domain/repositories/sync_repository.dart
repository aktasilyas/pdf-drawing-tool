/// Sync repository interface defining synchronization operations.
///
/// This repository handles all sync-related operations including
/// syncing data, managing the sync queue, handling conflicts,
/// and monitoring connectivity.
library;

import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import '../entities/sync_status.dart';
import '../entities/sync_conflict.dart';
import '../entities/sync_queue_item.dart';

/// Repository interface for synchronization operations
abstract class SyncRepository {
  /// Sync all pending changes to remote server
  ///
  /// Returns [Either] with [Failure] on error or void on success
  Future<Either<Failure, void>> syncAll();

  /// Sync a specific document by ID
  ///
  /// [documentId] The ID of the document to sync
  /// Returns [Either] with [Failure] on error or void on success
  Future<Either<Failure, void>> syncDocument(String documentId);

  /// Get the current sync status
  ///
  /// Returns [Either] with [Failure] on error or [SyncStatus] on success
  Future<Either<Failure, SyncStatus>> getSyncStatus();

  /// Watch sync status changes as a stream
  ///
  /// Returns a stream of [SyncStatus] updates
  Stream<SyncStatus> watchSyncStatus();

  /// Get list of pending sync queue items
  ///
  /// Returns [Either] with [Failure] on error or list of items on success
  Future<Either<Failure, List<SyncQueueItem>>> getPendingItems();

  /// Add an item to the sync queue
  ///
  /// [item] The queue item to add
  /// Returns [Either] with [Failure] on error or void on success
  Future<Either<Failure, void>> addToQueue(SyncQueueItem item);

  /// Remove an item from the sync queue
  ///
  /// [itemId] The ID of the queue item to remove
  /// Returns [Either] with [Failure] on error or void on success
  Future<Either<Failure, void>> removeFromQueue(String itemId);

  /// Get list of sync conflicts
  ///
  /// Returns [Either] with [Failure] on error or list of conflicts on success
  Future<Either<Failure, List<SyncConflict>>> getConflicts();

  /// Resolve a sync conflict
  ///
  /// [documentId] The ID of the document in conflict
  /// [resolution] The resolution strategy to apply
  /// Returns [Either] with [Failure] on error or void on success
  Future<Either<Failure, void>> resolveConflict({
    required String documentId,
    required ConflictResolution resolution,
  });

  /// Check if device is currently online
  ///
  /// Returns true if online, false if offline
  Future<bool> isOnline();

  /// Watch connectivity changes as a stream
  ///
  /// Returns a stream of boolean values (true = online, false = offline)
  Stream<bool> watchConnectivity();

  /// Enable or disable automatic sync
  ///
  /// [enabled] Whether to enable auto sync
  /// Returns [Either] with [Failure] on error or void on success
  Future<Either<Failure, void>> setAutoSync(bool enabled);

  /// Check if automatic sync is enabled
  ///
  /// Returns true if auto sync is enabled, false otherwise
  Future<bool> isAutoSyncEnabled();
}
