import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'package:example_app/core/crash_reporting/crash_reporter.dart';
import 'package:example_app/core/crash_reporting/pii_scrubber.dart';

/// Replacement for the original error: only its type and a scrubbed message
/// reach Crashlytics, never the raw object.
class ScrubbedError {
  const ScrubbedError({required this.type, required this.message});

  final String type;
  final String message;

  @override
  String toString() => '$type: $message';
}

/// Crashlytics-backed reporter. Sends no user id, logs or custom keys.
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  bool get isActive => true;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    if (!enabled) {
      await _crashlytics.deleteUnsentReports();
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) {
    return _crashlytics.recordError(
      ScrubbedError(
        type: error.runtimeType.toString(),
        message: scrubPii(error.toString()),
      ),
      stack == null ? null : scrubStackTrace(stack),
      printDetails: false,
      fatal: fatal,
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) {
    final stack = details.stack;
    final context = details.context?.toDescription();
    return _crashlytics.recordError(
      ScrubbedError(
        type: details.exception.runtimeType.toString(),
        message: scrubPii(details.exceptionAsString()),
      ),
      stack == null ? null : scrubStackTrace(stack),
      reason: context == null ? null : scrubPii(context),
      printDetails: false,
    );
  }
}
