import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_sidebar.dart';

import '../../../../helpers/font_loader.dart';
import '../screens/library_fixtures.dart';
import '../../../../helpers/l10n.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    await loadManifestFonts();
  });

  Future<void> pump(
    WidgetTester tester, {
    ValueChanged<SidebarSection>? onSectionChanged,
    SidebarSection selected = SidebarSection.documents,
    FeatureFlags flags = FeatureFlags.allOff,
  }) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersProvider.overrideWith((ref) => libraryFolders),
          featureFlagsProvider.overrideWithValue(flags),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DocumentsSidebar(
              selectedSection: selected,
              onSectionChanged: onSectionChanged ?? (_) {},
              onCollapse: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the three nav rows and no Etiketler row', (tester) async {
    await pump(tester);
    expect(find.text('Tüm Notlar'), findsOneWidget);
    expect(find.text('Favoriler'), findsOneWidget);
    expect(find.text('Son Silinenler'), findsOneWidget);
    expect(find.text('Etiketler'), findsNothing);
    expect(find.text('Yakında'), findsNothing);
  });

  testWidgets('tapping Favoriler reports the favorites section',
      (tester) async {
    SidebarSection? section;
    await pump(tester, onSectionChanged: (s) => section = s);
    await tester.tap(find.text('Favoriler'));
    expect(section, SidebarSection.favorites);
  });

  testWidgets('lists root folders with counts and the subfolder row',
      (tester) async {
    await pump(tester);
    expect(find.text('Ders Notları'), findsOneWidget);
    expect(find.text('Biyoloji'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('nav rows are at least 48 high', (tester) async {
    await pump(tester);
    final size = tester.getSize(
      find.ancestor(
        of: find.text('Favoriler'),
        matching: find.byType(InkWell),
      ),
    );
    expect(size.height, greaterThanOrEqualTo(48));
  });

  // Regression guard: the sidebar has no flag-dependent rows; it must not
  // show unshipped Shared/Store placeholders in any flag combination.
  group('frozen-feature sections (#249)', () {
    for (final flags in [FeatureFlags.allOff, FeatureFlags.allOn]) {
      testWidgets('no Paylaşılan / Mağaza placeholder rows with $flags',
          (tester) async {
        await pump(tester, flags: flags);
        expect(find.text('Paylaşılan'), findsNothing);
        expect(find.text('Mağaza'), findsNothing);
        expect(find.text('Yakında'), findsNothing);
      });
    }
  });
}
