import 'package:drawing_ui/drawing_ui.dart' as drawing_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:example_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:example_app/features/settings/presentation/widgets/about_section.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';
import 'package:example_app/l10n/l10n.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/font_loader.dart';
import '../../../helpers/l10n.dart';

class _MockUser extends Mock implements User {}

const _phone = Size(390, 844);
const _locales = [Locale('tr'), Locale('en')];

const _settings = SettingsScreen(
  aboutSection: AboutSection(buildName: '1.0.0', buildNumber: '1'),
);

Future<void> _shortDelay() {
  return Future<void>.delayed(const Duration(milliseconds: 20));
}

Widget _scaled(BuildContext context, Widget? child) {
  final data = MediaQuery.of(context);
  return MediaQuery(
    data: data.copyWith(textScaler: const TextScaler.linear(1.3)),
    child: child!,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppTestFonts();
    await loadManifestFonts();
  });

  Future<AppLocalizations> pump(
    WidgetTester tester,
    Locale locale,
    Widget home, {
    bool cloud = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final user = _MockUser();
    when(() => user.email).thenReturn('a-rather-long-address@example.com');
    when(() => user.id).thenReturn('00000000-0000-0000-0000-000000000000');
    when(() => user.userMetadata).thenReturn(null);
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagsProvider.overrideWithValue(
            cloud ? const FeatureFlags(cloudSync: true) : FeatureFlags.allOff,
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
          drawing_ui.sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWith((ref) => cloud ? user : null),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          locale: locale,
          builder: _scaled,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(Scaffold).first));
  }

  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
  }

  for (final locale in _locales) {
    final tag = locale.languageCode;

    testWidgets('$tag: settings screen, scrolled to the bottom', (t) async {
      await pump(t, locale, _settings);
      expectNoOverflow(t, 'settings top');
      await scrollToBottom(t);
      expectNoOverflow(t, 'settings bottom');
    });

    testWidgets('$tag: cloud settings screen incl. logout', (t) async {
      await pump(t, locale, _settings, cloud: true);
      await scrollToBottom(t);
      expectNoOverflow(t, 'cloud settings bottom');
    });

    testWidgets('$tag: theme dialog', (t) async {
      final l10n = await pump(t, locale, _settings);
      await t.tap(find.text(l10n.settingsTheme));
      await t.pumpAndSettle();
      expect(find.text(l10n.settingsThemeDialogTitle), findsOneWidget);
      expectNoOverflow(t, 'theme dialog');
    });

    testWidgets('$tag: edit name dialog', (t) async {
      await pump(t, locale, _settings, cloud: true);
      await t.tap(find.text('a-rather-long-address'));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expectNoOverflow(t, 'edit name dialog');
    });

    testWidgets('$tag: account info dialog', (t) async {
      final l10n = await pump(t, locale, _settings, cloud: true);
      final tile = find.text(l10n.settingsAccountInfo);
      await t.ensureVisible(tile);
      await t.tap(tile);
      await t.pumpAndSettle();
      expect(find.text(l10n.settingsAccountInfoTitle), findsOneWidget);
      expectNoOverflow(t, 'account info dialog');
    });

    testWidgets('$tag: logout confirmation', (t) async {
      final l10n = await pump(t, locale, _settings, cloud: true);
      await scrollToBottom(t);
      await t.tap(find.text(l10n.settingsLogout));
      await t.pumpAndSettle();
      expect(find.text(l10n.settingsLogoutConfirm), findsOneWidget);
      expectNoOverflow(t, 'logout dialog');
    });

    testWidgets('$tag: privacy policy screen', (t) async {
      await pump(t, locale, const PrivacyPolicyScreen());
      final loading = find.byType(CircularProgressIndicator);
      for (var i = 0; i < 50 && loading.evaluate().isNotEmpty; i++) {
        await t.runAsync(_shortDelay);
        await t.pump();
      }
      await t.pumpAndSettle();
      expect(loading, findsNothing);
      expectNoOverflow(t, 'privacy policy');
    });
  }
}
