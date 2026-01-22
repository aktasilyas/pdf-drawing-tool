import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}

void main() {
  late ToggleFavoriteUseCase useCase;
  late MockDocumentRepository mockRepository;

  setUp(() {
    mockRepository = MockDocumentRepository();
    useCase = ToggleFavoriteUseCase(mockRepository);
  });

  group('ToggleFavoriteUseCase', () {
    const testDocumentId = 'doc-1';

    test('should toggle favorite successfully', () async {
      // Arrange
      when(() => mockRepository.toggleFavorite(testDocumentId))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(testDocumentId);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRepository.toggleFavorite(testDocumentId)).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = CacheFailure('Failed to toggle favorite');
      when(() => mockRepository.toggleFavorite(testDocumentId))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(testDocumentId);

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.toggleFavorite(testDocumentId)).called(1);
    });
  });
}
