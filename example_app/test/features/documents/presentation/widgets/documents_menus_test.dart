import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/presentation/widgets/menu_tile.dart';
import 'package:example_app/features/premium/premium.dart';

import '../providers/documents_controller_harness.dart';
import '../../../../helpers/l10n.dart';

void main() {
  late MockDocumentRepository repo;
  late MockPageTrashRepository pageTrash;

  final trashedPage = TrashedPage(
    id: 'tp-1',
    pageId: 'p-1',
    sourceDocumentId: 'doc-1',
    sourceDocumentTitle: 'Notes',
    originalPageIndex: 1,
    deletedAt: DateTime(2026, 1, 3),
    pageData: const {},
  );

  setUp(() {
    repo = MockDocumentRepository();
    pageTrash = MockPageTrashRepository();
    when(() => repo.updateDocument(
          id: any(named: 'id'),
          title: any(named: 'title'),
        )).thenAnswer((_) async => Right(testDocument));
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

  Future<void> open(
    WidgetTester tester,
    void Function(BuildContext, WidgetRef) show, {
    Size size = const Size(800, 1200),
    FakeViewPadding padding = FakeViewPadding.zero,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = padding;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentRepositoryProvider.overrideWithValue(repo),
          pageTrashRepositoryProvider.overrideWithValue(pageTrash),
          totalDocumentCountProvider.overrideWith((ref) async => 0),
          foldersProvider.overrideWith((ref) async => []),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => show(context, ref),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> openDocMenu(WidgetTester tester, {bool isTrash = false}) => open(
        tester,
        (c, r) => showDocumentMenu(c, r, testDocument, isTrash: isTrash),
      );

  group('normal document menu', () {
    testWidgets('shows all actions with tiles of at least 48dp',
        (tester) async {
      await openDocMenu(tester);
      for (final label in [
        'Yeniden Adlandır',
        'Çoğalt',
        'Taşı',
        'Favorilere Ekle',
        'PDF olarak dışa aktar',
        'Çöpe Taşı',
      ]) {
        expect(find.text(label), findsOneWidget);
        final tile = find.ancestor(
          of: find.text(label),
          matching: find.byType(MenuTile),
        );
        expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets(
        'fits a landscape tablet without overflow and every action is '
        'tappable', (tester) async {
      // Pixel Tablet in landscape with a 48dp navigation bar: a sheet capped
      // at 9/16 of the height cannot hold all seven actions.
      await open(
        tester,
        (c, r) => showDocumentMenu(c, r, testDocument),
        size: const Size(1280, 800),
        padding: const FakeViewPadding(top: 24, bottom: 48),
      );
      expect(tester.takeException(), isNull);

      final trash = find.text('Çöpe Taşı');
      const viewBottom = 800 - 48.0;
      expect(tester.getRect(trash).bottom, lessThanOrEqualTo(viewBottom));
      await tester.tap(trash);
      await tester.pumpAndSettle();
      verify(() => repo.moveToTrash(testDocument.id)).called(1);
    });

    testWidgets('rename saves the new title', (tester) async {
      await openDocMenu(tester);
      await tester.tap(find.text('Yeniden Adlandır'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Renamed');
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      verify(() => repo.updateDocument(id: 'doc-1', title: 'Renamed'))
          .called(1);
    });

    testWidgets('rename dialog rejects an empty name', (tester) async {
      await openDocMenu(tester);
      await tester.tap(find.text('Yeniden Adlandır'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      verifyNever(() => repo.updateDocument(
            id: any(named: 'id'),
            title: any(named: 'title'),
          ));
    });

    testWidgets('move opens the folder dialog', (tester) async {
      await openDocMenu(tester);
      await tester.tap(find.text('Taşı'));
      await tester.pumpAndSettle();
      expect(find.byType(MoveToFolderDialog), findsOneWidget);
    });

    testWidgets('favourite and trash call the actions', (tester) async {
      await openDocMenu(tester);
      await tester.tap(find.text('Favorilere Ekle'));
      await tester.pumpAndSettle();
      verify(() => repo.toggleFavorite('doc-1')).called(1);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Çöpe Taşı'));
      await tester.pumpAndSettle();
      verify(() => repo.moveToTrash('doc-1')).called(1);
    });
  });

  group('trash document menu', () {
    testWidgets('does not offer PDF export', (tester) async {
      await openDocMenu(tester, isTrash: true);
      expect(find.text('PDF olarak dışa aktar'), findsNothing);
    });

    testWidgets('restore calls the action and confirms', (tester) async {
      await openDocMenu(tester, isTrash: true);
      await tester.tap(find.text('Kurtar'));
      await tester.pumpAndSettle();
      verify(() => repo.restoreFromTrash('doc-1')).called(1);
      expect(find.text('Belge geri yüklendi'), findsOneWidget);
    });

    testWidgets('delete forever asks first and cancel does nothing',
        (tester) async {
      await openDocMenu(tester, isTrash: true);
      await tester.tap(find.text('Kalıcı Sil'));
      await tester.pumpAndSettle();
      expect(find.text('Kalıcı Olarak Sil'), findsOneWidget);
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();
      verifyNever(() => repo.permanentlyDelete(any()));
    });

    testWidgets('delete forever confirmed deletes', (tester) async {
      await openDocMenu(tester, isTrash: true);
      await tester.tap(find.text('Kalıcı Sil'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Kalıcı Sil'));
      await tester.pumpAndSettle();
      verify(() => repo.permanentlyDelete('doc-1')).called(1);
    });
  });

  group('trashed page menu', () {
    testWidgets('shows title and restores the page', (tester) async {
      await open(tester, (c, r) => showTrashedPageMenu(c, r, trashedPage));
      expect(find.text('Notes — Sayfa 2'), findsOneWidget);
      await tester.tap(find.text('Kurtar'));
      await tester.pumpAndSettle();
      verify(() => pageTrash.restorePageFromTrash('tp-1')).called(1);
      expect(find.text('Sayfa geri yüklendi'), findsOneWidget);
    });

    testWidgets('restore reports a missing source document', (tester) async {
      when(() => pageTrash.documentExists(any()))
          .thenAnswer((_) async => const Right(false));
      await open(tester, (c, r) => showTrashedPageMenu(c, r, trashedPage));
      await tester.tap(find.text('Kurtar'));
      await tester.pumpAndSettle();
      expect(find.text('Kaynak belge bulunamadı'), findsOneWidget);
      verifyNever(() => pageTrash.restorePageFromTrash(any()));
    });

    testWidgets('delete forever cancel does nothing, confirm deletes',
        (tester) async {
      await open(tester, (c, r) => showTrashedPageMenu(c, r, trashedPage));
      await tester.tap(find.text('Kalıcı Sil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();
      verifyNever(() => pageTrash.permanentlyDeletePage(any()));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kalıcı Sil'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Kalıcı Sil'));
      await tester.pumpAndSettle();
      verify(() => pageTrash.permanentlyDeletePage('tp-1')).called(1);
    });
  });
}
