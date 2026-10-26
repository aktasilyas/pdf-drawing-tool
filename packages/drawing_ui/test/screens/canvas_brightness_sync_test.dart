import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/providers/canvas_dark_mode_provider.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';
import 'package:drawing_ui/src/screens/canvas_brightness_sync.dart';

Widget _app(Brightness brightness) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(null)],
    child: MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: const CanvasBrightnessSync(child: SizedBox()),
    ),
  );
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SizedBox)));

void main() {
  group('CanvasBrightnessSync', () {
    testWidgets('app_dark_platform_light_gives_dark_canvas', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(_app(Brightness.dark));
      final container = _container(tester);
      await container
          .read(canvasDarkModeProvider.notifier)
          .setMode(CanvasDarkMode.followSystem);
      await tester.pump();
      await tester.pump();

      expect(
        container.read(canvasColorSchemeProvider).background,
        equals(const Color(0xFF2C2C2C)),
      );
    });

    testWidgets('theme_switch_to_light_updates_canvas', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(_app(Brightness.dark));
      final container = _container(tester);
      await container
          .read(canvasDarkModeProvider.notifier)
          .setMode(CanvasDarkMode.followSystem);
      await tester.pump();
      await tester.pump();

      await tester.pumpWidget(_app(Brightness.light));
      await tester.pumpAndSettle();

      expect(
        container.read(canvasColorSchemeProvider).background,
        equals(const Color(0xFFFFFFFF)),
      );
    });
  });
}
