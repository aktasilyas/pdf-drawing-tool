import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/premium/premium.dart';

import '../providers/documents_controller_harness.dart';
import '../../../../helpers/l10n.dart';

/// Moving a notebook to the trash from its library menu confirms with a
/// snackbar and an Undo action (#612).
void main() {
  late MockDocumentRepository repo;
  late MockPageTrashRepository pageTrash;

  const trashedMessage = "Son Silinenler'e taşındı";
  const undoLabel = 'Geri al';

  setUp(() {
    repo = MockDocumentRepository();
    pageTrash = MockPageTrashRepository();
    when(() => repo.restoreFromTrash(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => repo.getDocuments(folderId: any(named: 'folderId')))
        .thenAnswer((_) async => const Right([]));
    when(() => repo.getFavorites()).thenAnswer((_) async => const Right([]));
    when(() => repo.getRecent(limit: any(named: 'limit')))
        .thenAnswer((_) async => const Right([]));
    when(() => repo.getTrash()).thenAnswer((_) async => const Right([]));
    when(() => pageTrash.getTrashedPages())
        .thenAnswer((_) async => const Right([]));
  });

  /// Opens the menu from a tile-like host that disappears once the notebook
  /// is trashed, as the real library tile does.
  Future<void> trashFromMenu(WidgetTester tester) async {
    final tileVisible = ValueNotifier(true);
    addTearDown(tileVisible.dispose);
    when(() => repo.moveToTrash(any())).thenAnswer((_) async {
      tileVisible.value = false;
      return const Right(null);
    });
    await _pumpHost(tester, repo, pageTrash, tileVisible);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çöpe Taşı'));
    await tester.pumpAndSettle();
  }

  testWidgets('a successful trash shows a floating snackbar with Undo',
      (tester) async {
    await trashFromMenu(tester);

    verify(() => repo.moveToTrash(testDocument.id)).called(1);
    expect(find.text('open'), findsNothing);
    expect(find.text(trashedMessage), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.persist, isFalse);
    expect(find.widgetWithText(SnackBarAction, undoLabel), findsOneWidget);
  });

  testWidgets('Undo restores the notebook', (tester) async {
    await trashFromMenu(tester);

    await tester.tap(find.text(undoLabel));
    await tester.pumpAndSettle();

    verify(() => repo.restoreFromTrash(testDocument.id)).called(1);
    expect(find.text(trashedMessage), findsNothing);
  });

  testWidgets('the snackbar dismisses itself when Undo is not used',
      (tester) async {
    await trashFromMenu(tester);

    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    expect(find.text(trashedMessage), findsNothing);
    verifyNever(() => repo.restoreFromTrash(any()));
  });

  testWidgets('a failed trash shows no success snackbar', (tester) async {
    when(() => repo.moveToTrash(any()))
        .thenAnswer((_) async => const Left(failure));
    final tileVisible = ValueNotifier(true);
    addTearDown(tileVisible.dispose);
    await _pumpHost(tester, repo, pageTrash, tileVisible);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Çöpe Taşı'));
    await tester.pumpAndSettle();

    verify(() => repo.moveToTrash(testDocument.id)).called(1);
    expect(find.text(trashedMessage), findsNothing);
    expect(find.text(undoLabel), findsNothing);
  });
}

Future<void> _pumpHost(
  WidgetTester tester,
  MockDocumentRepository repo,
  MockPageTrashRepository pageTrash,
  ValueNotifier<bool> tileVisible,
) {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
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
          body: ValueListenableBuilder<bool>(
            valueListenable: tileVisible,
            builder: (context, visible, _) => visible
                ? Consumer(
                    builder: (context, ref, _) => TextButton(
                      onPressed: () => showDocumentMenu(
                        context,
                        ref,
                        testDocument,
                        isTrash: false,
                      ),
                      child: const Text('open'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
}
