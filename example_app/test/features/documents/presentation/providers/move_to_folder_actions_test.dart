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
    when(() => docs.moveDocument(any(), any()))
        .thenAnswer((_) async => const Right(null));
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
    // Top-level folders a and d; b and c are subfolders of a; e of d.
    final tree = [
      _f('b', parent: 'a'),
      _f('a'),
      _f('d'),
      _f('c', parent: 'a'),
      _f('e', parent: 'd'),
      _f('f'),
    ];

    List<String> ids(List<MoveTarget> targets) =>
        targets.map((t) => t.folder.id).toList();

    test('documents may go anywhere; subfolders follow their parent', () {
      final targets = MoveToFolderActions.targetsFor(tree, const []);
      expect(ids(targets), ['a', 'b', 'c', 'd', 'e', 'f']);
      expect(targets.map((t) => t.depth), [0, 1, 1, 0, 1, 0]);
    });

    test('a folder with a missing parent is listed at the top level', () {
      final targets =
          MoveToFolderActions.targetsFor([_f('x', parent: 'gone')], const []);
      expect(targets, [MoveTarget(_f('x', parent: 'gone'), 0)]);
    });

    test('a folder with subfolders can only go to the root', () {
      // Repository rule: LibraryRule.folderWithSubfoldersMove.
      expect(MoveToFolderActions.targetsFor(tree, const ['a']), isEmpty);
      expect(MoveToFolderActions.targetsFor(tree, const ['f', 'd']), isEmpty);
    });

    test('a folder without subfolders is offered top-level folders only', () {
      // Repository rule: LibraryRule.folderMoveDepth (no subfolder targets),
      // and a folder is never its own target.
      expect(
          ids(MoveToFolderActions.targetsFor(tree, const ['f'])), ['a', 'd']);
      expect(ids(MoveToFolderActions.targetsFor(tree, const ['b'])),
          ['a', 'd', 'f']);
      expect(
        MoveToFolderActions.targetsFor(tree, const ['b'])
            .every((t) => t.depth == 0),
        isTrue,
      );
    });
  });

  group('FolderMoveRules', () {
    test('a subfolder target is refused', () {
      expect(FolderMoveRules.checkTarget(targetIsSubfolder: true),
          LibraryRule.folderMoveDepth);
      expect(FolderMoveRules.checkTarget(targetIsSubfolder: false), isNull);
    });

    test('a folder with subfolders may not leave the root', () {
      expect(FolderMoveRules.checkMoved(hasSubfolders: true),
          LibraryRule.folderWithSubfoldersMove);
      expect(FolderMoveRules.checkMoved(hasSubfolders: false), isNull);
    });
  });

  group('move', () {
    test('moves documents into a folder', () async {
      final ok = await actions.move(
          documentIds: const ['d1', 'd2'],
          folderIds: const [],
          targetFolderId: 'f1');
      expect(ok, isTrue);
      verify(() => docs.moveDocument('d1', 'f1')).called(1);
      verify(() => docs.moveDocument('d2', 'f1')).called(1);
      verifyNever(() => folders.moveFolder(any(), any()));
    });

    test('moves documents to the root', () async {
      final ok = await actions.move(
          documentIds: const ['d1'], folderIds: const [], targetFolderId: null);
      expect(ok, isTrue);
      verify(() => docs.moveDocument('d1', null)).called(1);
    });

    test('moves folders under the target', () async {
      final ok = await actions.move(
          documentIds: const [], folderIds: const ['f1'], targetFolderId: 'f2');
      expect(ok, isTrue);
      verify(() => folders.moveFolder('f1', 'f2')).called(1);
    });

    test('a failed document move returns false and skips folders', () async {
      when(() => docs.moveDocument(any(), any()))
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
