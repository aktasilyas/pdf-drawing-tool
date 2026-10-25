import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../golden/helpers/chrome_theme.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpMenu(WidgetTester tester, Brightness brightness) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: chromeTheme(brightness),
          home: Scaffold(
            body: RepaintBoundary(
              key: const Key('menu'),
              child: DrawingThemeProvider(
                theme: const DrawingTheme(),
                child: const Align(
                  alignment: Alignment.topRight,
                  child: ToolbarOverflowMenu(
                    hiddenTools: [ToolType.shapes, ToolType.text],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ToolbarOverflowMenu));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets('menu uses chrome palette surface (${brightness.name})',
        (tester) async {
      await pumpMenu(tester, brightness);
      final palette =
          ChromePalette.of(tester.element(find.byType(ToolbarOverflowMenu)));
      final panel = tester.widget<Material>(find
          .ancestor(
              of: find.text(ToolType.shapes.displayName),
              matching: find.byType(Material))
          .first);
      expect(panel.color, palette.surfaceElevated);
      expect(find.text(ToolType.shapes.displayName), findsOneWidget);
    });

    testWidgets('golden (${brightness.name})', (tester) async {
      await pumpMenu(tester, brightness);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
            'goldens/toolbar_overflow_menu_${brightness.name}.png'),
      );
    });
  }
}
