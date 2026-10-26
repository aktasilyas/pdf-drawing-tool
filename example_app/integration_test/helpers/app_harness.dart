import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/bootstrap/app_bootstrap.dart';
import 'package:example_app/core/bootstrap/app_overrides.dart';
import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/database/app_database.dart';
import 'package:example_app/core/di/injection.dart';
import 'package:example_app/main.dart' show ElyaNotesApp;

/// Call first in every integration test file's `main()`.
IntegrationTestWidgetsFlutterBinding initE2E() =>
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

/// File name of the app database (see `AppDatabase._openConnection`).
const _databaseFile = 'elyanotes.db';

/// Closes the open [AppDatabase] (if any) and drops the GetIt registrations,
/// so the next bootstrap opens a fresh connection instead of a second one on
/// the same file.
Future<void> _closeDatabase() async {
  if (getIt.isRegistered<AppDatabase>()) {
    await getIt<AppDatabase>().close();
  }
  await getIt.reset();
}

/// Wipes everything the v1.0 app persists.
///
/// Notebooks, folders, page content and trash live in the Drift database
/// (`elyanotes.db` in the documents directory); settings live in
/// SharedPreferences. Closing the database, deleting its files and clearing
/// the prefs gives a first-launch state.
Future<void> resetAppState() async {
  await _closeDatabase();
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, _databaseFile);
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final file = File('$dbPath$suffix');
    if (file.existsSync()) await file.delete();
  }
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
  await _bootApp(tester);
}

/// Simulates killing and reopening the app: unmounts the tree, closes the
/// database and boots again **without** wiping storage, so persistence flows
/// can check what survived.
Future<void> relaunchApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await _closeDatabase();
  await _bootApp(tester);
}

Future<void> _bootApp(WidgetTester tester) async {
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
