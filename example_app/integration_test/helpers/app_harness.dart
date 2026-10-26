import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/bootstrap/app_bootstrap.dart';
import 'package:example_app/core/bootstrap/app_overrides.dart';
import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/di/injection.dart';
import 'package:example_app/main.dart' show ElyaNotesApp;

/// Call first in every integration test file's `main()`.
IntegrationTestWidgetsFlutterBinding initE2E() =>
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

/// Wipes everything the v1.0 app persists.
///
/// Notebooks, folders, trash and settings live in SharedPreferences (the
/// Drift database is only used by the frozen AI feature), so clearing the
/// prefs and dropping the GetIt registrations gives a first-launch state.
Future<void> resetAppState() async {
  await getIt.reset();
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

/// Boots the app like `main()` does, with all feature flags off, from a clean
/// storage state. Crash reporting stays a no-op (`isRelease: false`), and
/// Supabase / RevenueCat are never initialised because their flags are off.
///
/// Returns once the widget tree is pumped; the caller waits for the splash
/// screen (see `LibraryRobot.waitForLibrary`).
Future<void> launchApp(WidgetTester tester) async {
  await resetAppState();

  const flags = FeatureFlags.allOff;
  final result = await AppBootstrap(flags: flags, isRelease: false).run();

  await tester.pumpWidget(
    ProviderScope(
      overrides: buildAppOverrides(
        flags: flags,
        prefs: result.prefs,
        crashReporter: result.crashReporter,
      ),
      child: const ElyaNotesApp(),
    ),
  );
  await tester.pump();
}
