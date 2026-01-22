import 'package:example_app/features/sync/domain/entities/sync_queue_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncQueueItem', () {
    final tCreatedAt = DateTime(2026, 1, 22);

    test('should have correct properties', () {
      // Arrange
      final item = SyncQueueItem(
        id: 'test-id',
        entityId: 'doc-123',
        entityType: SyncEntityType.document,
        action: SyncAction.update,
        createdAt: tCreatedAt,
        retryCount: 2,
        errorMessage: 'Network error',
      );

      // Assert
      expect(item.id, 'test-id');
      expect(item.entityId, 'doc-123');
      expect(item.entityType, SyncEntityType.document);
      expect(item.action, SyncAction.update);
      expect(item.createdAt, tCreatedAt);
      expect(item.retryCount, 2);
      expect(item.errorMessage, 'Network error');
    });

    test('canRetry should return true when retry count < 3', () {
      // Arrange
      final item = SyncQueueItem(
        id: 'test-id',
        entityId: 'doc-123',
        entityType: SyncEntityType.document,
        action: SyncAction.create,
        createdAt: tCreatedAt,
        retryCount: 2,
      );

      // Assert
      expect(item.canRetry, true);
    });

    test('canRetry should return false when retry count >= 3', () {
      // Arrange
      final item = SyncQueueItem(
        id: 'test-id',
        entityId: 'doc-123',
        entityType: SyncEntityType.document,
        action: SyncAction.create,
        createdAt: tCreatedAt,
        retryCount: 3,
      );

      // Assert
      expect(item.canRetry, false);
    });

    test('incrementRetry should increase retry count', () {
      // Arrange
      final item = SyncQueueItem(
        id: 'test-id',
        entityId: 'doc-123',
        entityType: SyncEntityType.document,
        action: SyncAction.create,
        createdAt: tCreatedAt,
        retryCount: 1,
      );

      // Act
      final incremented = item.incrementRetry('Connection timeout');

      // Assert
      expect(incremented.retryCount, 2);
      expect(incremented.errorMessage, 'Connection timeout');
      expect(incremented.id, item.id); // Other fields unchanged
      expect(incremented.entityId, item.entityId);
    });

    test('should support equality', () {
      // Arrange
      final item1 = SyncQueueItem(
        id: 'test-id',
        entityId: 'doc-123',
        entityType: SyncEntityType.document,
        action: SyncAction.create,
        createdAt: tCreatedAt,
      );
      final item2 = SyncQueueItem(
        id: 'test-id',
        entityId: 'doc-123',
        entityType: SyncEntityType.document,
        action: SyncAction.create,
        createdAt: tCreatedAt,
      );
      final item3 = SyncQueueItem(
        id: 'different-id',
        entityId: 'doc-123',
        entityType: SyncEntityType.document,
        action: SyncAction.create,
        createdAt: tCreatedAt,
      );

      // Assert
      expect(item1, item2);
      expect(item1, isNot(item3));
    });

    test('maxRetries constant should be 3', () {
      // Assert
      expect(SyncQueueItem.maxRetries, 3);
    });
  });
}
