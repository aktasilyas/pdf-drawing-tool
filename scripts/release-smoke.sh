#!/bin/bash
# Release smoke test on a running emulator (#192): installs the universal APK
# from a bundletool .apks archive, starts the app and checks that it is still
# running without a crash. Usage: scripts/release-smoke.sh <app.apks> [package]
set -uo pipefail

apks="${1:?usage: release-smoke.sh <app.apks> [package]}"
package="${2:-com.aktasilyas.elyanotes}"
work=$(mktemp -d)

unzip -o -q "$apks" universal.apk -d "$work" || { echo "::error::universal.apk not found in $apks"; exit 1; }

attempt() {
  adb uninstall "$package" >/dev/null 2>&1 || true
  adb install -r "$work/universal.apk" || return 1
  adb logcat -c
  adb shell am start -W -n "$package/.MainActivity" || return 1
  sleep 20
  local log
  log=$(adb logcat -d)
  if ! adb shell pidof "$package" >/dev/null; then
    echo "::error title=Release smoke::$package is not running 20 s after launch"
    echo "$log" | tail -n 200
    return 1
  fi
  # Only this app's crashes count; other emulator processes may log their own.
  if echo "$log" | grep -A2 'FATAL EXCEPTION' | grep -q "Process: $package" ||
    echo "$log" | grep -E 'flutter.*Unhandled Exception'; then
    echo "::error title=Release smoke::crash or Flutter error in logcat"
    echo "$log" | tail -n 200
    return 1
  fi
  echo "Release smoke passed: $package running, no crash in logcat."
}

# One retry for emulator start-up flakiness; a second failure is real.
attempt || { echo "Retrying once..."; sleep 10; attempt; }
