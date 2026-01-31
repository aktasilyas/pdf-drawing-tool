import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:drawing_core/drawing_core.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}

void main() {
  late SaveDocumentUseCase useCase;
  late MockDocumentRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRepository = MockDocumentRepository();
    useCase = SaveDocumentUseCase(mockRepository);
  });

  group('SaveDocumentUseCase', () {
    late DrawingDocument testDocument;

    setUp(() {
      testDocument = DrawingDocument.multiPage(
        id: 'test-doc-id',
        title: 'Test Document',
        pages: [Page.create(index: 0)],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('should save document content successfully', () async {
      // Arrange
      when(() => mockRepository.saveDocumentContent(
            id: any(named: 'id'),
            content: any(named: 'content'),
            pageCount: any(named: 'pageCount'),
            updatedAt: any(named: 'updatedAt'),
          )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(testDocument);

      // Assert
      expect(result.isRight(), true);
      
      verify(() => mockRepository.saveDocumentContent(
            id: testDocument.id,
            content: any(named: 'content'),
            pageCount: testDocument.pageCount,
            updatedAt: any(named: 'updatedAt'),
          )).called(1);
    });

    test('should return failure when save fails', () async {
      // Arrange
      when(() => mockRepository.saveDocumentContent(
            id: any(named: 'id'),
            content: any(named: 'content'),
            pageCount: any(named: 'pageCount'),
            updatedAt: any(named: 'updatedAt'),
          )).thenAnswer((_) async => const Left(CacheFailure('Save failed')));

      // Act
      final result = await useCase(testDocument);

      // Assert
      expect(result.isLeft(), true);
      
      verify(() => mockRepository.saveDocumentContent(
            id: any(named: 'id'),
            content: any(named: 'content'),
            pageCount: any(named: 'pageCount'),
            updatedAt: any(named: 'updatedAt'),
          )).called(1);
    });

    test('should serialize document correctly', () async {
      // Arrange
      Map<String, dynamic>? capturedContent;
      when(() => mockRepository.saveDocumentContent(
            id: any(named: 'id'),
            content: any(named: 'content'),
            pageCount: any(named: 'pageCount'),
            updatedAt: any(named: 'updatedAt'),
          )).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as Map<String, dynamic>;
        return const Right(null);
      });

      // Act
      await useCase(testDocument);

      // Assert
      expect(capturedContent, isNotNull);
      expect(capturedContent!['id'], testDocument.id);
      expect(capturedContent!['title'], testDocument.title);
      expect(capturedContent!['pages'], isA<List>());
    });
  });
}
