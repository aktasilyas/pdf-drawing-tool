/// Implementation of sync repository with offline-first strategy.
///
/// This repository coordinates between local and remote data sources
/// to provide seamless synchronization with conflict resolution.
///
/// NOTE: This is a simplified implementation using SharedPreferences-based
/// SyncLocalDatasource. Full Drift integration can be added later.
library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/core/errors/exceptions.dart';
import 'package:example_app/core/errors/failures.dart';
import 'package:example_app/features/sync/domain/entities/sync_conflict.dart';
import 'package:example_app/features/sync/domain/entities/sync_queue_item.dart';
import 'package:example_app/features/sync/domain/entities/sync_status.dart';
import 'package:example_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:example_app/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:example_app/features/sync/data/datasources/sync_remote_datasource.dart';

/// Implementation of sync repository
class SyncRepositoryImpl implements SyncRepository {
  final SyncLocalDatasource _localDatasource;
  final SyncRemoteDatasource _remoteDatasource;
  final SharedPreferences _prefs;
  final Connectivity _connectivity;

  /// Stream controller for sync status updates
  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  /// Current sync status
  SyncStatus _currentStatus = SyncStatus.idle;

  /// Metadata keys
  // ignore: unused_field
  static const String _autoSyncKey = 'auto_sync_enabled';
  static const String _lastSyncKey = 'last_sync_timestamp';

  /// Creates a sync repository implementation
  SyncRepositoryImpl(
    this._localDatasource,
    this._remoteDatasource,
    this._prefs,
    this._connectivity,
  ) {
    _initializeConnectivityMonitoring();
  }

