import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/config/app_env.dart';
import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/di/injection.dart';
import 'package:example_app/core/utils/logger.dart';

typedef EnvInitializer = Future<void> Function(AppEnv env);

/// Result of a successful [AppBootstrap.run].
class AppBootstrapResult {
  const AppBootstrapResult({required this.prefs});
  final SharedPreferences prefs;
}

/// Startup sequence. Services behind a disabled flag are never touched.
class AppBootstrap {
  AppBootstrap({
    required this.flags,
    this.env = const AppEnv(),
    this.initSupabase = _defaultInitSupabase,
    this.initRevenueCat = _defaultInitRevenueCat,
    this.configureDeps = configureDependencies,
  });

  final FeatureFlags flags;
  final AppEnv env;
  final EnvInitializer initSupabase;
  final EnvInitializer initRevenueCat;
  final Future<void> Function() configureDeps;

  Future<AppBootstrapResult> run() async {
    env.validateFor(flags);

    final prefsFuture = SharedPreferences.getInstance();
    if (flags.needsSupabase) {
      await initSupabase(env);
    }
    if (flags.premium) {
      try {
        await initRevenueCat(env);
      } catch (e) {
        // Graceful degradation: the app works without RevenueCat.
        logger.e('RevenueCat init failed: $e');
      }
    }
    await configureDeps();
    return AppBootstrapResult(prefs: await prefsFuture);
  }
}

Future<void> _defaultInitSupabase(AppEnv env) async {
  await Supabase.initialize(
    url: env.supabaseUrl,
    anonKey: env.supabaseAnonKey,
    debug: kDebugMode,
  );
  logger.i('Supabase initialized');
}

Future<void> _defaultInitRevenueCat(AppEnv env) async {
  await Purchases.configure(PurchasesConfiguration(env.revenueCatApiKey));
  if (kDebugMode) {
    await Purchases.setLogLevel(LogLevel.debug);
  }
  logger.i('RevenueCat initialized');
}
