/// Sync queue item entity representing a pending synchronization operation.
///
/// Each queue item represents a single operation that needs to be synced
/// to the remote server. Items are processed in FIFO order.
library;

import 'package:equatable/equatable.dart';

/// Types of sync actions
enum SyncAction {
  /// Create a new entity
  create,

  /// Update an existing entity
  update,

  /// Delete an entity
  delete,
}

/// Types of entities that can be synced
enum SyncEntityType {
  /// Document entity
  document,

  /// Folder entity
  folder,
}

/// Represents a single item in the sync queue
class SyncQueueItem extends Equatable {
  /// Unique identifier for this queue item
  final String id;

  /// ID of the entity being synced
  final String entityId;

  /// Type of entity
  final SyncEntityType entityType;

  /// Action to perform
  final SyncAction action;

  /// When this item was added to the queue
  final DateTime createdAt;

  /// Number of retry attempts
  final int retryCount;

  /// Error message from last attempt
  final String? errorMessage;

  /// Creates a sync queue item
  const SyncQueueItem({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.action,
    required this.createdAt,
    this.retryCount = 0,
    this.errorMessage,
  });

  /// Maximum number of retry attempts before giving up
  static const int maxRetries = 3;

  /// Whether this item can be retried
  bool get canRetry => retryCount < maxRetries;

  /// Creates a copy with incremented retry count
  SyncQueueItem incrementRetry(String? error) {
    return SyncQueueItem(
      id: id,
      entityId: entityId,
      entityType: entityType,
      action: action,
      createdAt: createdAt,
      retryCount: retryCount + 1,
      errorMessage: error,
    );
  }

  @override
  List<Object?> get props => [
        id,
        entityId,
        entityType,
        action,
        createdAt,
        retryCount,
        errorMessage,
      ];
}