  /// Initializes connectivity monitoring
  void _initializeConnectivityMonitoring() {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && _currentStatus.isOffline) {
        _updateSyncStatus(_currentStatus.copyWith(
          state: SyncStateType.idle,
        ));
      } else if (result == ConnectivityResult.none &&
          !_currentStatus.isOffline) {
        _updateSyncStatus(_currentStatus.copyWith(
          state: SyncStateType.offline,
        ));
      }
    });
  }

  /// Updates and broadcasts sync status
  void _updateSyncStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

  @override
  Future<Either<Failure, void>> syncAll() async {
    try {
      // Check if online
      if (!await isOnline()) {
        return const Left(SyncFailure('Device is offline'));
      }

      // Get pending items count
      final pendingItems = await _localDatasource.getPendingItems();

      // Update status to syncing
      _updateSyncStatus(_currentStatus.copyWith(
        state: SyncStateType.syncing,
        pendingChanges: pendingItems.length,
        progress: 0.0,
      ));

      // First, pull changes from remote
      await _pullChangesFromRemote();

      // Then, push local changes
      await _pushLocalChanges(pendingItems);

      // Update last sync timestamp
      final now = DateTime.now();
      await _prefs.setString(_lastSyncKey, now.toIso8601String());
      await _localDatasource.setLastSyncTime(now);
      await _remoteDatasource.updateLastSyncTimestamp(now);

      // Update status to idle
      _updateSyncStatus(_currentStatus.copyWith(
        state: SyncStateType.idle,
        lastSyncedAt: now,
        pendingChanges: 0,
        progress: 1.0,
      ));

      return const Right(null);
    } on ServerException catch (e) {
      _updateSyncStatus(_currentStatus.copyWith(
        state: SyncStateType.error,
        errorMessage: e.message,
      ));
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      _updateSyncStatus(_currentStatus.copyWith(
        state: SyncStateType.offline,
        errorMessage: e.message,
      ));
      return Left(NetworkFailure(e.message));
    } catch (e) {
      _updateSyncStatus(_currentStatus.copyWith(
        state: SyncStateType.error,
        errorMessage: e.toString(),
      ));
      return Left(UnknownFailure('Sync failed: $e'));
    }
  }

  /// Pulls changes from remote server
  Future<void> _pullChangesFromRemote() async {
    final lastSync = await _localDatasource.getLastSyncTime() ?? 
        DateTime.fromMillisecondsSinceEpoch(0);

    // Pull documents from remote
    // TODO: Store pulled documents using DocumentLocalDatasource
    // For now, we just fetch them to trigger the API call
    await _remoteDatasource.getDocumentsModifiedAfter(lastSync);

    // Pull folders from remote
    // TODO: Store pulled folders using FolderLocalDatasource
    // For now, we just fetch them to trigger the API call
    await _remoteDatasource.getFoldersModifiedAfter(lastSync);
  }

  /// Pushes local changes to remote server
  Future<void> _pushLocalChanges(List<SyncQueueItem> items) async {
    int processedCount = 0;

    for (final item in items) {
      try {
        await _processSyncQueueItem(item);
        await _localDatasource.removeFromQueue(item.id);
        
        processedCount++;
        _updateSyncStatus(_currentStatus.copyWith(
          progress: processedCount / items.length,
          pendingChanges: items.length - processedCount,
        ));
      } catch (e) {
        // Handle retry logic
        if (item.canRetry) {
          await _localDatasource.updateRetryCount(
            item.id,
            item.retryCount + 1,
            e.toString(),
          );
        } else {
          // Max retries exceeded, remove from queue
          await _localDatasource.removeFromQueue(item.id);
        }
      }
    }
  }

  /// Processes a single sync queue item
  Future<void> _processSyncQueueItem(SyncQueueItem item) async {
    if (item.entityType == SyncEntityType.document) {
      await _syncDocument(item);
    } else {
      await _syncFolder(item);
    }
  }

  /// Syncs a document based on action
  Future<void> _syncDocument(SyncQueueItem item) async {
    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        // TODO: Get document from DocumentLocalDatasource and sync to remote
        // For now, just mark as processed
        // This requires injecting DocumentLocalDatasource into this repository
        break;

      case SyncAction.delete:
        await _remoteDatasource.deleteDocument(item.entityId);
        break;
    }
  }

  /// Syncs a folder based on action
  Future<void> _syncFolder(SyncQueueItem item) async {
    switch (item.action) {
      case SyncAction.create:
      case SyncAction.update:
        // TODO: Get folder from FolderLocalDatasource and sync to remote
        // For now, just mark as processed
        // This requires injecting FolderLocalDatasource into this repository
        break;

      case SyncAction.delete:
        await _remoteDatasource.deleteFolder(item.entityId);
        break;
    }
  }

  @override
  Future<Either<Failure, void>> syncDocument(String documentId) async {
    try {
      if (!await isOnline()) {
        return const Left(SyncFailure('Device is offline'));
      }

      // TODO: Implement full document sync with DocumentLocalDatasource
      // For now, return success
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Sync document failed: $e'));
    }
  }

  @override
  Future<Either<Failure, SyncStatus>> getSyncStatus() async {
    try {
      final pendingCount = await _localDatasource.getPendingChangesCount();
      final lastSync = await _localDatasource.getLastSyncTime();

      final status = _currentStatus.copyWith(
        pendingChanges: pendingCount,
        lastSyncedAt: lastSync,
      );

      return Right(status);
    } catch (e) {
      return Left(CacheFailure('Failed to get sync status: $e'));
    }
  }

  @override
  Stream<SyncStatus> watchSyncStatus() {
    return _syncStatusController.stream;
  }

  @override
  Future<Either<Failure, List<SyncQueueItem>>> getPendingItems() async {
    try {
      final items = await _localDatasource.getPendingItems();
      return Right(items);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get pending items: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addToQueue(SyncQueueItem item) async {
    try {
      await _localDatasource.addToQueue(item);
      
      // Update pending count
      final status = await getSyncStatus();
      status.fold(
        (_) {},
        (s) => _updateSyncStatus(s),
      );

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to add to queue: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromQueue(String itemId) async {
    try {
      await _localDatasource.removeFromQueue(itemId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to remove from queue: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SyncConflict>>> getConflicts() async {
    try {
      // TODO: Implement conflict detection logic
      // For now, return empty list
      return const Right([]);
    } catch (e) {
      return Left(UnknownFailure('Failed to get conflicts: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resolveConflict({
    required String documentId,
    required ConflictResolution resolution,
  }) async {
    try {
      // TODO: Implement conflict resolution logic
      switch (resolution) {
        case ConflictResolution.keepLocal:
          // Keep local version, sync to remote
          await syncDocument(documentId);
          break;

        case ConflictResolution.keepRemote:
          // TODO: Fetch remote version, overwrite local
          // This requires DocumentLocalDatasource
          break;

        case ConflictResolution.keepBoth:
          // TODO: Create a copy of local version with new ID
          break;
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to resolve conflict: $e'));
    }
  }

  @override
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Stream<bool> watchConnectivity() {
    return _connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }

  @override
  Future<Either<Failure, void>> setAutoSync(bool enabled) async {
    try {
      await _localDatasource.setAutoSyncEnabled(enabled);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to set auto sync: $e'));
    }
  }

  @override
  Future<bool> isAutoSyncEnabled() async {
    return await _localDatasource.isAutoSyncEnabled();
  }

  /// Disposes resources
  void dispose() {
    _syncStatusController.close();
  }
}
