/// Sync status entity representing the current state of synchronization.
///
/// This entity holds information about the sync state, including whether
/// sync is in progress, when the last sync occurred, how many changes are
/// pending, and any error messages.
library;

import 'package:equatable/equatable.dart';

/// Types of sync states
enum SyncStateType {
  /// Idle state - not syncing
  idle,

  /// Currently syncing
  syncing,

  /// Error occurred during sync
  error,

  /// Device is offline
  offline,
}

/// Represents the current synchronization status
class SyncStatus extends Equatable {
  /// Current state of sync
  final SyncStateType state;

  /// When the last successful sync occurred
  final DateTime? lastSyncedAt;

  /// Number of pending changes to sync
  final int pendingChanges;

  /// Error message if state is error
  final String? errorMessage;

  /// Progress of current sync operation (0.0 - 1.0)
  final double? progress;

  /// Creates a sync status
  const SyncStatus({
    required this.state,
    this.lastSyncedAt,
    this.pendingChanges = 0,
    this.errorMessage,
    this.progress,
  });

  /// Whether sync is currently in progress
  bool get isSyncing => state == SyncStateType.syncing;

  /// Whether an error occurred
  bool get hasError => state == SyncStateType.error;

  /// Whether device is offline
  bool get isOffline => state == SyncStateType.offline;

  /// Whether there are pending changes to sync
  bool get hasPendingChanges => pendingChanges > 0;

  /// Default idle state
  static const SyncStatus idle = SyncStatus(state: SyncStateType.idle);

  /// Default offline state
  static const SyncStatus offline = SyncStatus(state: SyncStateType.offline);

  /// Creates a copy with updated fields
  SyncStatus copyWith({
    SyncStateType? state,
    DateTime? lastSyncedAt,
    int? pendingChanges,
    String? errorMessage,
    double? progress,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [
        state,
        lastSyncedAt,
        pendingChanges,
        errorMessage,
        progress,
      ];
}
