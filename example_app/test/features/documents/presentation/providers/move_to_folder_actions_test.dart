import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/features/documents/documents.dart';

import 'documents_controller_harness.dart';

class MockFolderRepository extends Mock implements FolderRepository {}

Folder _f(String id, {String? parent}) => Folder(
      id: id,
      name: id,
      parentId: parent,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockDocumentRepository docs;
  late MockFolderRepository folders;
  late ProviderContainer container;
  late MoveToFolderActions actions;

  setUpAll(registerDocumentsFallbacks);

  setUp(() {
    docs = MockDocumentRepository();
    folders = MockFolderRepository();
    container = ProviderContainer(overrides: [
      documentRepositoryProvider.overrideWithValue(docs),
      folderRepositoryProvider.overrideWithValue(folders),
    ]);
    addTearDown(container.dispose);
    actions = container.read(moveToFolderActionsProvider);
    when(() => docs.updateDocument(
            id: any(named: 'id'), folderId: any(named: 'folderId')))
        .thenAnswer((_) async => Right(testDocument));
    when(() => folders.moveFolder(any(), any()))
        .thenAnswer((_) async => const Right(null));
    when(() => folders.getFolders(parentId: any(named: 'parentId')))
        .thenAnswer((_) async => const Right([]));
    when(() => docs.getDocuments(folderId: any(named: 'folderId')))
        .thenAnswer((_) async => const Right([]));
    when(() => docs.getFavorites()).thenAnswer((_) async => const Right([]));
    when(() => docs.getRecent(limit: any(named: 'limit')))
        .thenAnswer((_) async => const Right([]));
    when(() => docs.getTrash()).thenAnswer((_) async => const Right([]));
  });

  group('targetsFor', () {
    final tree = [
      _f('a'),
      _f('b', parent: 'a'),
      _f('c', parent: 'b'),
      _f('d'),
    ];

    test('returns everything when only documents move', () {
      expect(MoveToFolderActions.targetsFor(tree, const []), tree);
    });

    test('excludes the moved folder and all its descendants', () {
      final ids =
          MoveToFolderActions.targetsFor(tree, const ['a']).map((f) => f.id);
      expect(ids, ['d']);
    });

    test('a leaf only excludes itself', () {
      final ids =
          MoveToFolderActions.targetsFor(tree, const ['c']).map((f) => f.id);
      expect(ids, ['a', 'b', 'd']);
    });
  });

  group('move', () {
    test('moves documents into a folder', () async {
      final ok = await actions.move(
          documentIds: const ['d1', 'd2'],
          folderIds: const [],
          targetFolderId: 'f1');
      expect(ok, isTrue);
      verify(() => docs.updateDocument(id: 'd1', folderId: 'f1')).called(1);
      verify(() => docs.updateDocument(id: 'd2', folderId: 'f1')).called(1);
      verifyNever(() => folders.moveFolder(any(), any()));
    });

    test('moves documents to the root', () async {
      final ok = await actions.move(
          documentIds: const ['d1'], folderIds: const [], targetFolderId: null);
      expect(ok, isTrue);
      verify(() => docs.updateDocument(id: 'd1', folderId: null)).called(1);
    });

    test('moves folders under the target', () async {
      final ok = await actions.move(
          documentIds: const [], folderIds: const ['f1'], targetFolderId: 'f2');
      expect(ok, isTrue);
      verify(() => folders.moveFolder('f1', 'f2')).called(1);
    });

    test('a failed document move returns false and skips folders', () async {
      when(() => docs.updateDocument(
              id: any(named: 'id'), folderId: any(named: 'folderId')))
          .thenAnswer((_) async => const Left(failure));
      final ok = await actions.move(
          documentIds: const ['d1'],
          folderIds: const ['f1'],
          targetFolderId: 'f2');
      expect(ok, isFalse);
      verifyNever(() => folders.moveFolder(any(), any()));
    });

    test('a failed folder move returns false and stops', () async {
      when(() => folders.moveFolder('f1', any()))
          .thenAnswer((_) async => const Left(failure));
      final ok = await actions.move(
          documentIds: const [],
          folderIds: const ['f1', 'f3'],
          targetFolderId: null);
      expect(ok, isFalse);
      verifyNever(() => folders.moveFolder('f3', any()));
    });
  });

  group('createFolder', () {
    final created = _f('new');

    test('rejects a blank name without touching the repository', () async {
      final id = await actions.createFolder(name: '   ', colorValue: 1);
      expect(id, isNull);
      verifyNever(() => folders.createFolder(
          name: any(named: 'name'),
          parentId: any(named: 'parentId'),
          colorValue: any(named: 'colorValue')));
    });

    test('trims the name and returns the new id', () async {
      when(() => folders.createFolder(
            name: any(named: 'name'),
            parentId: any(named: 'parentId'),
            colorValue: any(named: 'colorValue'),
          )).thenAnswer((_) async => Right(created));
      final id = await actions.createFolder(
          name: '  Ders ', colorValue: 7, parentId: 'p');
      expect(id, 'new');
      verify(() =>
              folders.createFolder(name: 'Ders', parentId: 'p', colorValue: 7))
          .called(1);
    });

    test('returns null when creation fails', () async {
      when(() => folders.createFolder(
            name: any(named: 'name'),
            parentId: any(named: 'parentId'),
            colorValue: any(named: 'colorValue'),
          )).thenAnswer((_) async => const Left(failure));
      expect(await actions.createFolder(name: 'x', colorValue: 1), isNull);
    });
  });
}
