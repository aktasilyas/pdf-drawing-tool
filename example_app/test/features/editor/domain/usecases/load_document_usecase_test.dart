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
      when(() => mockRepository.getDrawingDocument(testDocId))
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
      verify(() => mockRepository.getDrawingDocument(testDocId)).called(1);
    });

    for (final color in PaperColor.values) {
      for (final stored in {color.storageKey, color.asciiKey}) {
        test('new document with paper "$stored" opens with that colour',
            () async {
          when(() => mockRepository.getDocument(testDocId)).thenAnswer(
            (_) async => Right(testDocInfo.copyWith(paperColor: stored)),
          );
          when(() => mockRepository.getDrawingDocument(testDocId))
              .thenAnswer((_) async => const Right(null));

          final result = await useCase(testDocId);

          final document = result.getOrElse(() => throw Exception());
          expect(document.pages.last.background.color, color.argb);
        });
      }
    }

    test('engineer_pad template keeps its extraData on the new page', () async {
      when(() => mockRepository.getDocument(testDocId)).thenAnswer(
        (_) async => Right(testDocInfo.copyWith(templateId: 'engineer_pad')),
      );
      when(() => mockRepository.getDrawingDocument(testDocId))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(testDocId);

      final document = result.getOrElse(() => throw Exception());
      expect(document.pages.last.background.templateExtraData,
          {'showMarginLeft': true, 'marginMm': 25});
    });

    test('should return deserialized document when content exists', () async {
      // Arrange
      final testContent = DrawingDocument.multiPage(
        id: testDocId,
        title: 'Test Document',
        pages: [Page.create(index: 0)],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      when(() => mockRepository.getDocument(testDocId))
          .thenAnswer((_) async => Right(testDocInfo));
      when(() => mockRepository.getDrawingDocument(testDocId))
          .thenAnswer((_) async => Right(testContent));

      // Act
      final result = await useCase(testDocId);

      // Assert
      expect(result.isRight(), true);
      final document = result.getOrElse(() => throw Exception());
      expect(document.id, testDocId);
      expect(document.title, 'Test Document');

      verify(() => mockRepository.getDocument(testDocId)).called(1);
      verify(() => mockRepository.getDrawingDocument(testDocId)).called(1);
    });

    test('uses the library title when the stored content title is stale',
        () async {
      final staleContent = DrawingDocument.multiPage(
        id: testDocId,
        title: 'Old Title',
        pages: [Page.create(index: 0)],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      when(() => mockRepository.getDocument(testDocId))
          .thenAnswer((_) async => Right(testDocInfo));
      when(() => mockRepository.getDrawingDocument(testDocId))
          .thenAnswer((_) async => Right(staleContent));

      final result = await useCase(testDocId);

      final document = result.getOrElse(() => throw Exception());
      expect(document.title, 'Test Document');
    });

    test('forces the requested row id when the stored content id mismatches',
        () async {
      final copied = DrawingDocument.multiPage(
        id: 'original-id',
        title: 'Test Document',
        pages: [Page.create(index: 0)],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      when(() => mockRepository.getDocument(testDocId))
          .thenAnswer((_) async => Right(testDocInfo));
      when(() => mockRepository.getDrawingDocument(testDocId))
          .thenAnswer((_) async => Right(copied));

      final result = await useCase(testDocId);

      final document = result.getOrElse(() => throw Exception());
      expect(document.id, testDocId);
    });

    test('should return failure when document not found', () async {
      // Arrange
      when(() => mockRepository.getDocument(testDocId)).thenAnswer(
          (_) async => const Left(CacheFailure('Document not found')));

      // Act
      final result = await useCase(testDocId);

      // Assert
      expect(result.isLeft(), true);

      verify(() => mockRepository.getDocument(testDocId)).called(1);
      verifyNever(() => mockRepository.getDrawingDocument(any()));
    });

    test('should return failure when content is corrupted', () async {
      // Arrange

      when(() => mockRepository.getDocument(testDocId))
          .thenAnswer((_) async => Right(testDocInfo));
      when(() => mockRepository.getDrawingDocument(testDocId)).thenAnswer(
          (_) async => const Left(CacheFailure('Document corrupted')));

      // Act
      final result = await useCase(testDocId);

      // Assert
      expect(result.isLeft(), true);

      verify(() => mockRepository.getDocument(testDocId)).called(1);
      verify(() => mockRepository.getDrawingDocument(testDocId)).called(1);
    });
  });
}
