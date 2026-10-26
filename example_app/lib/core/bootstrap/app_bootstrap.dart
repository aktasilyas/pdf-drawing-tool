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
    this.resetDeps = resetDependencies,
  });

  final FeatureFlags flags;
  final AppEnv env;
  final EnvInitializer initSupabase;
  final EnvInitializer initRevenueCat;
  final Future<void> Function() configureDeps;
  final CrashReporterInitializer initCrashReporting;
  final bool isRelease;

  /// Undoes a partial [configureDeps] so [run] can be called again (Retry).
  final Future<void> Function() resetDeps;

  /// Selected once and reused by later runs, so a Retry never initializes
  /// Firebase twice.
  CrashReporter? _crashReporter;

  /// Runs the startup sequence. Safe to call again after it threw: failed
  /// registrations are reset first. Errors after the crash reporter exists
  /// are reported to it (not logged; the caller logs) and rethrown.
  Future<AppBootstrapResult> run() async {
    env.validateFor(flags);

    final prefs = await SharedPreferences.getInstance();
    final crashReporter = _crashReporter ?? await _selectReporter(prefs);
    _crashReporter = crashReporter;

    try {
      if (flags.needsSupabase) {
        // Out of v1.0 scope: a Retry after a failed Supabase init would call
        // Supabase.initialize twice (frozen cloud-sync flag only).
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
    } catch (error, stack) {
      await _report(crashReporter, error, stack);
      await _resetQuietly();
      rethrow;
    }
    return AppBootstrapResult(prefs: prefs, crashReporter: crashReporter);
  }

  Future<CrashReporter> _selectReporter(SharedPreferences prefs) async {
    final reporter = await selectCrashReporter(
      isRelease: isRelease,
      env: env,
      userEnabled: prefs.getBool(StorageKeys.crashReportingEnabled) ?? true,
      initFirebase: initCrashReporting,
    );
    installCrashHandlers(reporter);
    return reporter;
  }

  Future<void> _report(
    CrashReporter reporter,
    Object error,
    StackTrace stack,
  ) async {
    if (!reporter.isActive) return;
    try {
      // Not fatal: the user can recover with Retry.
      await reporter.recordError(error, stack);
    } catch (e) {
      logger.w('Could not report startup error: $e');
    }
  }

  Future<void> _resetQuietly() async {
    try {
      await resetDeps();
    } catch (e) {
      logger.w('Dependency reset after failed startup failed: $e');
    }
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
