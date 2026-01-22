import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}

void main() {
  late SearchDocumentsUseCase useCase;
  late MockDocumentRepository mockRepository;

  setUp(() {
    mockRepository = MockDocumentRepository();
    useCase = SearchDocumentsUseCase(mockRepository);
  });

  group('SearchDocumentsUseCase', () {
    final testDocuments = [
      DocumentInfo(
        id: 'doc-1',
        title: 'Flutter Tutorial',
        templateId: 'blank',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      DocumentInfo(
        id: 'doc-2',
        title: 'Dart Programming',
        templateId: 'lined',
        createdAt: DateTime(2024, 1, 2),
        updatedAt: DateTime(2024, 1, 2),
      ),
    ];

    test('should return matching documents', () async {
      // Arrange
      const query = 'Flutter';
      when(() => mockRepository.search(query))
          .thenAnswer((_) async => Right([testDocuments.first]));

      // Act
      final result = await useCase(query);

      // Assert
      expect(result, Right([testDocuments.first]));
      verify(() => mockRepository.search(query)).called(1);
    });

    test('should return empty list when query is empty', () async {
      // Act
      final result = await useCase('');

      // Assert
      expect(result, const Right([]));
      verifyNever(() => mockRepository.search(any()));
    });

    test('should return empty list when query is whitespace', () async {
      // Act
      final result = await useCase('   ');

      // Assert
      expect(result, const Right([]));
      verifyNever(() => mockRepository.search(any()));
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const query = 'test';
      const failure = CacheFailure('Search failed');
      when(() => mockRepository.search(query))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(query);

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.search(query)).called(1);
    });

    test('should return empty list when no matches found', () async {
      // Arrange
      const query = 'nonexistent';
      when(() => mockRepository.search(query))
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase(query);

      // Assert
      expect(result, const Right([]));
      result.fold(
        (_) => fail('Should return empty list'),
        (documents) => expect(documents, isEmpty),
      );
    });
  });
}
