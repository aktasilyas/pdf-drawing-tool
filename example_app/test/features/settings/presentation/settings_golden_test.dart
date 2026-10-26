import 'package:drawing_ui/drawing_ui.dart' as drawing_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:example_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:example_app/features/settings/presentation/widgets/about_section.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';

import '../../../helpers/font_loader.dart';

const _tablet = Size(1180, 820);
const _phone = Size(390, 844);

Future<void> _shortDelay() {
  return Future<void>.delayed(const Duration(milliseconds: 20));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    await loadManifestFonts();
  });

  Future<void> pumpGolden(
    WidgetTester tester, {
    required Size size,
    required bool dark,
    required Widget home,
  }) async {
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
          theme: dark ? AppTheme.dark : AppTheme.light,
          debugShowCheckedModeBanner: false,
          home: home,
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    // The privacy policy loads its Markdown asset asynchronously.
    final loading = find.byType(CircularProgressIndicator);
    for (var i = 0; i < 50 && loading.evaluate().isNotEmpty; i++) {
      await tester.runAsync(_shortDelay);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  const settings = SettingsScreen(
    aboutSection: AboutSection(buildName: '1.0.0', buildNumber: '1'),
  );

  for (final (device, size) in [('phone', _phone), ('tablet', _tablet)]) {
    for (final dark in [false, true]) {
      final name = 'settings_${device}_${dark ? 'dark' : 'light'}';
      testWidgets(name, (tester) async {
        await pumpGolden(tester, size: size, dark: dark, home: settings);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/$name.png'),
        );
      });
    }
  }

  testWidgets('settings_phone_light_about', (tester) async {
    await pumpGolden(tester, size: _phone, dark: false, home: settings);
    await tester.scrollUntilVisible(
      find.text('Geri bildirim gönder'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/settings_phone_light_about.png'),
    );
  });

  const privacyCases = [
    ('privacy_policy_phone_light', _phone, false),
    ('privacy_policy_phone_dark', _phone, true),
    ('privacy_policy_tablet_light', _tablet, false),
  ];
  for (final (name, size, dark) in privacyCases) {
    testWidgets(name, (tester) async {
      await pumpGolden(
        tester,
        size: size,
        dark: dark,
        home: const PrivacyPolicyScreen(),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    });
  }
}
