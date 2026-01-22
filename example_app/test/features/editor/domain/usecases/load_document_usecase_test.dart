import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:drawing_core/drawing_core.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}

void main() {
  late LoadDocumentUseCase useCase;
  late MockDocumentRepository mockRepository;

  setUp(() {
    mockRepository = MockDocumentRepository();
    useCase = LoadDocumentUseCase(mockRepository);
  });

  group('LoadDocumentUseCase', () {
    const testDocId = 'test-doc-id';
    final testDocInfo = DocumentInfo(
      id: testDocId,
      title: 'Test Document',
      templateId: 'blank',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      pageCount: 1,
    );

    test('should return new empty document when content is null', () async {
      // Arrange
      when(() => mockRepository.getDocument(testDocId))
          .thenAnswer((_) async => Right(testDocInfo));
      when(() => mockRepository.getDocumentContent(testDocId))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(testDocId);

      // Assert
      expect(result.isRight(), true);
      final document = result.getOrElse(() => throw Exception());
      expect(document.id, testDocId);
      expect(document.title, 'Test Document');
      expect(document.pageCount, 1);
      
      verify(() => mockRepository.getDocument(testDocId)).called(1);
      verify(() => mockRepository.getDocumentContent(testDocId)).called(1);
    });

    test('should return deserialized document when content exists', () async {
      // Arrange
      final testContent = {
        'id': testDocId,
        'title': 'Test Document',
        'pages': [
          {
            'index': 0,
            'elements': <Map<String, dynamic>>[],
          }
        ],
      };
      
      when(() => mockRepository.getDocument(testDocId))
          .thenAnswer((_) async => Right(testDocInfo));
      when(() => mockRepository.getDocumentContent(testDocId))
          .thenAnswer((_) async => Right(testContent));

      // Act
      final result = await useCase(testDocId);

      // Assert
      expect(result.isRight(), true);
      final document = result.getOrElse(() => throw Exception());
      expect(document.id, testDocId);
      expect(document.title, 'Test Document');
      
      verify(() => mockRepository.getDocument(testDocId)).called(1);
      verify(() => mockRepository.getDocumentContent(testDocId)).called(1);
    });

    test('should return failure when document not found', () async {
      // Arrange
      when(() => mockRepository.getDocument(testDocId))
          .thenAnswer((_) async => Left(CacheFailure('Document not found')));

      // Act
      final result = await useCase(testDocId);

      // Assert
      expect(result.isLeft(), true);
      
      verify(() => mockRepository.getDocument(testDocId)).called(1);
      verifyNever(() => mockRepository.getDocumentContent(any()));
    });

    test('should return failure when content is corrupted', () async {
      // Arrange
      const invalidContent = {'invalid': 'data'};
      
      when(() => mockRepository.getDocument(testDocId))
          .thenAnswer((_) async => Right(testDocInfo));
      when(() => mockRepository.getDocumentContent(testDocId))
          .thenAnswer((_) async => const Right(invalidContent));

      // Act
      final result = await useCase(testDocId);

      // Assert
      expect(result.isLeft(), true);
      
      verify(() => mockRepository.getDocument(testDocId)).called(1);
      verify(() => mockRepository.getDocumentContent(testDocId)).called(1);
    });
  });
}
