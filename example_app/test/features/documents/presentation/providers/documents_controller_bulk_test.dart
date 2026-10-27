import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

import 'documents_controller_harness.dart';

void main() {
  setUpAll(registerDocumentsFallbacks);

  late DocumentsHarness h;

  setUp(() => h = DocumentsHarness());
  tearDown(() => h.dispose());

  const ok = Right<Failure, void>(null);
  const ko = Left<Failure, void>(failure);
  const ids = ['a', 'b'];

  group('moveDocumentsToTrash', () {
    test('trashes every id and refreshes documents, trash, folders', () async {
      when(() => h.repo.moveToTrash(any())).thenAnswer((_) async => ok);
      final rebuilt = await h.rebuiltBy(() async {
        await h.controller.moveDocumentsToTrash(ids);
      });
      verify(() => h.repo.moveToTrash('a')).called(1);
      verify(() => h.repo.moveToTrash('b')).called(1);
      expect(rebuilt, trashMoveLists);
      expect(h.state, const AsyncData<void>(null));
    });

    test('a failure stops, sets the error and rethrows', () async {
      when(() => h.repo.moveToTrash('a')).thenAnswer((_) async => ko);
      await expectLater(
        h.controller.moveDocumentsToTrash(ids),
        throwsA(isA<Exception>()),
      );
      verifyNever(() => h.repo.moveToTrash('b'));
      expect(h.state.hasError, isTrue);
    });

    test('deprecated deleteDocuments moves to trash', () async {
      when(() => h.repo.moveToTrash(any())).thenAnswer((_) async => ok);
      // ignore: deprecated_member_use_from_same_package
      await h.controller.deleteDocuments(ids);
      verify(() => h.repo.moveToTrash(any())).called(2);
    });
  });

  group('permanentlyDeleteDocuments', () {
    test('deletes every id and refreshes trash and counts', () async {
      when(() => h.repo.permanentlyDelete(any())).thenAnswer((_) async => ok);
      final rebuilt = await h.rebuiltBy(() async {
        await h.controller.permanentlyDeleteDocuments(ids);
      });
      verify(() => h.repo.permanentlyDelete(any())).called(2);
      expect(rebuilt, permanentDeleteLists);
    });

    test('a failure sets the error and rethrows', () async {
      when(() => h.repo.permanentlyDelete(any())).thenAnswer((_) async => ko);
      await expectLater(
        h.controller.permanentlyDeleteDocuments(ids),
        throwsA(isA<Exception>()),
      );
      expect(h.state.hasError, isTrue);
      final reported = h.container.read(libraryErrorProvider);
      expect(reported?.action, LibraryAction.deleteDocumentsForever);
    });
  });

  group('duplicateDocuments', () {
    test('duplicates every id and refreshes every list', () async {
      when(() => h.repo
              .duplicateDocument(any(), copyTitle: any(named: 'copyTitle')))
          .thenAnswer((_) async => Right(testDocument));
      final rebuilt = await h.rebuiltBy(() async {
        await h.controller.duplicateDocuments(ids, copyTitle: copyTitle);
      });
      verify(() => h.repo.duplicateDocument(any(),
          copyTitle: any(named: 'copyTitle'))).called(2);
      expect(rebuilt, allLists);
    });

    test('a failure sets the error and rethrows', () async {
      when(() => h.repo
              .duplicateDocument(any(), copyTitle: any(named: 'copyTitle')))
          .thenAnswer((_) async => const Left(failure));
      await expectLater(
        h.controller.duplicateDocuments(ids, copyTitle: copyTitle),
        throwsA(isA<Exception>()),
      );
      expect(h.state.hasError, isTrue);
    });
  });

  group('moveDocumentsToFolder', () {
    test('moves every id and refreshes every list', () async {
      when(() => h.repo.updateDocument(id: any(named: 'id'), folderId: 'f1'))
          .thenAnswer((_) async => Right(testDocument));
      late bool result;
      final rebuilt = await h.rebuiltBy(() async {
        result = await h.controller.moveDocumentsToFolder(ids, 'f1');
      });
      expect(result, isTrue);
      verify(() => h.repo.updateDocument(id: 'a', folderId: 'f1')).called(1);
      verify(() => h.repo.updateDocument(id: 'b', folderId: 'f1')).called(1);
      expect(rebuilt, allLists);
    });

    test('a failure returns false, reports it and refreshes', () async {
      when(() => h.repo.updateDocument(id: any(named: 'id'), folderId: 'f1'))
          .thenAnswer((_) async => const Left(failure));
      late bool result;
      final rebuilt = await h.rebuiltBy(() async {
        result = await h.controller.moveDocumentsToFolder(ids, 'f1');
      });
      expect(result, isFalse);
      // Earlier ids may have moved, so every list is refreshed.
      expect(rebuilt, allLists);
      expect(h.state.hasError, isTrue);
      final reported = h.container.read(libraryErrorProvider);
      expect(reported?.action, LibraryAction.moveDocuments);
    });
  });
}
