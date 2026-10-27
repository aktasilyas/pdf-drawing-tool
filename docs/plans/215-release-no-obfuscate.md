# #215 Release: no Dart obfuscation, automatic R8 mapping upload

Goal: a solo maintainer uploads no symbols by hand.

## Design
- `release.yml`: `flutter build appbundle --release` without `--obfuscate`/`--split-debug-info`.
  Artifact `…-mapping` keeps only R8's `mapping.txt` (fallback for Play Console ReTrace).
  PR trigger also covers `android/settings.gradle.kts` and `android/build.gradle.kts`.
- The Crashlytics Gradle plugin (3.x) uploads mapping.txt only with the google-services
  plugin's output (firebase-android-sdk#1560; v3 requires google-services 4.4.1+). So:
  - add `com.google.gms.google-services` 4.4.2, applied before Crashlytics, with
    `missingGoogleServicesStrategy = WARN` so local/PR builds without the file pass;
  - `scripts/release-secrets.sh` writes `android/app/google-services.json` (git-ignored)
    from the four `FIREBASE_*` secrets, next to `config/firebase.json`;
  - `mappingFileUploadEnabled = file("google-services.json").exists()`; native symbols off.
- Native default FirebaseApp now auto-initialises from the generated resources. FlutterFire's
  `initializeApp(options)` accepts an existing default app when the apiKey matches (same
  secret), and storage bucket / database URL are omitted on purpose. Collection stays off
  until the user's opt-in (manifest `firebase_crashlytics_collection_enabled=false`).
- Root `.gitignore`: `*.jks`, `*.keystore`, `key.properties`.

## Verification
- `release-secrets.sh` with dummy values → valid `google-services.json`.
- CI: release.yml PR run and android-manifest.yml build the release without Firebase config.
- Firebase-on path: one manual `workflow_dispatch` before v1.0 (release checklist step 6).
