import 'package:drawing_ui/drawing_ui.dart' show CoverTextureStore;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/buttons/index.dart';
import 'package:example_app/features/documents/presentation/screens/documents_screen.dart';

import '../../../../helpers/a11y.dart';
import '../../../../helpers/font_loader.dart';
import 'library_fixtures.dart';
import '../../../../helpers/l10n.dart';

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
        child: localizedApp(
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
      final nodes = find.semantics.byLabel(label!).evaluate().toList();
      expect(
        nodes,
        isNotEmpty,
        reason: 'no semantics node labelled "$label": '
            '${semanticsLabels(tester)}',
      );
      // The label must sit on the button's own node, not on a neighbour's.
      expect(nodes.first, isSemantics(label: label, isButton: true));
    }
    handle.dispose();
  });

  testWidgets('tiles and favourite badges reach the semantics tree',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const Size(1180, 820));

    // Fixtures hold favourites, so a badge is on screen; the tile covers
    // themselves are asserted in library_tile_semantics_test.dart.
    expect(
      find.semantics.byLabel('Favorilerden çıkar').evaluate().first,
      isSemantics(isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });
}
