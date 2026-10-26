import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/config/app_env.dart';
import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/constants/storage_keys.dart';
import 'package:example_app/core/crash_reporting/crash_reporter.dart';
import 'package:example_app/core/crash_reporting/crash_reporting_setup.dart';
import 'package:example_app/core/di/injection.dart';
import 'package:example_app/core/utils/logger.dart';

typedef EnvInitializer = Future<void> Function(AppEnv env);

/// Result of a successful [AppBootstrap.run].
class AppBootstrapResult {
  const AppBootstrapResult({required this.prefs, required this.crashReporter});
  final SharedPreferences prefs;
  final CrashReporter crashReporter;
}

/// Startup sequence. Services behind a disabled flag are never touched.
class AppBootstrap {
  AppBootstrap({
    required this.flags,
    this.env = const AppEnv(),
    this.initSupabase = _defaultInitSupabase,
    this.initRevenueCat = _defaultInitRevenueCat,
    this.configureDeps = configureDependencies,
    this.initCrashReporting = initFirebaseCrashReporter,
    this.isRelease = kReleaseMode,
  });

  final FeatureFlags flags;
  final AppEnv env;
  final EnvInitializer initSupabase;
  final EnvInitializer initRevenueCat;
  final Future<void> Function() configureDeps;
  final CrashReporterInitializer initCrashReporting;
  final bool isRelease;

  Future<AppBootstrapResult> run() async {
    env.validateFor(flags);

    final prefs = await SharedPreferences.getInstance();
    final crashReporter = await selectCrashReporter(
      isRelease: isRelease,
      env: env,
      userEnabled: prefs.getBool(StorageKeys.crashReportingEnabled) ?? true,
      initFirebase: initCrashReporting,
    );
    installCrashHandlers(crashReporter);

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
    return AppBootstrapResult(prefs: prefs, crashReporter: crashReporter);
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
