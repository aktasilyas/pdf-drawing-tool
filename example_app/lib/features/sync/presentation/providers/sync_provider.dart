/// Riverpod providers for sync feature.
///
/// This file contains all providers related to synchronization,
/// including sync status, connectivity, and sync operations.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:example_app/features/sync/domain/entities/sync_conflict.dart';
import 'package:example_app/features/sync/domain/entities/sync_queue_item.dart';
import 'package:example_app/features/sync/domain/entities/sync_status.dart';
import 'package:example_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:example_app/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:example_app/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:example_app/features/sync/data/repositories/sync_repository_impl.dart';

// ==================== Infrastructure Providers ====================

/// App database provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Shared preferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// Connectivity provider
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

// ==================== Datasource Providers ====================

/// Sync local datasource provider
final syncLocalDatasourceProvider = Provider<SyncLocalDatasource>((ref) {
  // SyncLocalDatasource now uses SharedPreferences internally
  return SyncLocalDatasource();
});

/// Sync remote datasource provider
final syncRemoteDatasourceProvider = Provider<SyncRemoteDatasource>((ref) {
  final client = Supabase.instance.client;
  return SyncRemoteDatasource(client);
});

// ==================== Repository Provider ====================

/// Sync repository provider
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final localDatasource = ref.watch(syncLocalDatasourceProvider);
  final remoteDatasource = ref.watch(syncRemoteDatasourceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final connectivity = ref.watch(connectivityProvider);

  return SyncRepositoryImpl(
    localDatasource,
    remoteDatasource,
    prefs,
    connectivity,
  );
});

// ==================== Connectivity Stream Provider ====================

/// Watches connectivity changes
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  return repository.watchConnectivity();
});

/// Current online status
final isOnlineProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(syncRepositoryProvider);
  return repository.isOnline();
});

// ==================== Sync Status Providers ====================

/// Sync status stream provider
final syncStatusStreamProvider = StreamProvider<SyncStatus>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  return repository.watchSyncStatus();
});

/// Current sync status provider
final syncStatusProvider = FutureProvider<SyncStatus>((ref) async {
  final repository = ref.watch(syncRepositoryProvider);
  final result = await repository.getSyncStatus();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (status) => status,
  );
});

// ==================== Pending Items Providers ====================

/// Pending sync items provider
final pendingItemsProvider = FutureProvider<List<SyncQueueItem>>((ref) async {
  final repository = ref.watch(syncRepositoryProvider);
  final result = await repository.getPendingItems();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (items) => items,
  );
});

/// Pending items count provider
final pendingCountProvider = FutureProvider<int>((ref) async {
  final items = await ref.watch(pendingItemsProvider.future);
  return items.length;
});

// ==================== Sync Conflicts Provider ====================

/// Sync conflicts provider
final syncConflictsProvider = FutureProvider<List<SyncConflict>>((ref) async {
  final repository = ref.watch(syncRepositoryProvider);
  final result = await repository.getConflicts();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (conflicts) => conflicts,
  );
});

// ==================== Auto Sync Provider ====================

/// Auto sync enabled provider
final autoSyncEnabledProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(syncRepositoryProvider);
  return repository.isAutoSyncEnabled();
});

// ==================== Sync Controller ====================

/// Sync controller for triggering sync operations
class SyncController extends StateNotifier<AsyncValue<void>> {
  final SyncRepository _repository;

  SyncController(this._repository) : super(const AsyncData(null));

  /// Triggers a full sync
  Future<void> syncAll() async {
    state = const AsyncLoading();
    
    final result = await _repository.syncAll();
    
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  /// Syncs a specific document
  Future<void> syncDocument(String documentId) async {
    state = const AsyncLoading();
    
    final result = await _repository.syncDocument(documentId);
    
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  /// Toggles auto sync
  Future<void> toggleAutoSync(bool enabled) async {
    final result = await _repository.setAutoSync(enabled);
    
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) {},
    );
  }

  /// Resolves a sync conflict
  Future<void> resolveConflict({
    required String documentId,
    required ConflictResolution resolution,
  }) async {
    state = const AsyncLoading();
    
    final result = await _repository.resolveConflict(
      documentId: documentId,
      resolution: resolution,
    );
    
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}

/// Sync controller provider
final syncControllerProvider =
    StateNotifierProvider<SyncController, AsyncValue<void>>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  return SyncController(repository);
});
