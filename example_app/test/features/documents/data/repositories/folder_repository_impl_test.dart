import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:example_app/features/documents/documents.dart';

class MockFolderLocalDatasource extends Mock
    implements FolderLocalDatasource {}

class MockDocumentLocalDatasource extends Mock
    implements DocumentLocalDatasource {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late FolderRepositoryImpl repository;
  late MockFolderLocalDatasource mockFolderDatasource;
  late MockDocumentLocalDatasource mockDocumentDatasource;
  late MockUuid mockUuid;

  setUp(() {
    mockFolderDatasource = MockFolderLocalDatasource();
    mockDocumentDatasource = MockDocumentLocalDatasource();
    mockUuid = MockUuid();
    repository = FolderRepositoryImpl(
      mockFolderDatasource,
      mockDocumentDatasource,
      mockUuid,
    );
  });

  group('FolderRepositoryImpl', () {
    final testModel = FolderModel(
      id: 'folder-1',
      name: 'Test Folder',
      createdAt: DateTime(2024, 1, 1),
    );

    final testModels = [
      testModel,
      FolderModel(
        id: 'folder-2',
        name: 'Test Folder 2',
        createdAt: DateTime(2024, 1, 2),
      ),
    ];

    group('getFolders', () {
      test('should return list of folders sorted by name', () async {
        // Arrange
        when(() => mockFolderDatasource.getFolders(parentId: null))
            .thenAnswer((_) async => testModels);
        when(() => mockDocumentDatasource.getAllDocuments())
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getFolders();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return folders'),
          (folders) {
            expect(folders.length, 2);
            expect(folders.first.name, 'Test Folder');
          },
        );
        verify(() => mockFolderDatasource.getFolders(parentId: null)).called(1);
        verify(() => mockDocumentDatasource.getDocuments()).called(1);
      });

      test('should filter folders by parentId', () async {
        // Arrange
        const parentId = 'parent-1';
        when(() => mockFolderDatasource.getFolders(parentId: parentId))
            .thenAnswer((_) async => [testModel]);
        when(() => mockDocumentDatasource.getAllDocuments())
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getFolders(parentId: parentId);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return folders'),
          (folders) => expect(folders.length, 1),
        );
      });
    });

    group('createFolder', () {
      const testName = 'New Folder';
      const testParentId = 'parent-1';
      const testColor = 0xFF2196F3;
      const testId = 'new-folder-id';

      test('should create folder with generated ID', () async {
        // Arrange
        when(() => mockUuid.v4()).thenReturn(testId);
        when(() => mockFolderDatasource.createFolder(any()))
            .thenAnswer((invocation) async {
          final model = invocation.positionalArguments[0] as FolderModel;
          return model;
        });

        // Act
        final result = await repository.createFolder(
          name: testName,
          parentId: testParentId,
          colorValue: testColor,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should create folder'),
          (folder) {
            expect(folder.id, testId);
            expect(folder.name, testName);
            expect(folder.parentId, testParentId);
            expect(folder.colorValue, testColor);
          },
        );
        verify(() => mockUuid.v4()).called(1);
        verify(() => mockFolderDatasource.createFolder(any())).called(1);
      });
    });

    group('moveFolder', () {
      test('should prevent circular reference', () async {
        // Arrange
        final childFolder = FolderModel(
          id: 'child',
          name: 'Child',
          parentId: 'parent',
          createdAt: DateTime.now(),
        );

        final parentFolder = FolderModel(
          id: 'parent',
          name: 'Parent',
          createdAt: DateTime.now(),
        );

        when(() => mockFolderDatasource.getFolder('child'))
            .thenAnswer((_) async => childFolder);
        when(() => mockFolderDatasource.getFolder('parent'))
            .thenAnswer((_) async => parentFolder);

        // Act - Try to move parent into its own child
        final result = await repository.moveFolder('parent', 'child');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, contains('kendi alt klasörüne taşınamaz'));
          },
          (_) => fail('Should return failure'),
        );
      });

      test('should allow moving to valid parent', () async {
        // Arrange
        final folder = FolderModel(
          id: 'folder-1',
          name: 'Folder',
          createdAt: DateTime.now(),
        );

        when(() => mockFolderDatasource.getFolder('folder-1'))
            .thenAnswer((_) async => folder);
        when(() => mockFolderDatasource.getFolder('new-parent'))
            .thenAnswer((_) async => FolderModel(
                  id: 'new-parent',
                  name: 'New Parent',
                  createdAt: DateTime.now(),
                ));
        when(() => mockFolderDatasource.updateFolder(any()))
            .thenAnswer((invocation) async {
          final model = invocation.positionalArguments[0] as FolderModel;
          return model;
        });

        // Act
        final result = await repository.moveFolder('folder-1', 'new-parent');

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('getFolderPath', () {
      test('should return breadcrumb path', () async {
        // Arrange
        final grandparent = FolderModel(
          id: 'gp',
          name: 'Grandparent',
          createdAt: DateTime.now(),
        );

        final parent = FolderModel(
          id: 'p',
          name: 'Parent',
          parentId: 'gp',
          createdAt: DateTime.now(),
        );

        final child = FolderModel(
          id: 'c',
          name: 'Child',
          parentId: 'p',
          createdAt: DateTime.now(),
        );

        when(() => mockFolderDatasource.getFolder('c'))
            .thenAnswer((_) async => child);
        when(() => mockFolderDatasource.getFolder('p'))
            .thenAnswer((_) async => parent);
        when(() => mockFolderDatasource.getFolder('gp'))
            .thenAnswer((_) async => grandparent);

        // Act
        final result = await repository.getFolderPath('c');

        // Assert
        result.fold(
          (_) => fail('Should return path'),
          (path) {
            expect(path.length, 3);
            expect(path[0].id, 'gp');
            expect(path[1].id, 'p');
            expect(path[2].id, 'c');
          },
        );
      });
    });
  });
}
