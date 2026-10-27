import 'package:drawing_ui/drawing_ui.dart'
    show CoverTextureStore, ElyanotesIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/constants/storage_keys.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/screens/documents_screen.dart';
import 'package:example_app/l10n/l10n.dart';

import '../../../../helpers/a11y.dart';
import '../../../../helpers/font_loader.dart';
import '../../../../helpers/l10n.dart';
import 'library_fixtures.dart';

const _phone = Size(390, 844);
const _locales = [Locale('tr'), Locale('en')];

/// Library chrome at 1.3x text scale on a phone, in Turkish and English
/// (#201): long Turkish words and English copy must both fit.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    await loadManifestFonts();
    await CoverTextureStore.ensureLoaded();
  });

  Future<AppLocalizations> pump(
    WidgetTester tester,
    Locale locale, {
    bool empty = false,
    bool selection = false,
    bool list = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (list) StorageKeys.viewMode: 'list',
    });
    useTextScale(tester, 1.3);
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...libraryOverrides(empty: empty, selection: selection),
          trashDocumentsProvider
              .overrideWith((ref) => libraryRootDocuments.take(2).toList()),
          trashedPagesProvider.overrideWith((ref) => const <TrashedPage>[]),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          locale: locale,
          home: const DocumentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(Scaffold).first));
  }

  Future<void> openTrash(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.byTooltip(l10n.commonMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.librarySectionTrash));
    await tester.pumpAndSettle();
  }

  for (final locale in _locales) {
    final tag = locale.languageCode;

    testWidgets('$tag: grid view', (t) async {
      final l10n = await pump(t, locale);
      expect(find.text(l10n.librarySectionAll), findsOneWidget);
      expectNoOverflow(t, 'library grid');
    });

    testWidgets('$tag: list view with section headers', (t) async {
      final l10n = await pump(t, locale, list: true);
      expect(find.text(l10n.libraryFolders), findsOneWidget);
      expect(find.text(l10n.libraryDocuments), findsOneWidget);
      expectNoOverflow(t, 'library list');
    });

    testWidgets('$tag: empty library', (t) async {
      final l10n = await pump(t, locale, empty: true);
      expect(find.text(l10n.libraryEmptyTitle), findsOneWidget);
      expectNoOverflow(t, 'empty library');
    });

    testWidgets('$tag: selection header', (t) async {
      final l10n = await pump(t, locale, selection: true);
      expect(find.text(l10n.librarySelectedCount(3)), findsOneWidget);
      expectNoOverflow(t, 'selection header');
    });

    testWidgets('$tag: drawer and trash section with info bar', (t) async {
      final l10n = await pump(t, locale);
      await t.tap(find.byTooltip(l10n.commonMenu));
      await t.pumpAndSettle();
      expect(find.text(l10n.libraryManage), findsOneWidget);
      expectNoOverflow(t, 'library drawer');
      await t.tap(find.text(l10n.librarySectionTrash));
      await t.pumpAndSettle();
      expect(find.text(l10n.libraryTrashInfo), findsOneWidget);
      expectNoOverflow(t, 'trash section');
    });

    testWidgets('$tag: sort menu', (t) async {
      final l10n = await pump(t, locale);
      await t.tap(find.byTooltip(l10n.librarySortTitle));
      await t.pumpAndSettle();
      expect(find.text(l10n.settingsPinFavorites), findsOneWidget);
      expect(find.text(l10n.librarySortNewestFirst), findsOneWidget);
      expectNoOverflow(t, 'sort menu');
    });

    testWidgets('$tag: empty-trash confirmation', (t) async {
      final l10n = await pump(t, locale);
      await openTrash(t, l10n);
      await t.tap(find.widgetWithText(AppButton, l10n.libraryEmptyTrash));
      await t.pumpAndSettle();
      expect(find.text(l10n.libraryEmptyTrashConfirmMessage), findsOneWidget);
      expectNoOverflow(t, 'empty-trash dialog');
    });

    testWidgets('$tag: item menu sheet', (t) async {
      final l10n = await pump(t, locale);
      await _openItemMenu(t);
      expect(find.text(l10n.commonDuplicate), findsOneWidget);
      expect(find.text(l10n.libraryMoveToTrash), findsOneWidget);
      expectNoOverflow(t, 'item menu sheet');
    });

    testWidgets('$tag: rename dialog', (t) async {
      final l10n = await pump(t, locale);
      await _openItemMenu(t);
      await t.tap(find.text(l10n.commonRename));
      await t.pumpAndSettle();
      expect(find.text(l10n.libraryDocumentNameLabel), findsOneWidget);
      expectNoOverflow(t, 'rename dialog');
    });

    testWidgets('$tag: folder delete dialog', (t) async {
      final l10n = await pump(t, locale);
      await t.tap(find.byKey(const Key('folder_card_more_button')).first);
      await t.pumpAndSettle();
      await t.tap(find.text(l10n.commonDelete));
      await t.pumpAndSettle();
      expect(find.text(l10n.libraryDeleteFolderTitle), findsOneWidget);
      expectNoOverflow(t, 'folder delete dialog');
    });
  }
}

/// Opens the menu of the first document tile through its caret.
Future<void> _openItemMenu(WidgetTester tester) async {
  final caret = find.byWidgetPredicate(
    (w) =>
        w is Icon && w.icon == ElyanotesIcons.libraryCaretDown && w.key == null,
  );
  await tester.tap(caret.first);
  await tester.pumpAndSettle();
}
