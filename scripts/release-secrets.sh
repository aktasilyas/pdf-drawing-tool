#!/bin/bash
# Release signing setup for .github/workflows/release.yml (#192).
# Reads ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS,
# ANDROID_KEY_PASSWORD (and optional FIREBASE_*) from the environment, decodes
# the keystore and hands the Gradle signing values to later steps via
# $GITHUB_ENV. Fails with one clear error naming every missing secret.
# Never prints secret values.
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

required=(ANDROID_KEYSTORE_BASE64 ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD)
missing=()
for name in "${required[@]}"; do
  [ -n "${!name:-}" ] || missing+=("$name")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "::error title=Release signing::Missing repository secrets: ${missing[*]}. See docs/store/release-checklist.md."
  exit 1
fi

out_dir="${RUNNER_TEMP:-$(mktemp -d)}"
keystore="$out_dir/upload-keystore.jks"
if ! printf '%s' "$ANDROID_KEYSTORE_BASE64" | base64 --decode >"$keystore" 2>/dev/null || [ ! -s "$keystore" ]; then
  echo "::error title=Release signing::ANDROID_KEYSTORE_BASE64 is not valid base64 (use: base64 -w0 upload-keystore.jks)."
  exit 1
fi

env_file="${GITHUB_ENV:-/dev/null}"
{
  echo "ANDROID_KEYSTORE_PATH=$keystore"
  echo "ANDROID_KEYSTORE_PASSWORD=$ANDROID_KEYSTORE_PASSWORD"
  echo "ANDROID_KEY_ALIAS=$ANDROID_KEY_ALIAS"
  echo "ANDROID_KEY_PASSWORD=$ANDROID_KEY_PASSWORD"
  echo "ELYANOTES_REQUIRE_RELEASE_SIGNING=true"
} >>"$env_file"
echo "Release keystore decoded to $keystore"

# Optional crash reporting config (#60): all four values or none.
firebase=(FIREBASE_API_KEY FIREBASE_APP_ID FIREBASE_PROJECT_ID FIREBASE_MESSAGING_SENDER_ID)
present=0
for name in "${firebase[@]}"; do
  [ -n "${!name:-}" ] && present=$((present + 1))
done
if [ "$present" -eq ${#firebase[@]} ]; then
  jq -n \
    --arg k "$FIREBASE_API_KEY" --arg a "$FIREBASE_APP_ID" \
    --arg p "$FIREBASE_PROJECT_ID" --arg s "$FIREBASE_MESSAGING_SENDER_ID" \
    '{FIREBASE_API_KEY: $k, FIREBASE_APP_ID: $a, FIREBASE_PROJECT_ID: $p, FIREBASE_MESSAGING_SENDER_ID: $s}' \
    >example_app/config/firebase.json
  echo "Firebase config written (crash reporting on)."
elif [ "$present" -gt 0 ]; then
  echo "::warning title=Firebase::Only $present of ${#firebase[@]} FIREBASE_* secrets set; building without crash reporting."
else
  echo "No FIREBASE_* secrets; building without crash reporting."
fi
