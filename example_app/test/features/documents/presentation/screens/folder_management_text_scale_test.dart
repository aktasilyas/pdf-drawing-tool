import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/screens/manage_folders_screen.dart';
import 'package:example_app/features/documents/presentation/widgets/manage_folder_list_item.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';
import 'package:example_app/l10n/l10n.dart';

import '../../../../helpers/a11y.dart';
import '../../../../helpers/font_loader.dart';
import '../../../../helpers/l10n.dart';
import 'library_fixtures.dart';

const _phone = Size(390, 844);
const _locales = [Locale('tr'), Locale('en')];

/// Folder management (manage-folders screen, move-to-folder dialog) at 1.3x
/// text scale on a phone, in Turkish and English (#333).
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
  });

  Future<AppLocalizations> pump(
    WidgetTester tester,
    Locale locale,
    Widget home, {
    List<Folder>? folders,
  }) async {
    useTextScale(tester, 1.3);
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWith((ref) => folders ?? libraryFolders),
        ],
        child: localizedApp(theme: AppTheme.light, locale: locale, home: home),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(Scaffold).first));
  }

  /// Pumps a button that opens [dialog], taps it and returns the l10n.
  Future<AppLocalizations> pumpDialog(
    WidgetTester tester,
    Locale locale,
    MoveToFolderDialog dialog,
  ) async {
    await pump(
      tester,
      locale,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => dialog,
            ),
            child: const Text('open'), // l10n-ignore
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(MoveToFolderDialog)));
  }

  for (final locale in _locales) {
    final tag = locale.languageCode;

    testWidgets('$tag: manage folders screen and item menu', (t) async {
      final l10n = await pump(t, locale, const ManageFoldersScreen());
      expect(find.text(l10n.libraryManageFolders), findsOneWidget);
      expect(find.text(l10n.libraryNewFolder), findsOneWidget);
      expectNoOverflow(t, 'manage folders');

      await t.tap(find
          .descendant(
            of: find.ancestor(
              of: find.text(libraryFolders.first.name),
              matching: find.byType(ManageFolderListItem),
            ),
            matching: find.byType(PopupMenuButton<String>),
          )
          .first);
      await t.pumpAndSettle();
      expect(find.text(l10n.libraryAddSubfolder), findsOneWidget);
      expect(find.text(l10n.libraryChangeColor), findsOneWidget);
      expectNoOverflow(t, 'folder item menu');

      await t.tap(find.text(l10n.libraryAddSubfolder));
      await t.pumpAndSettle();
      expect(
        find.text(l10n.libraryAddSubfolderTitle(libraryFolders.first.name)),
        findsOneWidget,
      );
      expectNoOverflow(t, 'add-subfolder dialog');
    });

    testWidgets('$tag: manage folders empty state', (t) async {
      final l10n = await pump(
        t,
        locale,
        const ManageFoldersScreen(),
        folders: const [],
      );
      expect(find.text(l10n.libraryNoFoldersYet), findsOneWidget);
      expect(find.text(l10n.libraryNoFoldersHint), findsOneWidget);
      expectNoOverflow(t, 'manage folders empty');
    });

    testWidgets('$tag: move-to-folder dialog with create form', (t) async {
      final l10n = await pumpDialog(
        t,
        locale,
        const MoveToFolderDialog(documentIds: ['doc-1']),
      );
      expect(find.text(l10n.libraryMoveToFolderTitle), findsOneWidget);
      expect(find.text(l10n.libraryNoFolderRoot), findsOneWidget);
      expect(find.text(l10n.commonMove), findsOneWidget);
      expectNoOverflow(t, 'move-to-folder dialog');

      await t.tap(find.text(l10n.libraryNewFolder));
      await t.pumpAndSettle();
      expect(find.text(l10n.libraryColor), findsOneWidget);
      expect(find.text(l10n.libraryFolderNameHint), findsOneWidget);
      expectNoOverflow(t, 'move-to-folder create form');
    });

    testWidgets('$tag: move-folder dialog', (t) async {
      final l10n = await pumpDialog(
        t,
        locale,
        const MoveToFolderDialog(folderIds: ['f-okuma']),
      );
      expect(find.text(l10n.libraryMoveFolderTitle), findsOneWidget);
      expect(find.text(l10n.libraryRootFolders), findsOneWidget);
      expectNoOverflow(t, 'move-folder dialog');
    });
  }
}
