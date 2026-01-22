import 'package:example_app/features/sync/domain/entities/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncStatus', () {
    test('should have correct properties', () {
      // Arrange
      final lastSynced = DateTime(2026, 1, 22);
      const status = SyncStatus(
        state: SyncStateType.syncing,
        lastSyncedAt: null,
        pendingChanges: 5,
        errorMessage: null,
        progress: 0.5,
      );

      // Assert
      expect(status.state, SyncStateType.syncing);
      expect(status.lastSyncedAt, null);
      expect(status.pendingChanges, 5);
      expect(status.errorMessage, null);
      expect(status.progress, 0.5);
    });

    test('isSyncing should return true when state is syncing', () {
      // Arrange
      const status = SyncStatus(state: SyncStateType.syncing);

      // Assert
      expect(status.isSyncing, true);
    });

    test('hasError should return true when state is error', () {
      // Arrange
      const status = SyncStatus(
        state: SyncStateType.error,
        errorMessage: 'Test error',
      );

      // Assert
      expect(status.hasError, true);
    });

    test('isOffline should return true when state is offline', () {
      // Arrange
      const status = SyncStatus(state: SyncStateType.offline);

      // Assert
      expect(status.isOffline, true);
    });

    test('hasPendingChanges should return true when pending > 0', () {
      // Arrange
      const status = SyncStatus(
        state: SyncStateType.idle,
        pendingChanges: 3,
      );

      // Assert
      expect(status.hasPendingChanges, true);
    });

    test('hasPendingChanges should return false when pending = 0', () {
      // Arrange
      const status = SyncStatus(
        state: SyncStateType.idle,
        pendingChanges: 0,
      );

      // Assert
      expect(status.hasPendingChanges, false);
    });

    test('copyWith should update only specified fields', () {
      // Arrange
      const status = SyncStatus(
        state: SyncStateType.idle,
        pendingChanges: 5,
      );

      // Act
      final updated = status.copyWith(
        state: SyncStateType.syncing,
        progress: 0.7,
      );

      // Assert
      expect(updated.state, SyncStateType.syncing);
      expect(updated.pendingChanges, 5); // unchanged
      expect(updated.progress, 0.7);
    });

    test('should support equality', () {
      // Arrange
      const status1 = SyncStatus(
        state: SyncStateType.idle,
        pendingChanges: 5,
      );
      const status2 = SyncStatus(
        state: SyncStateType.idle,
        pendingChanges: 5,
      );
      const status3 = SyncStatus(
        state: SyncStateType.syncing,
        pendingChanges: 5,
      );

      // Assert
      expect(status1, status2);
      expect(status1, isNot(status3));
    });

    test('idle constant should have idle state', () {
      // Assert
      expect(SyncStatus.idle.state, SyncStateType.idle);
      expect(SyncStatus.idle.pendingChanges, 0);
    });

    test('offline constant should have offline state', () {
      // Assert
      expect(SyncStatus.offline.state, SyncStateType.offline);
    });
  });
}
