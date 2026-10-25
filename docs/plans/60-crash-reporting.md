# Plan #60 — Crash reporting (Firebase Crashlytics)

Owner decision (issue #60, 2026-10-25): Firebase Crashlytics; on by default in
release, opt-out in Settings, never in debug; PII scrubbed; store docs updated.

## Key finding
Issue #102 strips `INTERNET` / `ACCESS_NETWORK_STATE` from the release manifest.
Crashlytics cannot upload without them, so this change keeps both in release,
updates `scripts/check-android-manifest.sh`, and corrects the privacy policy
("does not use the network") and Play Data safety notes.

## Acceptance criteria
- AC1: `flutter run`, CI analyze/test and a release build work with no Firebase
  config and no `google-services.json`.
- AC2: Crashlytics is active only when `kReleaseMode`, all four `FIREBASE_*`
  dart-defines are present and the user has not opted out; otherwise a no-op
  reporter is used and Firebase is never initialized.
- AC3: `FlutterError.onError` and `PlatformDispatcher.instance.onError` are
  reported after scrubbing; no file paths, URIs, quoted strings, emails or
  widget diagnostics; never `setUserIdentifier`, `log`, `setCustomKey`.
- AC4: Settings switch "Çökme raporlarını gönder" (default on), persisted in
  SharedPreferences; toggles `setCrashlyticsCollectionEnabled` at runtime;
  turning off also calls `deleteUnsentReports`.
- AC5: native auto-collection off by default (manifest meta-data) until Dart
  applies the user's choice.
- AC6: privacy policy (EN+TR) and Play Data safety notes describe crash
  reporting; a needs-owner issue lists the Firebase project steps.

## Design
- `example_app/lib/core/crash_reporting/`: `CrashReporter` interface +
  `crashReporterProvider` (default no-op), `NoopCrashReporter`,
  `FirebaseCrashReporter` (sends a `ScrubbedError(type, message)` and a
  scrubbed stack; never forwards the raw error or `informationCollector`),
  pure `scrubPii` / `scrubStackTrace`, `selectCrashReporter` and
  `installCrashHandlers`.
- Firebase is initialized with `FirebaseOptions` from `--dart-define`
  (`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID`,
  `FIREBASE_MESSAGING_SENDER_ID`) read in `AppEnv`; no `google-services.json`
  and no google-services Gradle plugin.
- The Crashlytics Gradle plugin is applied only for the build-ID resource the
  SDK requires; mapping and native symbol upload are off (no credentials in
  builds; Dart stacks are readable without `--obfuscate`).
- Bootstrap: prefs → stored opt-out (default true) → reporter → handlers (only
  when active) → rest. Failure to init falls back to no-op.
- Settings: `crashReportingEnabledProvider` (prefs source of truth) and a
  `CrashReportingSetting` tile in a new "GİZLİLİK" section.
- No `FF_*` flag: release mode + config presence + user setting is the gate.

## Steps
1. Scrubber (TDD).
2. Dependencies (`firebase_core ^4.15.2`, `firebase_crashlytics ^5.4.1`), Gradle
   plugin with uploads off, manifest meta-data, release manifest un-strip,
   manifest check script, release APK build in the Android workflow,
   `.gitignore`, `config/firebase.example.json`.
3. Reporter interface and implementations + tests.
4. Selection, handlers, bootstrap, overrides, `AppEnv` + tests.
5. Settings toggle + widget tests.
6. Store docs; needs-owner issue for the Firebase project.

## Risks / omissions
- Native (Java/Kotlin) exception messages are not scrubbable; NDK crashes out
  of scope. Crashes before Firebase init are not captured.
- Out of scope: Analytics, breadcrumbs, custom keys, iOS, first-run consent
  dialog.

## Reference check
GoodNotes discloses anonymous crash data (Firebase among others) in its privacy
policy with no in-app toggle; no public statement found for StarNote/Flexcil.
Common pattern: anonymous crash data on by default, disclosed. We follow it and
add an in-app opt-out (owner decision), fitting an offline-first app.
