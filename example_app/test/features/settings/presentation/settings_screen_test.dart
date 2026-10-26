import 'package:drawing_ui/drawing_ui.dart' as drawing_ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/constants/storage_keys.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/settings/domain/entities/app_settings.dart';
import 'package:example_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:example_app/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:example_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:example_app/features/settings/presentation/widgets/about_section.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';

import '../../../helpers/l10n.dart';

class _MockUser extends Mock implements User {}

User? _noSupabase() => throw StateError('Supabase must not be touched');

Future<void> _shortDelay() {
  return Future<void>.delayed(const Duration(milliseconds: 50));
}

const _about = AboutSection(buildName: '1.0.0', buildNumber: '7');

/// The switch in the settings row whose title is [title].
Finder _switchOf(String title) {
  final row = find.ancestor(of: find.text(title), matching: find.byType(Row));
  return find.descendant(of: row.first, matching: find.byType(Switch));
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    FeatureFlags flags = FeatureFlags.allOff,
    User? Function()? user,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final userFn = user ?? _noSupabase;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagsProvider.overrideWithValue(flags),
          sharedPreferencesProvider.overrideWithValue(prefs),
          drawing_ui.sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWith((ref) => userFn()),
        ],
        child: localizedApp(
          theme: AppTheme.light,
          home: const SettingsScreen(aboutSection: _about),
        ),
      ),
    );
    await tester.pump();
  }

  ProviderContainer containerOf(WidgetTester tester) {
    final element = tester.element(find.byType(SettingsScreen));
    return ProviderScope.containerOf(element);
  }

  group('flags off (v1.0)', () {
    testWidgets('no account entries, no logout, Supabase untouched',
        (tester) async {
      await pumpSettings(tester);
      expect(find.text('Ayarlar'), findsOneWidget);
      expect(find.text('HESAP'), findsNothing);
      expect(find.text('Çıkış Yap'), findsNothing);
      expect(find.text('Şifre değiştir'), findsNothing);
      expect(find.text('GÖRÜNÜM'), findsOneWidget);
      expect(find.text('GİZLİLİK'), findsOneWidget);
      expect(find.text('HAKKINDA'), findsOneWidget);
    });

    testWidgets('no placeholder entries remain', (tester) async {
      await pumpSettings(tester);
      const removed = [
        'Dışa aktar',
        'Önbelleği temizle',
        'Kullanım koşulları',
        'VERİ',
      ];
      for (final title in removed) {
        expect(find.text(title), findsNothing, reason: title);
      }
    });
  });

  testWidgets('theme: dialog choice applies and persists', (tester) async {
    await pumpSettings(tester);
    expect(find.text('Sistem'), findsWidgets);
    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    final dark = find.descendant(of: dialog, matching: find.text('Koyu'));
    await tester.tap(dark);
    await tester.pumpAndSettle();

    expect(dialog, findsNothing);
    final settings = containerOf(tester).read(settingsProvider);
    expect(settings.themeMode, AppThemeMode.dark);
    expect(prefs.getString('app_settings'), contains('"themeMode":"dark"'));
  });

  testWidgets('canvas theme: segment applies and persists', (tester) async {
    await pumpSettings(tester);
    final segments = find.byType(SegmentedButton<drawing_ui.CanvasDarkMode>);
    final dark = find.descendant(of: segments, matching: find.text('Koyu'));
    await tester.tap(dark);
    await tester.pumpAndSettle();

    final container = containerOf(tester);
    final mode = container.read(drawing_ui.canvasDarkModeProvider);
    expect(mode, drawing_ui.CanvasDarkMode.on);
    expect(prefs.getString('canvas_dark_mode'), 'on');
  });

  testWidgets('pin favourites: switch toggles and persists', (tester) async {
    await pumpSettings(tester);
    final toggle = _switchOf('Favorileri üste sabitle');
    expect(tester.widget<Switch>(toggle).value, isFalse);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(toggle).value, isTrue);
    expect(prefs.getBool(StorageKeys.pinFavoritesToTop), isTrue);
  });

  testWidgets('crash reports: switch turns reporting off and persists',
      (tester) async {
    await pumpSettings(tester);
    final toggle = _switchOf('Çökme raporlarını gönder');
    expect(tester.widget<Switch>(toggle).value, isTrue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(prefs.getBool(StorageKeys.crashReportingEnabled), isFalse);
  });

  group('about', () {
    testWidgets('shows the build version', (tester) async {
      await pumpSettings(tester);
      expect(find.text('Sürüm'), findsOneWidget);
      expect(find.text('1.0.0 (7)'), findsOneWidget);
    });

    testWidgets('licences open the licence page', (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.text('Açık kaynak lisansları'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('privacy policy opens the bundled policy', (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.text('Gizlilik politikası'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final loading = find.byType(CircularProgressIndicator);
      for (var i = 0; i < 50 && loading.evaluate().isNotEmpty; i++) {
        await tester.runAsync(_shortDelay);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      final date = find.textContaining('Yürürlük', findRichText: true);
      expect(date, findsOneWidget);

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyPolicyScreen), findsNothing);
    });

    testWidgets('feedback copies the contact e-mail', (tester) async {
      String? copied;
      final messenger = tester.binding.defaultBinaryMessenger;
      const channel = SystemChannels.platform;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      await pumpSettings(tester);
      expect(find.text('elyanotes2108@gmail.com'), findsOneWidget);
      await tester.tap(find.text('Geri bildirim gönder'));
      await tester.pump();
      expect(copied, 'elyanotes2108@gmail.com');
      expect(find.text('E-posta adresi kopyalandı'), findsOneWidget);
    });

    testWidgets('version falls back to a dash without build info',
        (tester) async {
      final app = localizedApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AboutSection(buildName: null)),
      );
      await tester.pumpWidget(app);
      expect(find.text('—'), findsOneWidget);
    });
  });

  testWidgets('cloud on: shows account section, logout and user name',
      (tester) async {
    final user = _MockUser();
    when(() => user.email).thenReturn('ada@example.com');
    when(() => user.userMetadata).thenReturn(null);
    await pumpSettings(
      tester,
      flags: const FeatureFlags(cloudSync: true),
      user: () => user,
    );
    expect(find.text('HESAP'), findsOneWidget);
    expect(find.text('Çıkış Yap'), findsOneWidget);
    expect(find.text('ada'), findsOneWidget);
    expect(find.text('Ayarlar'), findsNothing);
  });

  testWidgets('close button pops the screen', (tester) async {
    await pumpSettings(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    final route = MaterialPageRoute<void>(
      builder: (_) => const SettingsScreen(aboutSection: _about),
    );
    navigator.push(route);
    await tester.pumpAndSettle();
    expect(navigator.canPop(), isTrue);

    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();
    expect(navigator.canPop(), isFalse);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
