# Plan: #192 Signed Android App Bundle on version tags

Reference check: not applicable (CI/build infrastructure, no product behaviour). Standard
Play App Signing flow; our keystore is the upload key.

## Acceptance criteria
- AC1: Missing secrets fail the workflow with an `::error` naming each missing secret.
- AC2: With secrets present the `.aab` is release-signed: `jarsigner -verify -strict` passes
  (exit 4 = self-signed chain allowed) and the signer SHA-256 matches the keystore.
- AC3: The release build (R8 + obfuscated) starts on an emulator with no crash.
- AC4: `android-manifest.yml` (unsigned `flutter build apk --release`) stays green.
- AC5: Workflow-file PR: architect marks `needs-owner-review` for a manual merge.

## Steps
1. `build.gradle.kts`: release signingConfig from env `ANDROID_KEYSTORE_PATH/_PASSWORD`,
   `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, else `android/key.properties`; else debug
   signing, unless `ELYANOTES_REQUIRE_RELEASE_SIGNING=true` (set only by the release
   workflow) → GradleException. `isMinifyEnabled`/`isShrinkResources` explicit;
   `proguard-rules.pro` (Crashlytics attributes, `-dontwarn` Play Core). Mapping upload
   stays off; obfuscation overrides the #60 "no obfuscation" note (symbols uploaded by hand).
2. `scripts/release-secrets.sh`: validate the four ANDROID_* values, decode the keystore to
   `$RUNNER_TEMP`, export via `$GITHUB_ENV`; write `config/firebase.json` only when all four
   FIREBASE_* are set.
3. `scripts/release-smoke.sh`: install the universal APK, start MainActivity, assert the
   process lives 20 s and logcat has no crash for the package; one retry.
4. `.github/workflows/release.yml`: tags `v*`, dispatch, and PRs touching the release setup.
   PR runs assert the missing-secret failure, then use a throwaway keystore through the same
   script. Tag/dispatch: analyze + test, versionName from the tag (semver checked) or pubspec,
   versionCode `run_number + 100`, `--obfuscate --split-debug-info`, signature + fingerprint
   check, artifacts (.aab, mapping.txt, symbols). Smoke job on API 34 x86_64 emulator
   with bundletool universal APKs built in the bundle job.
5. `docs/store/release-checklist.md`.

## Risks
versionCode resets if the workflow is renamed; obfuscated Dart traces need manual symbol
upload; `shrinkResources` could drop name-looked-up resources (smoke test guards); emulator
flakiness (one retry); future AGP/Flutter bumps may add R8 missing-class errors.
