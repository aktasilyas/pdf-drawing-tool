import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'package:example_app/core/config/app_env.dart';
import 'package:example_app/core/crash_reporting/crash_reporter.dart';
import 'package:example_app/core/crash_reporting/firebase_crash_reporter.dart';
import 'package:example_app/core/crash_reporting/noop_crash_reporter.dart';
import 'package:example_app/core/utils/logger.dart';

typedef CrashReporterInitializer = Future<CrashReporter> Function(AppEnv env);

/// Picks the reporter for this run.
///
/// Firebase is touched only in release builds with complete config. The
/// user's stored choice is applied before any report can be sent.
Future<CrashReporter> selectCrashReporter({
  required bool isRelease,
  required AppEnv env,
  required bool userEnabled,
  required CrashReporterInitializer initFirebase,
}) async {
  if (!isRelease || !env.hasFirebaseConfig) {
    return const NoopCrashReporter();
  }
  try {
    final reporter = await initFirebase(env);
    await reporter.setCollectionEnabled(userEnabled);
    return reporter;
  } catch (e, s) {
    logger.e('Crash reporting init failed', error: e, stackTrace: s);
    return const NoopCrashReporter();
  }
}

/// Routes uncaught errors to [reporter]. Does nothing for inactive reporters.
void installCrashHandlers(CrashReporter reporter) {
  if (!reporter.isActive) return;
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reporter.recordFlutterError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Default initializer: Firebase from `--dart-define` values, no
/// `google-services.json`.
Future<CrashReporter> initFirebaseCrashReporter(AppEnv env) async {
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: env.firebaseApiKey,
      appId: env.firebaseAppId,
      messagingSenderId: env.firebaseMessagingSenderId,
      projectId: env.firebaseProjectId,
    ),
  );
  return FirebaseCrashReporter(FirebaseCrashlytics.instance);
}
