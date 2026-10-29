import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

import 'documents_controller_harness.dart';

void main() {
  setUpAll(registerDocumentsFallbacks);

  late DocumentsHarness h;

  setUp(() => h = DocumentsHarness());
  tearDown(() => h.dispose());

  bool? result;

  /// Runs [action], stores its result and returns the rebuilt providers.
  Future<Set<String>> run(Future<bool> Function(DocumentsController) action) {
    return h.rebuiltBy(() async {
      result = await action(h.controller);
    });
  }

  const ok = Right<Failure, void>(null);
  const ko = Left<Failure, void>(failure);

  group('toggleFavorite', () {
    test('success refreshes documents and favorites', () async {
      when(() => h.repo.toggleFavorite('doc-1')).thenAnswer((_) async => ok);
      final rebuilt = await run((c) => c.toggleFavorite('doc-1'));
      expect(result, isTrue);
      expect(rebuilt, {'documents', 'favorites'});
    });

    test('failure returns false', () async {
      when(() => h.repo.toggleFavorite('doc-1')).thenAnswer((_) async => ko);
      final rebuilt = await run((c) => c.toggleFavorite('doc-1'));
      expect(result, isFalse);
      expect(rebuilt, isEmpty);
    });
  });

  group('moveToTrash', () {
    test('success refreshes documents, trash and folders', () async {
      when(() => h.repo.moveToTrash('doc-1')).thenAnswer((_) async => ok);
      final rebuilt = await run((c) => c.moveToTrash('doc-1'));
      expect(result, isTrue);
      expect(rebuilt, trashMoveLists);
    });

    test('failure returns false', () async {
      when(() => h.repo.moveToTrash('doc-1')).thenAnswer((_) async => ko);
      final rebuilt = await run((c) => c.moveToTrash('doc-1'));
      expect(result, isFalse);
      expect(rebuilt, isEmpty);
    });
  });

  group('deleteDocument', () {
    test('success refreshes every list', () async {
      when(() => h.repo.deleteDocument('doc-1')).thenAnswer((_) async => ok);
      final rebuilt = await run((c) => c.deleteDocument('doc-1'));
      expect(result, isTrue);
      expect(rebuilt, allLists);
    });

    test('failure returns false', () async {
      when(() => h.repo.deleteDocument('doc-1')).thenAnswer((_) async => ko);
      final rebuilt = await run((c) => c.deleteDocument('doc-1'));
      expect(result, isFalse);
      expect(rebuilt, isEmpty);
    });
  });

  group('renameDocument', () {
    void stubRename(Either<Failure, DocumentInfo> value) {
      when(() => h.repo.updateDocument(id: 'doc-1', title: 'New'))
          .thenAnswer((_) async => value);
    }

    test('success refreshes documents, favorites and recent', () async {
      stubRename(Right(testDocument));
      final rebuilt = await run((c) => c.renameDocument('doc-1', 'New'));
      expect(result, isTrue);
      expect(rebuilt, {'documents', 'favorites', 'recent'});
    });

    test('failure returns false', () async {
      stubRename(const Left(failure));
      final rebuilt = await run((c) => c.renameDocument('doc-1', 'New'));
      expect(result, isFalse);
      expect(rebuilt, isEmpty);
    });
  });

  group('restoreFromTrash', () {
    test('success refreshes documents, trash and folders', () async {
      when(() => h.repo.restoreFromTrash('doc-1')).thenAnswer((_) async => ok);
      final rebuilt = await run((c) => c.restoreFromTrash('doc-1'));
      expect(result, isTrue);
      expect(rebuilt, trashMoveLists);
    });

    test('failure returns false and exposes the failure', () async {
      when(() => h.repo.restoreFromTrash('doc-1')).thenAnswer((_) async => ko);
      final rebuilt = await run((c) => c.restoreFromTrash('doc-1'));
      expect(result, isFalse);
      expect(rebuilt, isEmpty);
      expect(h.state.error, failure);
    });

    test('a thrown error returns false', () async {
      when(() => h.repo.restoreFromTrash('doc-1')).thenThrow(StateError('x'));
      expect(await h.controller.restoreFromTrash('doc-1'), isFalse);
      expect(h.state.error, isA<StateError>());
    });
  });

  group('duplicateDocument', () {
    test('success refreshes every list', () async {
      when(() => h.repo.duplicateDocument(
            'doc-1',
            copyTitle: any(named: 'copyTitle'),
          )).thenAnswer((_) async => Right(testDocument));
      final rebuilt =
          await run((c) => c.duplicateDocument('doc-1', copyTitle: copyTitle));
      expect(result, isTrue);
      expect(rebuilt, allLists);
    });

    test('failure returns false and exposes the failure', () async {
      when(() => h.repo.duplicateDocument(
            'doc-1',
            copyTitle: any(named: 'copyTitle'),
          )).thenAnswer((_) async => const Left(failure));
      final rebuilt =
          await run((c) => c.duplicateDocument('doc-1', copyTitle: copyTitle));
      expect(result, isFalse);
      expect(rebuilt, isEmpty);
      expect(h.state.error, failure);
    });

    test('a thrown error returns false', () async {
      when(() => h.repo.duplicateDocument(
            'doc-1',
            copyTitle: any(named: 'copyTitle'),
          )).thenThrow(StateError('x'));
      expect(
          await h.controller.duplicateDocument('doc-1', copyTitle: copyTitle),
          isFalse);
      expect(h.state.error, isA<StateError>());
    });
  });

  group('permanentlyDeleteDocument', () {
    test('success refreshes trash and document counts', () async {
      when(() => h.repo.permanentlyDelete('doc-1')).thenAnswer((_) async => ok);
      final rebuilt = await run((c) => c.permanentlyDeleteDocument('doc-1'));
      expect(result, isTrue);
      expect(rebuilt, permanentDeleteLists);
    });

    test('failure returns false and exposes the failure', () async {
      when(() => h.repo.permanentlyDelete('doc-1')).thenAnswer((_) async => ko);
      final rebuilt = await run((c) => c.permanentlyDeleteDocument('doc-1'));
      expect(result, isFalse);
      expect(rebuilt, isEmpty);
      expect(h.state.error, failure);
    });

    test('a thrown error returns false', () async {
      when(() => h.repo.permanentlyDelete('doc-1')).thenThrow(StateError('x'));
      expect(await h.controller.permanentlyDeleteDocument('doc-1'), isFalse);
      expect(h.state.error, isA<StateError>());
    });
  });
}
