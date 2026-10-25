import 'package:flutter/foundation.dart';

import 'package:example_app/core/crash_reporting/crash_reporter.dart';

/// Reporter used in debug builds, without Firebase config, or on init failure.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  bool get isActive => false;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}
}
