import 'package:alchemist/alchemist.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/chrome_theme.dart';

const double _width = 390;
const double _height = 104;

Widget _scenario({
  required Brightness brightness,
  required SharedPreferences prefs,
  bool readerMode = false,
}) {
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      // v1.0 configuration: audio recording is frozen.
      audioRecordingEnabledProvider.overrideWithValue(false),
    ],
  );
  // Two pages so the Pages button shows.
  container.read(pageManagerProvider.notifier).addPage();
  container.read(readerModeProvider.notifier).state = readerMode;
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: chromeTheme(brightness),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(_width, 844)),
        child: Material(
          color: (brightness == Brightness.dark
                  ? ChromePalette.dark
                  : ChromePalette.light)
              .paper,
          child: const SizedBox(
            width: _width,
            height: _height,
            child: Align(
              alignment: Alignment.topCenter,
              child: DrawingThemeProvider(
                theme: DrawingTheme(),
                child: AdaptiveToolbar(documentTitle: 'Matematik notlari'),
              ),
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
    'light': () => _scenario(brightness: Brightness.light, prefs: prefs),
    'dark': () => _scenario(brightness: Brightness.dark, prefs: prefs),
    'reader_light': () => _scenario(
          brightness: Brightness.light,
          prefs: prefs,
          readerMode: true,
        ),
  };

  scenarios.forEach((name, build) {
    goldenTest(
      'phone toolbar $name',
      fileName: 'phone_toolbar_$name',
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
