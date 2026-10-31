import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/premium/premium.dart';

import 'documents_controller_harness.dart';

void main() {
  setUpAll(registerDocumentsFallbacks);

  late MockDocumentRepository repo;
  late MockPageTrashRepository pageTrash;

  final trashedPage = TrashedPage(
    id: 'tp-1',
    pageId: 'p-1',
    sourceDocumentId: 'doc-1',
    sourceDocumentTitle: 'Notes',
    originalPageIndex: 0,
    deletedAt: DateTime(2026, 1, 3),
    pageData: const {},
  );

  ProviderContainer build({bool allowed = true}) {
    final container = ProviderContainer(overrides: [
      documentRepositoryProvider.overrideWithValue(repo),
      pageTrashRepositoryProvider.overrideWithValue(pageTrash),
      totalDocumentCountProvider.overrideWith((ref) async => 3),
      featureAccessProvider.overrideWith(
        (ref, params) => FeatureAccess(isAllowed: allowed),
      ),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    repo = MockDocumentRepository();
    pageTrash = MockPageTrashRepository();
    when(() => repo.updateDocument(
            id: any(named: 'id'), title: any(named: 'title')))
        .thenAnswer((_) async => Right(testDocument));
    when(() =>
            repo.duplicateDocument(any(), copyTitle: any(named: 'copyTitle')))
        .thenAnswer((_) async => Right(testDocument));
    when(() => repo.toggleFavorite(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => repo.moveToTrash(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => repo.restoreFromTrash(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => repo.permanentlyDelete(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => repo.getDocuments(folderId: any(named: 'folderId')))
        .thenAnswer((_) async => const Right([]));
    when(() => repo.getFavorites()).thenAnswer((_) async => const Right([]));
    when(() => repo.getRecent(limit: any(named: 'limit')))
        .thenAnswer((_) async => const Right([]));
    when(() => repo.getTrash()).thenAnswer((_) async => const Right([]));
    when(() => pageTrash.documentExists(any()))
        .thenAnswer((_) async => const Right(true));
    when(() => pageTrash.restorePageFromTrash(any()))
        .thenAnswer((_) async => const Right(true));
    when(() => pageTrash.permanentlyDeletePage(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => pageTrash.getTrashedPages())
        .thenAnswer((_) async => const Right([]));
  });

  group('rename', () {
    test('trims and saves the title', () async {
      final actions = build().read(documentMenuActionsProvider);
      expect(await actions.rename(testDocument, '  New  '), isTrue);
      verify(() => repo.updateDocument(id: 'doc-1', title: 'New')).called(1);
    });

    test('rejects a blank title without touching the repository', () async {
      final actions = build().read(documentMenuActionsProvider);
      expect(await actions.rename(testDocument, '   '), isFalse);
      verifyNever(
        () => repo.updateDocument(
            id: any(named: 'id'), title: any(named: 'title')),
      );
    });
  });

  group('duplicate', () {
    test('duplicates when under the limit', () async {
      final actions = build().read(documentMenuActionsProvider);
      final outcome =
          await actions.duplicate(testDocument, copyTitle: copyTitle);
      expect(outcome.duplicated, isTrue);
      expect(outcome.blockedBy, isNull);
      verify(() => repo.duplicateDocument(
            'doc-1',
            copyTitle: any(named: 'copyTitle'),
          )).called(1);
    });

    test('is blocked at the limit and does not duplicate', () async {
      final actions = build(allowed: false).read(documentMenuActionsProvider);
      final outcome =
          await actions.duplicate(testDocument, copyTitle: copyTitle);
      expect(outcome.duplicated, isFalse);
      expect(outcome.blockedBy, isNotNull);
      verifyNever(() =>
          repo.duplicateDocument(any(), copyTitle: any(named: 'copyTitle')));
    });

    test('reports failure', () async {
      when(() =>
              repo.duplicateDocument(any(), copyTitle: any(named: 'copyTitle')))
          .thenAnswer((_) async => const Left(failure));
      final actions = build().read(documentMenuActionsProvider);
      final outcome =
          await actions.duplicate(testDocument, copyTitle: copyTitle);
      expect(outcome.duplicated, isFalse);
      expect(outcome.blockedBy, isNull);
    });
  });

  test('favourite, trash, restore and delete forever hit the repository',
      () async {
    final actions = build().read(documentMenuActionsProvider);
    expect(await actions.toggleFavorite(testDocument), isTrue);
    expect(await actions.moveToTrash(testDocument), isTrue);
    expect(await actions.restore(testDocument), isTrue);
    expect(await actions.deleteForever(testDocument), isTrue);
    verify(() => repo.toggleFavorite('doc-1')).called(1);
    verify(() => repo.moveToTrash('doc-1')).called(1);
    verify(() => repo.restoreFromTrash('doc-1')).called(1);
    verify(() => repo.permanentlyDelete('doc-1')).called(1);
  });

  group('restorePage', () {
    test('restores when the source document exists', () async {
      final actions = build().read(documentMenuActionsProvider);
      expect(
        await actions.restorePage(trashedPage),
        PageRestoreOutcome.restored,
      );
      verify(() => pageTrash.restorePageFromTrash('tp-1')).called(1);
    });

    test('does nothing when the source document is gone', () async {
      when(() => pageTrash.documentExists(any()))
          .thenAnswer((_) async => const Right(false));
      final actions = build().read(documentMenuActionsProvider);
      expect(
        await actions.restorePage(trashedPage),
        PageRestoreOutcome.sourceMissing,
      );
      verifyNever(() => pageTrash.restorePageFromTrash(any()));
    });

    test('reports a failed restore', () async {
      when(() => pageTrash.restorePageFromTrash(any()))
          .thenAnswer((_) async => const Right(false));
      final actions = build().read(documentMenuActionsProvider);
      expect(
        await actions.restorePage(trashedPage),
        PageRestoreOutcome.failed,
      );
    });
  });

  test('deletePageForever deletes the trash entry', () async {
    final actions = build().read(documentMenuActionsProvider);
    await actions.deletePageForever(trashedPage);
    verify(() => pageTrash.permanentlyDeletePage('tp-1')).called(1);
  });

  group('changeCover', () {
    late DocumentsHarness h;
    final cover = CoverRegistry.byId('linen_sand')!;
    final withCover = testDocument.copyWith(coverId: 'linen_sage');

    setUp(() {
      h = DocumentsHarness();
      when(() => h.repo.getDocument('doc-1'))
          .thenAnswer((_) async => Right(withCover));
      when(() => h.repo.getDrawingDocument('doc-1'))
          .thenAnswer((_) async => const Right(null));
    });
    tearDown(() => h.dispose());

    test('success updates the cover and refreshes the document lists',
        () async {
      when(() => h.repo.updateCover('doc-1', 'linen_sand'))
          .thenAnswer((_) async => const Right(null));
      final actions = h.container.read(documentMenuActionsProvider);

      late bool ok;
      final rebuilt = await h.rebuiltBy(() async {
        ok = await actions.changeCover(withCover, cover);
      });

      expect(ok, isTrue);
      expect(rebuilt, {'documents', 'favorites', 'recent'});
      verify(() => h.repo.updateCover('doc-1', 'linen_sand')).called(1);
      expect(h.container.read(libraryErrorProvider), isNull);
    });

    test('failure publishes a LibraryError and refreshes nothing', () async {
      when(() => h.repo.updateCover('doc-1', 'linen_sand'))
          .thenAnswer((_) async => const Left(failure));
      final actions = h.container.read(documentMenuActionsProvider);

      late bool ok;
      final rebuilt = await h.rebuiltBy(() async {
        ok = await actions.changeCover(withCover, cover);
      });

      expect(ok, isFalse);
      expect(rebuilt, isEmpty);
      final error = h.container.read(libraryErrorProvider);
      expect(error, isNotNull);
      expect(error!.action, LibraryAction.changeCover);
      expect(error.failure, isA<Failure>());
    });
  });
}
