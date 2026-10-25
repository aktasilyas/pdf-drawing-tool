import 'package:alchemist/alchemist.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/chrome_theme.dart';

const double _width = 820;
const double _height = 64;

Widget _scenario({
  required Brightness brightness,
  required SharedPreferences prefs,
  bool readerMode = false,
}) {
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  container.read(readerModeProvider.notifier).state = readerMode;
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: chromeTheme(brightness),
      home: const MediaQuery(
        data: MediaQueryData(size: Size(_width, _height)),
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: _width,
            height: _height,
            child: DrawingThemeProvider(
              theme: DrawingTheme(),
              child: MediumToolbar(documentTitle: 'Matematik notlari'),
            ),
          ),
        ),
      ),
    ),
  );
}

// Only the CI variant has committed baselines; platform goldens stay off.
Future<void> main() => AlchemistConfig.runWithConfig(
      config: const AlchemistConfig(
        platformGoldensConfig: PlatformGoldensConfig(enabled: false),
      ),
      run: _tests,
    );

Future<void> _tests() async {
  late SharedPreferences prefs;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final scenarios = <String, Widget Function()>{
    'portrait_light': () =>
        _scenario(brightness: Brightness.light, prefs: prefs),
    'portrait_dark': () => _scenario(brightness: Brightness.dark, prefs: prefs),
    'portrait_reader_light': () => _scenario(
          brightness: Brightness.light,
          prefs: prefs,
          readerMode: true,
        ),
  };

  scenarios.forEach((name, build) {
    goldenTest(
      'medium toolbar $name',
      fileName: 'medium_toolbar_$name',
      constraints: const BoxConstraints.tightFor(
        width: _width + 48,
        height: _height + 64,
      ),
      builder: () => GoldenTestScenario(
        name: name,
        child: build(),
      ),
    );
  });
}
