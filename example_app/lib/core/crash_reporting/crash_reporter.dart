import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/crash_reporting/noop_crash_reporter.dart';

/// Sink for unexpected errors. Implementations must never send personal data.
abstract interface class CrashReporter {
  /// Whether reports can actually leave the device.
  bool get isActive;

  /// Applies the user's opt-in / opt-out choice at runtime.
  Future<void> setCollectionEnabled(bool enabled);

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  });

  Future<void> recordFlutterError(FlutterErrorDetails details);
}

/// Defaults to a no-op; the root scope overrides it with the bootstrap result.
final crashReporterProvider = Provider<CrashReporter>(
  (ref) => const NoopCrashReporter(),
);
