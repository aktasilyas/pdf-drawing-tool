/// Model class for sync queue items with database and entity conversions.
///
/// This model handles conversion between the domain entity [SyncQueueItem]
/// and database table rows.
library;

import 'package:example_app/core/database/app_database.dart';
import 'package:example_app/features/sync/domain/entities/sync_queue_item.dart';

/// Extension on SyncQueueData to convert to entity
extension SyncQueueDataX on SyncQueueData {
  /// Converts database row to domain entity
  SyncQueueItem toEntity() {
    return SyncQueueItem(
      id: id,
      entityId: entityId,
      entityType: SyncEntityType.values[entityType],
      action: SyncAction.values[action],
      createdAt: createdAt,
      retryCount: retryCount,
      errorMessage: errorMessage,
    );
  }
}

/// Extension on SyncQueueItem to convert to database companion
extension SyncQueueItemX on SyncQueueItem {
  /// Converts domain entity to database companion
  SyncQueueCompanion toCompanion() {
    return SyncQueueCompanion.insert(
      id: id,
      entityId: entityId,
      entityType: entityType.index,
      action: action.index,
      createdAt: createdAt,
      retryCount: Value(retryCount),
      errorMessage: Value(errorMessage),
    );
  }
}
