import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:example_app/features/documents/documents.dart';

class MockDocumentLocalDatasource extends Mock
    implements DocumentLocalDatasource {}

class MockFolderLocalDatasource extends Mock
    implements FolderLocalDatasource {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late DocumentRepositoryImpl repository;
  late MockDocumentLocalDatasource mockDatasource;
  late MockFolderLocalDatasource mockFolderDatasource;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(DocumentModel(
      id: '',
      title: '',
      templateId: '',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));
  });

  setUp(() {
    mockDatasource = MockDocumentLocalDatasource();
    mockFolderDatasource = MockFolderLocalDatasource();
    mockUuid = MockUuid();
    repository = DocumentRepositoryImpl(
      mockDatasource,
      mockFolderDatasource,
      mockUuid,
    );
  });

  group('DocumentRepositoryImpl', () {
    final testModel = DocumentModel(
      id: 'doc-1',
      title: 'Test Document',
      templateId: 'blank',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    final testModels = [
      testModel,
      DocumentModel(
        id: 'doc-2',
        title: 'Test Document 2',
        templateId: 'lined',
        createdAt: DateTime(2024, 1, 2),
        updatedAt: DateTime(2024, 1, 2),
      ),
    ];

    group('getDocuments', () {
      test('should return list of documents excluding trash', () async {
        // Arrange
        when(() => mockDatasource.getDocuments(folderId: null))
            .thenAnswer((_) async => testModels);

        // Act
        final result = await repository.getDocuments();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return documents'),
          (documents) {
            expect(documents.length, 2);
            expect(documents.first.id, 'doc-1');
          },
        );
        verify(() => mockDatasource.getDocuments(folderId: null)).called(1);
      });

      test('should filter documents by folderId', () async {
        // Arrange
        const folderId = 'folder-1';
        when(() => mockDatasource.getDocuments(folderId: folderId))
            .thenAnswer((_) async => [testModel]);

        // Act
        final result = await repository.getDocuments(folderId: folderId);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return documents'),
          (documents) => expect(documents.length, 1),
        );
      });

      test('should exclude documents in trash', () async {
        // Arrange
        final modelsWithTrash = [
          testModel,
          DocumentModel(
            id: 'trash-1',
            title: 'Trash Doc',
            templateId: 'blank',
            isInTrash: true,
            createdAt: DateTime(2024, 1, 3),
            updatedAt: DateTime(2024, 1, 3),
          ),
        ];

        when(() => mockDatasource.getDocuments(folderId: null))
            .thenAnswer((_) async => modelsWithTrash);

        // Act
        final result = await repository.getDocuments();

        // Assert
        result.fold(
          (_) => fail('Should return documents'),
          (documents) {
            expect(documents.length, 1);
            expect(documents.first.isInTrash, false);
          },
        );
      });

      test('should return failure when datasource throws exception', () async {
        // Arrange
        when(() => mockDatasource.getDocuments(folderId: null))
            .thenThrow(Exception('Cache error'));

        // Act
        final result = await repository.getDocuments();

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('createDocument', () {
      const testTitle = 'New Document';
      const testTemplateId = 'blank';
      const testFolderId = 'folder-1';
      const testId = 'new-doc-id';

      test('should create document with generated ID', () async {
        // Arrange
        when(() => mockUuid.v4()).thenReturn(testId);
        when(() => mockDatasource.createDocument(any()))
            .thenAnswer((invocation) async {
          final model = invocation.positionalArguments[0] as DocumentModel;
          return model;
        });

        // Act
        final result = await repository.createDocument(
          title: testTitle,
          templateId: testTemplateId,
          folderId: testFolderId,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should create document'),
          (document) {
            expect(document.id, testId);
            expect(document.title, testTitle);
            expect(document.templateId, testTemplateId);
            expect(document.folderId, testFolderId);
          },
        );
        verify(() => mockUuid.v4()).called(1);
        verify(() => mockDatasource.createDocument(any())).called(1);
      });
    });

    group('toggleFavorite', () {
      test('should toggle favorite status', () async {
        // Arrange
        when(() => mockDatasource.getDocument('doc-1'))
            .thenAnswer((_) async => testModel);
        when(() => mockDatasource.updateDocument(any()))
            .thenAnswer((invocation) async {
          final model = invocation.positionalArguments[0] as DocumentModel;
          return model;
        });

        // Act
        final result = await repository.toggleFavorite('doc-1');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDatasource.getDocument('doc-1')).called(1);
        verify(() => mockDatasource.updateDocument(any())).called(1);
      });
    });

    group('search', () {
      test('should return matching documents', () async {
        // Arrange
        when(() => mockDatasource.getAllDocuments())
            .thenAnswer((_) async => testModels);

        // Act
        final result = await repository.search('Test');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return documents'),
          (documents) => expect(documents.length, 2),
        );
      });

      test('should be case-insensitive', () async {
        // Arrange
        when(() => mockDatasource.getAllDocuments())
            .thenAnswer((_) async => testModels);

        // Act
        final result = await repository.search('test');

        // Assert
        result.fold(
          (_) => fail('Should return documents'),
          (documents) => expect(documents.length, 2),
        );
      });
    });

    group('moveToTrash', () {
      test('should mark document as in trash', () async {
        // Arrange
        when(() => mockDatasource.getDocument('doc-1'))
            .thenAnswer((_) async => testModel);
        when(() => mockDatasource.updateDocument(any()))
            .thenAnswer((invocation) async {
          final model = invocation.positionalArguments[0] as DocumentModel;
          return model;
        });

        // Act
        final result = await repository.moveToTrash('doc-1');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDatasource.getDocument('doc-1')).called(1);
        verify(() => mockDatasource.updateDocument(any())).called(1);
      });
    });

    group('getTrash', () {
      test('should return only documents in trash', () async {
        // Arrange
        final modelsWithTrash = [
          testModel,
          DocumentModel(
            id: 'trash-1',
            title: 'Trash Doc',
            templateId: 'blank',
            isInTrash: true,
            createdAt: DateTime(2024, 1, 3),
            updatedAt: DateTime(2024, 1, 3),
          ),
        ];

        when(() => mockDatasource.getAllDocuments())
            .thenAnswer((_) async => modelsWithTrash);

        // Act
        final result = await repository.getTrash();

        // Assert
        result.fold(
          (_) => fail('Should return trash documents'),
          (documents) {
            expect(documents.length, 1);
            expect(documents.first.isInTrash, true);
          },
        );
      });
    });
  });
}
