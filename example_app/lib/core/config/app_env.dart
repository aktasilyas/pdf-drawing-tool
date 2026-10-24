import 'package:flutter/foundation.dart';

import 'package:example_app/core/config/feature_flags.dart';

/// Build-time configuration read from `--dart-define` / `--dart-define-from-file`.
class AppEnv {
  const AppEnv({
    this.supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
    this.supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY'),
    this.revenueCatAppleKey =
        const String.fromEnvironment('REVENUECAT_APPLE_KEY'),
    this.revenueCatGoogleKey =
        const String.fromEnvironment('REVENUECAT_GOOGLE_KEY'),
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenueCatAppleKey;
  final String revenueCatGoogleKey;

  /// Platform-appropriate RevenueCat public API key (may be empty).
  String get revenueCatApiKey {
    final apple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    return apple ? revenueCatAppleKey : revenueCatGoogleKey;
  }

  /// Throws a [StateError] naming every value the enabled flags require.
  void validateFor(FeatureFlags flags) {
    final missing = <String>[
      if (flags.needsSupabase && supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (flags.needsSupabase && supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
      if (flags.premium && revenueCatApiKey.isEmpty)
        'REVENUECAT_APPLE_KEY / REVENUECAT_GOOGLE_KEY',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing build configuration for enabled feature flags: '
        '${missing.join(', ')}. Pass them with --dart-define-from-file.',
      );
    }
  }
}
