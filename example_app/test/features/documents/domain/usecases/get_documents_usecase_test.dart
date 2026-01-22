import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}

void main() {
  late GetDocumentsUseCase useCase;
  late MockDocumentRepository mockRepository;

  setUp(() {
    mockRepository = MockDocumentRepository();
    useCase = GetDocumentsUseCase(mockRepository);
  });

  group('GetDocumentsUseCase', () {
    final testDocuments = [
      DocumentInfo(
        id: 'doc-1',
        title: 'Document 1',
        templateId: 'blank',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      DocumentInfo(
        id: 'doc-2',
        title: 'Document 2',
        templateId: 'lined',
        createdAt: DateTime(2024, 1, 2),
        updatedAt: DateTime(2024, 1, 2),
      ),
    ];

    test('should return all documents when no folderId provided', () async {
      // Arrange
      when(() => mockRepository.getDocuments(folderId: null))
          .thenAnswer((_) async => Right(testDocuments));

      // Act
      final result = await useCase();

      // Assert
      expect(result, Right(testDocuments));
      verify(() => mockRepository.getDocuments(folderId: null)).called(1);
    });

    test('should return documents for specific folder', () async {
      // Arrange
      const folderId = 'folder-1';
      final folderDocuments = [testDocuments.first];
      
      when(() => mockRepository.getDocuments(folderId: folderId))
          .thenAnswer((_) async => Right(folderDocuments));

      // Act
      final result = await useCase(folderId: folderId);

      // Assert
      expect(result, Right(folderDocuments));
      verify(() => mockRepository.getDocuments(folderId: folderId)).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const failure = CacheFailure('Cache error');
      when(() => mockRepository.getDocuments(folderId: null))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.getDocuments(folderId: null)).called(1);
    });

    test('should return empty list when no documents exist', () async {
      // Arrange
      when(() => mockRepository.getDocuments(folderId: null))
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Right([]));
      result.fold(
        (_) => fail('Should return empty list'),
        (documents) => expect(documents, isEmpty),
      );
    });
  });
}
