import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import 'package:example_app/features/sync/domain/entities/sync_status.dart';
import 'package:example_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:example_app/features/sync/domain/usecases/get_sync_status_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncRepository extends Mock implements SyncRepository {}

void main() {
  late GetSyncStatusUseCase useCase;
  late MockSyncRepository mockRepository;

  setUp(() {
    mockRepository = MockSyncRepository();
    useCase = GetSyncStatusUseCase(mockRepository);
  });

  group('GetSyncStatusUseCase', () {
    final tSyncStatus = SyncStatus(
      state: SyncStateType.idle,
      lastSyncedAt: DateTime(2026, 1, 22),
      pendingChanges: 5,
    );

    test('should get sync status from repository', () async {
      // Arrange
      when(() => mockRepository.getSyncStatus()).thenAnswer(
        (_) async => Right(tSyncStatus),
      );

      // Act
      final result = await useCase();

      // Assert
      expect(result, Right(tSyncStatus));
      verify(() => mockRepository.getSyncStatus()).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = CacheFailure('Failed to get status');
      when(() => mockRepository.getSyncStatus()).thenAnswer(
        (_) async => const Left(failure),
      );

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.getSyncStatus()).called(1);
    });

    test('should watch sync status stream', () {
      // Arrange
      final stream = Stream.value(tSyncStatus);
      when(() => mockRepository.watchSyncStatus()).thenAnswer(
        (_) => stream,
      );

      // Act
      final result = useCase.watch();

      // Assert
      expect(result, stream);
      verify(() => mockRepository.watchSyncStatus()).called(1);
    });
  });
}
