#!/bin/bash
# Checks the merged Android manifests of example_app (issue #102):
# the release manifest must not request the permissions of frozen features,
# the debug manifest must still have them (FF_* flag testing).
#
#   ./scripts/check-android-manifest.sh [build-dir]
#
# Run after `./gradlew :app:processReleaseMainManifest :app:processDebugMainManifest`
# in example_app/android. build-dir defaults to example_app/build.
# Keep STRIPPED in sync with example_app/android/app/src/release/AndroidManifest.xml.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
BUILD_DIR="${1:-example_app/build}"
STRIPPED=(
  android.permission.INTERNET
  android.permission.ACCESS_NETWORK_STATE
  android.permission.RECORD_AUDIO
  com.android.vending.BILLING
)
status=0

fail() {
  echo "FAIL: $1"
  [ -n "${GITHUB_ACTIONS:-}" ] && echo "::error title=android manifest::$1"
  status=1
}

manifest_for() { # $1=variant (release|debug)
  # Only the :app module; plugin subprojects have their own merged manifests.
  find "$BUILD_DIR/app/intermediates/merged_manifest/$1" -name AndroidManifest.xml 2>/dev/null | head -n 1
}

permissions_of() { # $1=manifest file: one permission name per line
  # Merged manifests put attributes on their own lines; flatten first.
  tr '\n' ' ' <"$1" | grep -oE '<uses-permission[^>]*android:name="[^"]+"' \
    | sed -E 's/.*android:name="([^"]+)".*/\1/' | sort -u
}

for variant in release debug; do
  manifest=$(manifest_for "$variant")
  if [ -z "$manifest" ]; then
    fail "no merged $variant manifest under $BUILD_DIR"
    continue
  fi
  perms=$(permissions_of "$manifest")
  echo "== $variant permissions ($manifest)"
  echo "${perms:-<none>}"
  for p in "${STRIPPED[@]}"; do
    has=$(grep -Fxc "$p" <<<"$perms")
    if [ "$variant" = release ] && [ "$has" -ne 0 ]; then
      fail "release manifest still requests $p"
    elif [ "$variant" = debug ] && [ "$has" -eq 0 ]; then
      fail "debug manifest lost $p"
    fi
  done
done

[ "$status" -eq 0 ] && echo "OK: release strips ${#STRIPPED[@]} frozen-feature permissions, debug keeps them"
exit "$status"
