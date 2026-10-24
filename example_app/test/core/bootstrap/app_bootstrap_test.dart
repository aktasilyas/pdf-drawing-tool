import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/bootstrap/app_bootstrap.dart';
import 'package:example_app/core/config/app_env.dart';
import 'package:example_app/core/config/feature_flags.dart';

const _fullEnv = AppEnv(
  supabaseUrl: 'https://x.supabase.co',
  supabaseAnonKey: 'k',
  revenueCatAppleKey: 'a',
  revenueCatGoogleKey: 'g',
);

void main() {
  late List<String> calls;

  AppBootstrap build(FeatureFlags flags, {AppEnv env = const AppEnv()}) {
    return AppBootstrap(
      flags: flags,
      env: env,
      initSupabase: (_) async => calls.add('supabase'),
      initRevenueCat: (_) async => calls.add('revenuecat'),
      configureDeps: () async => calls.add('deps'),
    );
  }

  setUp(() {
    calls = [];
    SharedPreferences.setMockInitialValues({});
  });

  test('all flags off: no Supabase, no RevenueCat, no keys required', () async {
    final result = await build(FeatureFlags.allOff).run();
    expect(calls, ['deps']);
    expect(result.prefs, isA<SharedPreferences>());
  });

  test('all flags on: initializes Supabase and RevenueCat', () async {
    await build(FeatureFlags.allOn, env: _fullEnv).run();
    expect(calls, containsAll(['supabase', 'revenuecat', 'deps']));
  });

  test('cloudSync only: Supabase but not RevenueCat', () async {
    await build(const FeatureFlags(cloudSync: true), env: _fullEnv).run();
    expect(calls, contains('supabase'));
    expect(calls, isNot(contains('revenuecat')));
  });

  test('premium only: RevenueCat but not Supabase', () async {
    await build(const FeatureFlags(premium: true), env: _fullEnv).run();
    expect(calls, contains('revenuecat'));
    expect(calls, isNot(contains('supabase')));
  });

  test('fails fast on missing env for enabled flags', () async {
    expect(build(const FeatureFlags(aiChat: true)).run(),
        throwsA(isA<StateError>()));
    expect(calls, isEmpty);
  });

  test('RevenueCat init failure does not abort startup', () async {
    final b = AppBootstrap(
      flags: const FeatureFlags(premium: true),
      env: _fullEnv,
      initRevenueCat: (_) async => throw Exception('boom'),
      configureDeps: () async => calls.add('deps'),
    );
    await b.run();
    expect(calls, ['deps']);
  });
}
