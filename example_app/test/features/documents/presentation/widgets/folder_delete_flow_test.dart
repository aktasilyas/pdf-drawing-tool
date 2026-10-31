import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/l10n/l10n.dart';

import '../../../../helpers/l10n.dart';

class _MockFolderRepository extends Mock implements FolderRepository {}

Folder _folder({int documents = 3}) => Folder(
      id: 'f1',
      name: 'Ders',
      colorValue: 0xFF2196F3,
      createdAt: DateTime(2026, 1, 1),
      documentCount: documents,
    );

/// Deleting a folder says its notes move to Recently deleted, in the library
/// folder menu and in Manage Folders alike (#615).
void main() {
  late _MockFolderRepository repo;

  setUp(() {
    repo = _MockFolderRepository();
    when(() => repo.deleteFolder(any())).thenAnswer((_) async => const Right(3));
  });

  Future<void> pump(WidgetTester tester, Widget home,
      {Locale locale = const Locale('en'), List<Folder>? folders}) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          folderRepositoryProvider.overrideWithValue(repo),
          if (folders != null) foldersProvider.overrideWith((ref) => folders),
        ],
        child: localizedApp(theme: AppTheme.light, locale: locale, home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the library folder menu for [folder] and taps Delete.
  Future<void> openLibraryDelete(
    WidgetTester tester,
    Folder folder, {
    Locale locale = const Locale('en'),
    VoidCallback? onDeleted,
  }) async {
    await pump(
      tester,
      Scaffold(
        body: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () =>
                showFolderMenu(context, ref, folder, onDeleted: onDeleted),
            child: const Text('open'), // l10n-ignore
          ),
        ),
      ),
      locale: locale,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.text('open')));
    await tester.tap(find.text(l10n.commonDelete));
    await tester.pumpAndSettle();
  }

  group('library folder menu', () {
    testWidgets('says the notes, subfolders included, go to Recently deleted',
        (tester) async {
      await openLibraryDelete(tester, _folder());
      expect(
        find.text('Delete the folder "Ders"? The 3 notes inside it '
            '(subfolders included) will be moved to Recently deleted, '
            'where you can restore them.'),
        findsOneWidget,
      );
      expect(find.textContaining('also deletes'), findsNothing);
    });

    testWidgets('Turkish copy says Son Silinenler, not that notes are deleted',
        (tester) async {
      await openLibraryDelete(tester, _folder(), locale: const Locale('tr'));
      expect(
        find.text('"Ders" klasörü silinsin mi? İçindeki 3 not (alt klasörler '
            "dahil) Son Silinenler'e taşınacak; oradan geri yükleyebilirsiniz."),
        findsOneWidget,
      );
      expect(find.textContaining('belgelerini de siler'), findsNothing);
    });

    testWidgets('an empty folder gets a plain question', (tester) async {
      await openLibraryDelete(tester, _folder(documents: 0));
      expect(find.text('Delete the folder "Ders"?'), findsOneWidget);
    });

    testWidgets('confirming deletes and reports how many notes were trashed',
        (tester) async {
      var deleted = false;
      await openLibraryDelete(tester, _folder(),
          onDeleted: () => deleted = true);
      await tester.tap(find.widgetWithText(AppButton, 'Delete'));
      await tester.pumpAndSettle();
      verify(() => repo.deleteFolder('f1')).called(1);
      expect(deleted, isTrue);
      expect(
        find.text('Folder deleted. 3 notes moved to Recently deleted'),
        findsOneWidget,
      );
    });

    testWidgets('no count in the toast when nothing was trashed',
        (tester) async {
      when(() => repo.deleteFolder(any()))
          .thenAnswer((_) async => const Right(0));
      await openLibraryDelete(tester, _folder(documents: 0));
      await tester.tap(find.widgetWithText(AppButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Folder deleted'), findsOneWidget);
    });

    testWidgets('cancel keeps the folder', (tester) async {
      await openLibraryDelete(tester, _folder());
      await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => repo.deleteFolder(any()));
    });
  });

  testWidgets('Manage Folders uses the same wording', (tester) async {
    await pump(tester, const ManageFoldersScreen(), folders: [_folder()]);
    await tester.tap(find.descendant(
      of: find.byType(ManageFolderListItem),
      matching: find.byType(PopupMenuButton<String>),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    expect(find.text(l10n.libraryDeleteFolderConfirm('Ders', 3)), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Delete'));
    await tester.pumpAndSettle();
    verify(() => repo.deleteFolder('f1')).called(1);
    expect(
      find.text('Folder deleted. 3 notes moved to Recently deleted'),
      findsOneWidget,
    );
  });
}
