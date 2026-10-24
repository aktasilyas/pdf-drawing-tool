import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/config/app_env.dart';
import 'package:example_app/core/config/feature_flags.dart';

void main() {
  group('FeatureFlags', () {
    test('allOff has every flag disabled and needs no Supabase', () {
      const f = FeatureFlags.allOff;
      expect(f.aiChat, isFalse);
      expect(f.cloudSync, isFalse);
      expect(f.premium, isFalse);
      expect(f.audioRecording, isFalse);
      expect(f.needsSupabase, isFalse);
    });

    test('allOn has every flag enabled and needs Supabase', () {
      const f = FeatureFlags.allOn;
      expect(f.aiChat && f.cloudSync && f.premium && f.audioRecording, isTrue);
      expect(f.needsSupabase, isTrue);
    });

    test('needsSupabase is true for aiChat or cloudSync only', () {
      expect(const FeatureFlags(aiChat: true).needsSupabase, isTrue);
      expect(const FeatureFlags(cloudSync: true).needsSupabase, isTrue);
      expect(const FeatureFlags(premium: true).needsSupabase, isFalse);
      expect(const FeatureFlags(audioRecording: true).needsSupabase, isFalse);
    });

    test('fromEnvironment defaults to all off without dart-defines', () {
      expect(FeatureFlags.fromEnvironment(), FeatureFlags.allOff);
    });

    test('provider defaults to fromEnvironment and can be overridden', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(featureFlagsProvider), FeatureFlags.allOff);

      final c2 = ProviderContainer(overrides: [
        featureFlagsProvider.overrideWithValue(FeatureFlags.allOn),
      ]);
      addTearDown(c2.dispose);
      expect(c2.read(featureFlagsProvider), FeatureFlags.allOn);
    });
  });

  group('AppEnv.validateFor', () {
    test('passes with no keys when all flags are off', () {
      expect(() => const AppEnv().validateFor(FeatureFlags.allOff),
          returnsNormally);
    });

    test('fails fast when Supabase is needed but not configured', () {
      expect(
        () => const AppEnv().validateFor(const FeatureFlags(aiChat: true)),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('SUPABASE_URL'))),
      );
    });

    test('fails when premium is on without a RevenueCat key', () {
      expect(
        () => const AppEnv().validateFor(const FeatureFlags(premium: true)),
        throwsA(isA<StateError>()),
      );
    });

    test('passes when required keys are present', () {
      const env = AppEnv(
        supabaseUrl: 'https://x.supabase.co',
        supabaseAnonKey: 'k',
        revenueCatAppleKey: 'a',
        revenueCatGoogleKey: 'g',
      );
      expect(() => env.validateFor(FeatureFlags.allOn), returnsNormally);
    });
  });
}
