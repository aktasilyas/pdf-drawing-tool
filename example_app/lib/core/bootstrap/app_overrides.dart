import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/drawing_ui.dart' as drawing_ui;

import 'package:example_app/core/bootstrap/recording_limit_overrides.dart';
import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/crash_reporting/crash_reporter.dart';
import 'package:example_app/core/crash_reporting/noop_crash_reporter.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';

/// Root [ProviderScope] overrides.
///
/// Recording-limit and watermark overrides depend on the subscription tier,
/// so they are only installed when the premium flag is on.
List<Override> buildAppOverrides({
  required FeatureFlags flags,
  required SharedPreferences prefs,
  CrashReporter crashReporter = const NoopCrashReporter(),
}) {
  return [
    featureFlagsProvider.overrideWithValue(flags),
    sharedPreferencesProvider.overrideWithValue(prefs),
    crashReporterProvider.overrideWithValue(crashReporter),
    drawing_ui.sharedPreferencesProvider.overrideWithValue(prefs),
    drawing_ui.aiAssistantEnabledProvider.overrideWithValue(flags.aiChat),
    drawing_ui.audioRecordingEnabledProvider
        .overrideWithValue(flags.audioRecording),
    if (flags.premium) ...premiumRecordingOverrides(),
  ];
}
