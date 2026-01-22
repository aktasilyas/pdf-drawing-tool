import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import 'package:example_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:example_app/features/sync/domain/usecases/toggle_auto_sync_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncRepository extends Mock implements SyncRepository {}

void main() {
  late ToggleAutoSyncUseCase useCase;
  late MockSyncRepository mockRepository;

  setUp(() {
    mockRepository = MockSyncRepository();
    useCase = ToggleAutoSyncUseCase(mockRepository);
  });

  group('ToggleAutoSyncUseCase', () {
    const tParams = ToggleAutoSyncParams(enabled: true);

    test('should enable auto sync when called with true', () async {
      // Arrange
      when(() => mockRepository.setAutoSync(true)).thenAnswer(
        (_) async => const Right(null),
      );

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRepository.setAutoSync(true)).called(1);
    });

    test('should disable auto sync when called with false', () async {
      // Arrange
      const params = ToggleAutoSyncParams(enabled: false);
      when(() => mockRepository.setAutoSync(false)).thenAnswer(
        (_) async => const Right(null),
      );

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRepository.setAutoSync(false)).called(1);
    });

    test('should return current auto sync state', () async {
      // Arrange
      when(() => mockRepository.isAutoSyncEnabled()).thenAnswer(
        (_) async => true,
      );

      // Act
      final result = await useCase.isEnabled();

      // Assert
      expect(result, true);
      verify(() => mockRepository.isAutoSyncEnabled()).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = CacheFailure('Failed to set auto sync');
      when(() => mockRepository.setAutoSync(any())).thenAnswer(
        (_) async => const Left(failure),
      );

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(failure));
    });
  });
}
