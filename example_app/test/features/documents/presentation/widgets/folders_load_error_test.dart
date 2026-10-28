import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/screens/manage_folders_screen.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_error_views.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_sidebar.dart';
import 'package:example_app/features/documents/presentation/widgets/folders_load_error_row.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';
import 'package:example_app/l10n/l10n.dart';

import '../../../../helpers/font_loader.dart';
import '../../../../helpers/l10n.dart';
import '../screens/library_fixtures.dart';

const _secret = 'secret-boom-detail';

/// Folder load failures show a plain message and a retry that re-queries
/// [foldersProvider] (#388).
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
  });

  var calls = 0;
  var fail = true;

  setUp(() {
    calls = 0;
    fail = true;
  });

  Future<AppLocalizations> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWith((ref) async {
            calls++;
            if (fail) throw StateError(_secret);
            return libraryFolders;
          }),
        ],
        child: localizedApp(theme: AppTheme.light, home: home),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(Scaffold).first));
  }

  Future<void> expectPlainErrorThenRetry(
    WidgetTester tester,
    AppLocalizations l10n,
    Finder retry,
  ) async {
    expect(find.text(l10n.libraryFoldersLoadFailed), findsOneWidget);
    expect(find.textContaining(_secret), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
    expect(retry, findsOneWidget);
    expect(calls, 1);

    fail = false;
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text(l10n.libraryFoldersLoadFailed), findsNothing);
  }

  testWidgets('manage folders screen: message, no exception, retry',
      (tester) async {
    final l10n = await pump(tester, const ManageFoldersScreen());
    await expectPlainErrorThenRetry(
      tester,
      l10n,
      find.byKey(DocumentsErrorView.retryKey),
    );
  });

  testWidgets('move-to-folder dialog: message, no exception, retry',
      (tester) async {
    final l10n = await pump(
      tester,
      const Scaffold(body: MoveToFolderDialog(documentIds: ['doc-1'])),
    );
    await expectPlainErrorThenRetry(
      tester,
      l10n,
      find.byKey(DocumentsErrorView.retryKey),
    );
  });

  testWidgets('sidebar: inline message, no exception, 48dp retry',
      (tester) async {
    final l10n = await pump(
      tester,
      Scaffold(
        body: DocumentsSidebar(
          selectedSection: SidebarSection.documents,
          onSectionChanged: (_) {},
        ),
      ),
    );
    final retry = find.byKey(FoldersLoadErrorRow.retryKey);
    final size = tester.getSize(retry);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await expectPlainErrorThenRetry(tester, l10n, retry);
  });
}
