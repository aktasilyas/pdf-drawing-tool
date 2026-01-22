import 'package:example_app/features/sync/domain/entities/sync_status.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';
import 'package:example_app/features/sync/presentation/widgets/sync_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncStatusIndicator', () {
    testWidgets('should show synced status when idle with no pending',
        (tester) async {
      // Arrange
      const status = SyncStatus(
        state: SyncStateType.idle,
        pendingChanges: 0,
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusStreamProvider.overrideWith(
              (ref) => Stream.value(status),
            ),
            connectivityStreamProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncStatusIndicator(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.text('Güncel'), findsOneWidget);
    });

    testWidgets('should show syncing status with spinner', (tester) async {
      // Arrange
      const status = SyncStatus(
        state: SyncStateType.syncing,
        progress: 0.5,
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusStreamProvider.overrideWith(
              (ref) => Stream.value(status),
            ),
            connectivityStreamProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncStatusIndicator(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Senkronize ediliyor...'), findsOneWidget);
    });

    testWidgets('should show offline status when not connected',
        (tester) async {
      // Arrange
      const status = SyncStatus(state: SyncStateType.idle);

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusStreamProvider.overrideWith(
              (ref) => Stream.value(status),
            ),
            connectivityStreamProvider.overrideWith(
              (ref) => Stream.value(false), // Offline
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncStatusIndicator(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Çevrimdışı'), findsOneWidget);
    });

    testWidgets('should show error status', (tester) async {
      // Arrange
      const status = SyncStatus(
        state: SyncStateType.error,
        errorMessage: 'Sync failed',
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusStreamProvider.overrideWith(
              (ref) => Stream.value(status),
            ),
            connectivityStreamProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncStatusIndicator(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
      expect(find.text('Hata'), findsOneWidget);
    });

    testWidgets('should show pending changes count', (tester) async {
      // Arrange
      const status = SyncStatus(
        state: SyncStateType.idle,
        pendingChanges: 5,
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusStreamProvider.overrideWith(
              (ref) => Stream.value(status),
            ),
            connectivityStreamProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncStatusIndicator(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      expect(find.text('5 bekliyor'), findsOneWidget);
    });

    testWidgets('should hide label when showLabel is false', (tester) async {
      // Arrange
      const status = SyncStatus(
        state: SyncStateType.idle,
        pendingChanges: 0,
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusStreamProvider.overrideWith(
              (ref) => Stream.value(status),
            ),
            connectivityStreamProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncStatusIndicator(showLabel: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.text('Güncel'), findsNothing);
    });
  });
}
