/// Local datasource for sync operations using SharedPreferences
/// TODO: Migrate to Drift when database setup is complete
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/features/sync/sync.dart';

class SyncLocalDatasource {
  static const String _queueKey = 'sync_queue';
  static const String _metadataPrefix = 'sync_metadata_';
  static const String _lastSyncKey = 'last_sync_time';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Queue operations
  Future<List<SyncQueueItem>> getPendingItems() async {
    final prefs = await _prefs;
    final jsonList = prefs.getStringList(_queueKey) ?? [];
    return jsonList.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return SyncQueueItem(
        id: map['id'] as String,
        entityId: map['entity_id'] as String,
        entityType: SyncEntityType.values[map['entity_type'] as int],
        action: SyncAction.values[map['action'] as int],
        createdAt: DateTime.parse(map['created_at'] as String),
        retryCount: map['retry_count'] as int? ?? 0,
        errorMessage: map['error_message'] as String?,
      );
    }).toList();
  }

  Future<void> addToQueue(SyncQueueItem item) async {
    final prefs = await _prefs;
    final jsonList = prefs.getStringList(_queueKey) ?? [];
    
    final itemJson = jsonEncode({
      'id': item.id,
      'entity_id': item.entityId,
      'entity_type': item.entityType.index,
      'action': item.action.index,
      'created_at': item.createdAt.toIso8601String(),
      'retry_count': item.retryCount,
      'error_message': item.errorMessage,
    });
    
    jsonList.add(itemJson);
    await prefs.setStringList(_queueKey, jsonList);
  }

  Future<void> removeFromQueue(String itemId) async {
    final prefs = await _prefs;
    final jsonList = prefs.getStringList(_queueKey) ?? [];
    
    jsonList.removeWhere((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map['id'] == itemId;
    });
    
    await prefs.setStringList(_queueKey, jsonList);
  }

  Future<void> updateRetryCount(String itemId, int count, String? error) async {
    final prefs = await _prefs;
    final jsonList = prefs.getStringList(_queueKey) ?? [];
    
    final updatedList = jsonList.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (map['id'] == itemId) {
        map['retry_count'] = count;
        map['error_message'] = error;
        return jsonEncode(map);
      }
      return json;
    }).toList();
    
    await prefs.setStringList(_queueKey, updatedList);
  }

  Future<void> clearQueue() async {
    final prefs = await _prefs;
    await prefs.remove(_queueKey);
  }

  // Metadata operations
  Future<String?> getMetadata(String key) async {
    final prefs = await _prefs;
    return prefs.getString('$_metadataPrefix$key');
  }

  Future<void> setMetadata(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString('$_metadataPrefix$key', value);
  }

  Future<void> removeMetadata(String key) async {
    final prefs = await _prefs;
    await prefs.remove('$_metadataPrefix$key');
  }

  // Last sync time
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await _prefs;
    final timestamp = prefs.getString(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.parse(timestamp);
  }

  Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await _prefs;
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  // Pending changes count
  Future<int> getPendingChangesCount() async {
    final items = await getPendingItems();
    return items.length;
  }

  // Auto sync setting
  Future<bool> isAutoSyncEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool('auto_sync_enabled') ?? true;
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool('auto_sync_enabled', enabled);
  }
}
