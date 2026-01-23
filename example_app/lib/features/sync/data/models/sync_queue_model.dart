/// Model class for sync queue items.
///
/// Since we're using SharedPreferences-based SyncLocalDatasource,
/// the datasource handles serialization internally.
/// This file is kept for compatibility but simplified.
library;

import 'package:example_app/features/sync/domain/entities/sync_queue_item.dart';

/// Extension methods for SyncQueueItem
extension SyncQueueItemExtensions on SyncQueueItem {
  /// Converts to JSON map for SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_id': entityId,
      'entity_type': entityType.index,
      'action': action.index,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'error_message': errorMessage,
    };
  }

  /// Creates from JSON map
  static SyncQueueItem fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as String,
      entityId: json['entity_id'] as String,
      entityType: SyncEntityType.values[json['entity_type'] as int],
      action: SyncAction.values[json['action'] as int],
      createdAt: DateTime.parse(json['created_at'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
    );
  }
}
