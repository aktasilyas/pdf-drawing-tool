import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/constants/storage_keys.dart';
import 'package:example_app/core/crash_reporting/crash_reporter.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';

/// Whether the user allows anonymous crash reports (default on).
final crashReportingEnabledProvider =
    StateNotifierProvider<CrashReportingEnabledNotifier, bool>((ref) {
  return CrashReportingEnabledNotifier(
    ref.watch(sharedPreferencesProvider),
    ref.watch(crashReporterProvider),
  );
});

class CrashReportingEnabledNotifier extends StateNotifier<bool> {
  CrashReportingEnabledNotifier(this._prefs, this._reporter)
      : super(_prefs.getBool(StorageKeys.crashReportingEnabled) ?? true);

  final SharedPreferences _prefs;
  final CrashReporter _reporter;

  Future<void> set(bool enabled) async {
    state = enabled;
    await _prefs.setBool(StorageKeys.crashReportingEnabled, enabled);
    await _reporter.setCollectionEnabled(enabled);
  }
}
