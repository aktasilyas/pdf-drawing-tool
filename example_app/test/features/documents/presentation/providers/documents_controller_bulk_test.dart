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
  const abc = ['a', 'b', 'c'];

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
      expect(h.container.read(libraryErrorProvider), isNull);
    });

    test('a failing middle id does not stop the rest', () async {
      when(() => h.repo.moveToTrash(any())).thenAnswer((_) async => ok);
      when(() => h.repo.moveToTrash('b')).thenAnswer((_) async => ko);
      late BulkResult result;
      final rebuilt = await h.rebuiltBy(() async {
        result = await h.controller.moveDocumentsToTrash(abc);
      });
      verify(() => h.repo.moveToTrash('a')).called(1);
      verify(() => h.repo.moveToTrash('c')).called(1);
      expect(result.succeeded, ['a', 'c']);
      expect(result.failed, ['b']);
      expect(rebuilt, trashMoveLists);
      expect(h.state.hasError, isTrue);
      final reported = h.container.read(libraryErrorProvider);
      expect(reported?.action, LibraryAction.trashDocuments);
      expect(reported?.failedCount, 1);
      expect(reported?.totalCount, 3);
    });

    test('a throwing repository counts as a failed id', () async {
      when(() => h.repo.moveToTrash(any())).thenAnswer((_) async => ok);
      when(() => h.repo.moveToTrash('a')).thenThrow(StateError('disk'));
      final result = await h.controller.moveDocumentsToTrash(abc);
      expect(result.succeeded, ['b', 'c']);
      expect(result.failed, ['a']);
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

    test('a failing middle id does not stop the rest', () async {
      when(() => h.repo.permanentlyDelete(any())).thenAnswer((_) async => ok);
      when(() => h.repo.permanentlyDelete('b')).thenAnswer((_) async => ko);
      late BulkResult result;
      final rebuilt = await h.rebuiltBy(() async {
        result = await h.controller.permanentlyDeleteDocuments(abc);
      });
      verify(() => h.repo.permanentlyDelete('a')).called(1);
      verify(() => h.repo.permanentlyDelete('c')).called(1);
      expect(result.succeeded, ['a', 'c']);
      expect(result.failed, ['b']);
      expect(rebuilt, permanentDeleteLists);
      expect(h.state.hasError, isTrue);
      final reported = h.container.read(libraryErrorProvider);
      expect(reported?.action, LibraryAction.deleteDocumentsForever);
      expect(reported?.failedCount, 1);
      expect(reported?.totalCount, 3);
    });

    test('every id failing reports all of them', () async {
      when(() => h.repo.permanentlyDelete(any())).thenAnswer((_) async => ko);
      final result = await h.controller.permanentlyDeleteDocuments(ids);
      expect(result.succeeded, isEmpty);
      expect(result.failed, ids);
      final reported = h.container.read(libraryErrorProvider);
      expect(reported?.failedCount, 2);
      expect(reported?.totalCount, 2);
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

    test('a failing middle id does not stop the rest', () async {
      when(() => h.repo
              .duplicateDocument(any(), copyTitle: any(named: 'copyTitle')))
          .thenAnswer((_) async => Right(testDocument));
      when(() =>
              h.repo.duplicateDocument('b', copyTitle: any(named: 'copyTitle')))
          .thenAnswer((_) async => const Left(failure));
      late BulkResult result;
      final rebuilt = await h.rebuiltBy(() async {
        result =
            await h.controller.duplicateDocuments(abc, copyTitle: copyTitle);
      });
      verify(() =>
              h.repo.duplicateDocument('a', copyTitle: any(named: 'copyTitle')))
          .called(1);
      verify(() =>
              h.repo.duplicateDocument('c', copyTitle: any(named: 'copyTitle')))
          .called(1);
      expect(result.succeeded, ['a', 'c']);
      expect(result.failed, ['b']);
      expect(rebuilt, allLists);
      expect(h.state.hasError, isTrue);
      final reported = h.container.read(libraryErrorProvider);
      expect(reported?.action, LibraryAction.duplicateDocuments);
      expect(reported?.failedCount, 1);
      expect(reported?.totalCount, 3);
    });
  });

  group('moveDocumentsToFolder', () {
    test('moves every id and refreshes every list', () async {
      when(() => h.repo.moveDocument(any(), 'f1')).thenAnswer((_) async => ok);
      late bool result;
      final rebuilt = await h.rebuiltBy(() async {
        result = await h.controller.moveDocumentsToFolder(ids, 'f1');
      });
      expect(result, isTrue);
      verify(() => h.repo.moveDocument('a', 'f1')).called(1);
      verify(() => h.repo.moveDocument('b', 'f1')).called(1);
      expect(rebuilt, allLists);
    });

    test('moves via moveDocument, not updateDocument (#453)', () async {
      // updateDocument stamps the edited date; filing must not.
      when(() => h.repo.moveDocument(any(), any())).thenAnswer((_) async => ok);
      await h.controller.moveDocumentsToFolder(ids, null);
      verify(() => h.repo.moveDocument('a', null)).called(1);
      verify(() => h.repo.moveDocument('b', null)).called(1);
      verifyNever(() => h.repo.updateDocument(
          id: any(named: 'id'), folderId: any(named: 'folderId')));
    });

    test('a failure returns false, reports it and refreshes', () async {
      when(() => h.repo.moveDocument(any(), 'f1')).thenAnswer((_) async => ko);
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
