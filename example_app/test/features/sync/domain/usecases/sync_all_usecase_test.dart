import 'package:dartz/dartz.dart';
import 'package:example_app/core/errors/failures.dart';
import 'package:example_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:example_app/features/sync/domain/usecases/sync_all_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncRepository extends Mock implements SyncRepository {}

void main() {
  late SyncAllUseCase useCase;
  late MockSyncRepository mockRepository;

  setUp(() {
    mockRepository = MockSyncRepository();
    useCase = SyncAllUseCase(mockRepository);
  });

  group('SyncAllUseCase', () {
    test('should call syncAll on repository', () async {
      // Arrange
      when(() => mockRepository.syncAll()).thenAnswer(
        (_) async => const Right(null),
      );

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Right(null));
      verify(() => mockRepository.syncAll()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = NetworkFailure('No internet connection');
      when(() => mockRepository.syncAll()).thenAnswer(
        (_) async => const Left(failure),
      );

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.syncAll()).called(1);
    });
  });
}
