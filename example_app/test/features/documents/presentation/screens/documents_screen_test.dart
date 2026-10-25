import 'package:drawing_ui/drawing_ui.dart' show CoverTextureStore;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/presentation/screens/documents_screen.dart';

import '../../../../helpers/font_loader.dart';
import 'library_fixtures.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    await loadManifestFonts();
    await CoverTextureStore.ensureLoaded();
  });

  Future<void> pump(WidgetTester tester, Size size) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: libraryOverrides(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DocumentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('landscape tablet: sidebar open, no header toggle',
      (tester) async {
    await pump(tester, const Size(1180, 820));
    expect(find.byTooltip('Kenar çubuğunu aç'), findsNothing);
    // Header title plus the sidebar nav label.
    expect(find.text('Tüm Notlar'), findsWidgets);
  });

  testWidgets('portrait tablet: sidebar starts collapsed with header toggle',
      (tester) async {
    await pump(tester, const Size(820, 1180));
    expect(find.byTooltip('Kenar çubuğunu aç'), findsOneWidget);
  });

  testWidgets('header shows the section title', (tester) async {
    await pump(tester, const Size(390, 844));
    expect(find.text('Tüm Notlar'), findsOneWidget);
  });
}
