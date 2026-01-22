/// Local data source for sync operations using Drift (SQLite).
///
/// This data source handles all local database operations for sync,
/// including queue management and metadata storage.
library;

import 'package:drift/drift.dart';
import 'package:example_app/core/database/app_database.dart';
import 'package:example_app/core/errors/exceptions.dart';
import '../../domain/entities/sync_queue_item.dart';
import '../models/sync_queue_model.dart';

/// Local data source for sync operations
class SyncLocalDatasource {
  final AppDatabase _db;

  /// Creates a sync local data source
  const SyncLocalDatasource(this._db);

  // ==================== Queue Operations ====================

  /// Gets all pending items in the sync queue
  Future<List<SyncQueueItem>> getPendingItems() async {
    try {
      final rows = await _db.select(_db.syncQueue).get();
      return rows.map((row) => row.toEntity()).toList();
    } catch (e) {
      throw CacheException('Failed to get pending items: $e');
    }
  }

  /// Adds an item to the sync queue
  Future<void> addToQueue(SyncQueueItem item) async {
    try {
      await _db.into(_db.syncQueue).insert(item.toCompanion());
    } catch (e) {
      throw CacheException('Failed to add item to queue: $e');
    }
  }

  /// Removes an item from the sync queue
  Future<void> removeFromQueue(String itemId) async {
    try {
      await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(itemId)))
          .go();
    } catch (e) {
      throw CacheException('Failed to remove item from queue: $e');
    }
  }

  /// Updates retry count for a queue item
  Future<void> updateRetryCount(String itemId, int count, String? error) async {
    try {
      await (_db.update(_db.syncQueue)..where((t) => t.id.equals(itemId)))
          .write(SyncQueueCompanion(
        retryCount: Value(count),
        errorMessage: Value(error),
      ));
    } catch (e) {
      throw CacheException('Failed to update retry count: $e');
    }
  }

  /// Gets count of pending items
  Future<int> getPendingCount() async {
    try {
      final query = _db.selectOnly(_db.syncQueue)
        ..addColumns([_db.syncQueue.id.count()]);
      final result = await query.getSingle();
      return result.read(_db.syncQueue.id.count()) ?? 0;
    } catch (e) {
      throw CacheException('Failed to get pending count: $e');
    }
  }

  // ==================== Metadata Operations ====================

  /// Gets a metadata value by key
  Future<String?> getMetadata(String key) async {
    try {
      final result = await (_db.select(_db.syncMetadata)
            ..where((t) => t.key.equals(key)))
          .getSingleOrNull();
      return result?.value;
    } catch (e) {
      throw CacheException('Failed to get metadata: $e');
    }
  }

  /// Sets a metadata value
  Future<void> setMetadata(String key, String value) async {
    try {
      await _db.into(_db.syncMetadata).insertOnConflictUpdate(
            SyncMetadataCompanion.insert(key: key, value: value),
          );
    } catch (e) {
      throw CacheException('Failed to set metadata: $e');
    }
  }

  /// Deletes a metadata entry
  Future<void> deleteMetadata(String key) async {
    try {
      await (_db.delete(_db.syncMetadata)..where((t) => t.key.equals(key)))
          .go();
    } catch (e) {
      throw CacheException('Failed to delete metadata: $e');
    }
  }

  // ==================== Document Sync Operations ====================

  /// Gets a single document by ID
  Future<DocumentData?> getDocument(String id) async {
    try {
      return await (_db.select(_db.documents)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
    } catch (e) {
      throw CacheException('Failed to get document: $e');
    }
  }

  /// Gets documents modified after a specific date
  Future<List<DocumentData>> getDocumentsModifiedAfter(DateTime date) async {
    try {
      return await (_db.select(_db.documents)
            ..where((t) => t.updatedAt.isBiggerThanValue(date))
            ..orderBy([(t) => OrderingTerm(expression: t.updatedAt)]))
          .get();
    } catch (e) {
      throw CacheException('Failed to get modified documents: $e');
    }
  }

  /// Updates or inserts a document
  Future<void> upsertDocument(DocumentsCompanion doc) async {
    try {
      await _db.into(_db.documents).insertOnConflictUpdate(doc);
    } catch (e) {
      throw CacheException('Failed to upsert document: $e');
    }
  }

  /// Deletes a document by ID
  Future<void> deleteDocument(String id) async {
    try {
      await (_db.delete(_db.documents)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw CacheException('Failed to delete document: $e');
    }
  }

  /// Updates document sync state
  Future<void> updateDocumentSyncState(String id, int syncState) async {
    try {
      await (_db.update(_db.documents)..where((t) => t.id.equals(id)))
          .write(DocumentsCompanion(syncState: Value(syncState)));
    } catch (e) {
      throw CacheException('Failed to update document sync state: $e');
    }
  }

  // ==================== Folder Sync Operations ====================

  /// Gets a single folder by ID
  Future<FolderData?> getFolder(String id) async {
    try {
      return await (_db.select(_db.folders)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
    } catch (e) {
      throw CacheException('Failed to get folder: $e');
    }
  }

  /// Gets folders modified after a specific date
  Future<List<FolderData>> getFoldersModifiedAfter(DateTime date) async {
    try {
      return await (_db.select(_db.folders)
            ..where((t) => t.createdAt.isBiggerThanValue(date))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();
    } catch (e) {
      throw CacheException('Failed to get modified folders: $e');
    }
  }

  /// Updates or inserts a folder
  Future<void> upsertFolder(FoldersCompanion folder) async {
    try {
      await _db.into(_db.folders).insertOnConflictUpdate(folder);
    } catch (e) {
      throw CacheException('Failed to upsert folder: $e');
    }
  }

  /// Deletes a folder by ID
  Future<void> deleteFolder(String id) async {
    try {
      await (_db.delete(_db.folders)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw CacheException('Failed to delete folder: $e');
    }
  }

  // ==================== Transaction Support ====================

  /// Executes multiple operations in a transaction
  Future<T> transaction<T>(Future<T> Function() action) async {
    try {
      return await _db.transaction(() => action());
    } catch (e) {
      throw CacheException('Transaction failed: $e');
    }
  }
}
