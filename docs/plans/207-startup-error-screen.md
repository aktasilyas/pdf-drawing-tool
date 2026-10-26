# 207 — Recoverable startup error screen

Issue: #207. Reviewed by the `architect` subagent before implementation.

## Design
- `AppBootstrap.run()` keeps the crash reporter on the instance (a Retry never
  initializes Firebase twice). Errors after the reporter exists are sent to it
  (`fatal: false`, only when active), dependencies are reset, and the error is
  rethrown. Errors before that (env validation, SharedPreferences) just throw.
- `resetDependencies()` closes an already registered `AppDatabase` and resets
  GetIt so `configureDependencies()` can run again. It never touches files.
  `PrefsToDriftMigration` is idempotent (transaction + insert-or-ignore), so a
  rerun on Retry is safe.
- `attemptStartup()` runs a bootstrap, never throws, and logs once via `logger`.
- `StartupGate` (root widget): success → `appBuilder(result)` (the
  `ProviderScope` + `ElyaNotesApp`); failure → `StartupErrorApp` with one
  Retry button (disabled while retrying, `mounted` checked after the await).
- `main()` makes the first attempt before `runApp`, so the happy path keeps the
  native splash until the library's first frame (nothing calls
  `FlutterNativeSplash.preserve`).
- Out of v1.0 scope: Retry after a failed `Supabase.initialize` (frozen flag).

## Reference check
GoodNotes, StarNote and Flexcil do not document a startup-failure screen.
Platform convention (Play pre-launch report: no silent hang) → a calm
message, a "your notes are safe" line and one primary Retry button, no
destructive options.

## Tests
- `test/core/bootstrap/app_bootstrap_test.dart`: report + reset + rethrow,
  inactive reporter untouched, no reset on success, Retry reuses the reporter.
- `test/core/bootstrap/startup_gate_test.dart`: error screen, Retry → app,
  Retry failing again, no parallel bootstraps, 48dp tap targets.
- `test/core/bootstrap/startup_error_golden_test.dart`: phone light/dark,
  tablet light.
