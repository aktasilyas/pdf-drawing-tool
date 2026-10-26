import 'package:drawing_ui/drawing_ui.dart' show CoverTextureStore;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/buttons/app_icon_button.dart';
import 'package:example_app/features/documents/presentation/screens/documents_screen.dart';

import '../../../../helpers/a11y.dart';
import '../../../../helpers/font_loader.dart';
import 'library_fixtures.dart';

const _sizes = <String, Size>{
  'landscape tablet': Size(1180, 820),
  'portrait tablet': Size(820, 1180),
  'phone': Size(390, 844),
};

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    await loadManifestFonts();
    await CoverTextureStore.ensureLoaded();
  });

  Future<void> pump(
    WidgetTester tester,
    Size size, {
    bool selection = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: libraryOverrides(selection: selection),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DocumentsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final entry in _sizes.entries) {
    testWidgets('${entry.key}: meets the 48dp tap-target guideline',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, entry.value);
      await expectTapTargets(tester);
      handle.dispose();
    });

    testWidgets('${entry.key}: lays out at 1.3x text scale', (tester) async {
      useTextScale(tester, 1.3);
      await pump(tester, entry.value);
      expectNoOverflow(tester, 'library (${entry.key})');
    });
  }

  testWidgets('selection mode meets the 48dp tap-target guideline',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const Size(1180, 820), selection: true);
    await expectTapTargets(tester);
    handle.dispose();
  });

  testWidgets('selection mode lays out at 1.3x text scale', (tester) async {
    useTextScale(tester, 1.3);
    await pump(tester, const Size(1180, 820), selection: true);
    expectNoOverflow(tester, 'library selection mode');
  });

  testWidgets('every icon-only button carries its label into semantics',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const Size(1180, 820));

    final buttons = tester.widgetList<AppIconButton>(
      find.byType(AppIconButton),
    );
    expect(buttons, isNotEmpty);
    for (final button in buttons) {
      final label = button.semanticLabel ?? button.tooltip;
      expect(label, isNotNull, reason: 'icon button without a label');
      expect(
        find.semantics.byLabel(label!),
        findsAny,
        reason: 'no semantics node labelled "$label"',
      );
    }
    handle.dispose();
  });

  testWidgets('tiles and favourite badges reach the semantics tree',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const Size(1180, 820));

    // Tile covers are labelled with the item title (see
    // library_tile_semantics_test.dart for the button flag itself).
    expect(find.semantics.byLabel('Biyoloji'), findsAny);
    expect(find.semantics.byLabel('Ders Notları'), findsAny);
    // Fixtures hold favourites, so the badge is on screen.
    expect(find.semantics.byLabel('Favorilerden çıkar'), findsAny);
    handle.dispose();
  });
}
