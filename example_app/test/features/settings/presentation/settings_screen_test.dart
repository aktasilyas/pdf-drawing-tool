import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';

class _MockUser extends Mock implements User {}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    required FeatureFlags flags,
    required User? Function() user,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagsProvider.overrideWithValue(flags),
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWith((ref) => user()),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('cloud off: no account section, no logout, Supabase untouched',
      (tester) async {
    await pumpSettings(
      tester,
      flags: FeatureFlags.allOff,
      user: () => throw StateError('Supabase must not be touched'),
    );
    expect(find.text('HESAP'), findsNothing);
    expect(find.text('Çıkış Yap'), findsNothing);
    expect(find.text('GÖRÜNÜM'), findsOneWidget);
    expect(find.text('VERİ'), findsOneWidget);
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
  });
}
