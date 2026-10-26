# Android release checklist

Workflow: `.github/workflows/release.yml` (#192). It builds a signed, R8-shrunk and
obfuscated App Bundle, verifies the signature, and starts the release build on an emulator.

## One-time setup (owner)
1. Create the upload key (keep it and both passwords outside the repo, with a backup):
   `keytool -genkeypair -v -keystore upload-keystore.jks -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. In Play Console, enroll the app in Play App Signing; this keystore is the **upload key**.
3. Repository secrets (Settings → Secrets and variables → Actions):
   - `ANDROID_KEYSTORE_BASE64` = output of `base64 -w0 upload-keystore.jks`
   - `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (`upload`), `ANDROID_KEY_PASSWORD`
   - Optional crash reporting (#60): `FIREBASE_API_KEY`, `FIREBASE_APP_ID`,
     `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID` (all four or none).
4. Local release builds (optional): `example_app/android/key.properties` (git-ignored) with
   `storeFile=<path to .jks>`, `storePassword=`, `keyAlias=`, `keyPassword=`. Without it,
   `flutter build --release` falls back to debug signing.

## Each release
1. Bump `version:` in `example_app/pubspec.yaml` (versionName only; no `+build`).
2. Merge to `main`, then tag and push: `git tag v1.0.0 && git push origin v1.0.0`
   (format `vMAJOR.MINOR.PATCH`, must match the pubspec version you intend to ship).
3. Wait for both jobs of the **Release** run to pass. A missing secret fails the first job
   with an error naming it.
4. Download the artifacts: `elyanotes-<version>-<code>-aab` and `…-symbols`.
5. Upload the `.aab` to the Play internal testing track; promote after testing.
6. Crash reporting: the build is obfuscated and nothing is uploaded automatically. Upload
   `mapping.txt` in Play Console (App bundle explorer → Downloads → ReTrace mapping file),
   and the Dart symbols with
   `firebase crashlytics:symbols:upload --app=<FIREBASE_APP_ID> symbols/`. Without this,
   Dart stack traces in Crashlytics are unreadable.
7. Keep the symbols artifact (download it; Actions artifacts expire after 90 days).

## Version code
`versionCode = run number of the Release workflow + 100`. It only grows while the file
name stays `release.yml`: never rename or recreate it. Re-running a run reuses its code;
do not upload the same code twice.
