import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/drawing_ui.dart' as drawing_ui;

import 'package:example_app/core/bootstrap/recording_limit_overrides.dart';
import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';

/// Root [ProviderScope] overrides.
///
/// Recording-limit and watermark overrides depend on the subscription tier,
/// so they are only installed when the premium flag is on.
List<Override> buildAppOverrides({
  required FeatureFlags flags,
  required SharedPreferences prefs,
}) {
  return [
    featureFlagsProvider.overrideWithValue(flags),
    sharedPreferencesProvider.overrideWithValue(prefs),
    drawing_ui.sharedPreferencesProvider.overrideWithValue(prefs),
    if (flags.premium) ...premiumRecordingOverrides(),
  ];
}
