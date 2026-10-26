import 'package:drawing_ui/drawing_ui.dart' as drawing_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:example_app/features/settings/presentation/widgets/about_section.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/font_loader.dart';

const _sizes = <String, Size>{
  'tablet': Size(1180, 820),
  'phone': Size(390, 844),
};

const _settings = SettingsScreen(
  aboutSection: AboutSection(buildName: '1.0.0', buildNumber: '1'),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    await loadManifestFonts();
  });

  Future<void> pump(WidgetTester tester, Size size) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagsProvider.overrideWithValue(FeatureFlags.allOff),
          sharedPreferencesProvider.overrideWithValue(prefs),
          drawing_ui.sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: _settings,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The tap-target guideline is not asserted here yet: the canvas-theme
  // segments (40dp) and the licence row (32dp) are still below 48dp, and
  // raising them moves the rest of the screen, so it needs a golden regen
  // and a design review. Tracked in #205 with the measured offenders.
  for (final entry in _sizes.entries) {
    testWidgets('${entry.key}: lays out at 1.3x text scale', (tester) async {
      useTextScale(tester, 1.3);
      await pump(tester, entry.value);
      expectNoOverflow(tester, 'settings (${entry.key})');
    });
  }

  testWidgets('the close button is labelled', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const Size(390, 844));
    expect(find.semantics.byLabel('Kapat'), findsOne);
    handle.dispose();
  });
}
