import 'package:alchemist/alchemist.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/export_options.dart';
import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/chrome_theme.dart';

const _pageCount = 5;
const _tabletWidth = 300.0; // AnchoredPanel max width.
const _phoneWidth = 390.0;

const _range = ExportOptions(scope: ExportPageScope.range, from: 2, to: 4);
const _invalid = ExportOptions(scope: ExportPageScope.range, from: 4, to: 2);
const _current = ExportOptions(
  scope: ExportPageScope.current,
  includeTemplate: false,
);

Widget _scenario({
  required Brightness brightness,
  required double width,
  required SharedPreferences prefs,
  ExportOptions options = const ExportOptions(),
  double textScale = 1,
}) {
  final tablet = width < _phoneWidth;
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      isInfiniteCanvasProvider.overrideWith((ref) => false),
      pageCountProvider.overrideWithValue(_pageCount),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: chromeTheme(brightness),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 600),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Builder(
          builder: (context) {
            final cs = Theme.of(context).colorScheme;
            // Tablet: the anchored popover's rounded surface.
            // Phone: the bottom sheet body under the drag handle.
            return ColoredBox(
              color: ChromePalette.of(context).background,
              child: Padding(
                padding: EdgeInsets.all(tablet ? ChromeSpacing.sm : 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(tablet ? 12 : 0),
                  child: ColoredBox(
                    color: cs.surface,
                    child: Material(
                      type: MaterialType.transparency,
                      child: ExportPanel(
                        onClose: () {},
                        embedded: true,
                        initialOptions: options,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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

  const light = Brightness.light;
  const dark = Brightness.dark;
  final scenarios = <String, Widget Function()>{
    'tablet_light': () =>
        _scenario(brightness: light, width: _tabletWidth, prefs: prefs),
    'tablet_dark': () =>
        _scenario(brightness: dark, width: _tabletWidth, prefs: prefs),
    'tablet_light_range': () => _scenario(
        brightness: light, width: _tabletWidth, prefs: prefs, options: _range),
    'tablet_dark_invalid': () => _scenario(
        brightness: dark, width: _tabletWidth, prefs: prefs, options: _invalid),
    'phone_light': () => _scenario(
        brightness: light, width: _phoneWidth, prefs: prefs, options: _range),
    'phone_dark': () => _scenario(
        brightness: dark, width: _phoneWidth, prefs: prefs, options: _current),
    'phone_light_invalid_text130': () => _scenario(
        brightness: light,
        width: _phoneWidth,
        prefs: prefs,
        options: _invalid,
        textScale: 1.3),
  };

  scenarios.forEach((name, build) {
    goldenTest(
      'export panel $name',
      fileName: 'export_panel_$name',
      constraints: BoxConstraints.tightFor(
        width: name.startsWith('phone')
            ? _phoneWidth
            : _tabletWidth + 2 * ChromeSpacing.sm,
      ),
      builder: () => GoldenTestScenario(name: name, child: build()),
    );
  });
}
