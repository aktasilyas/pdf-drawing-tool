#!/bin/bash
# Runs one shard of the e2e suite on the connected device/emulator.
# Usage (from example_app/): ../scripts/e2e-run.sh <shard> [out-dir]
#   phone-a  flows listed in PHONE_A
#   phone-b  every other integration_test/*_test.dart (new files land here)
#   tablet   smoke subset in TABLET
#   all      the whole suite
# Writes test.log, final-screen.png and logcat.txt to out-dir (default
# $RUNNER_TEMP/e2e) and creates out-dir/failed when a test fails; the
# workflow reports from there. Never exits non-zero for a test failure.
set -uo pipefail

shard="${1:?usage: e2e-run.sh <phone-a|phone-b|tablet|all> [out-dir]}"
out="${2:-${RUNNER_TEMP:-/tmp}/e2e}"

PHONE_A=(app_launch_test notebook_crud_test folders_trash_test
  editor_ink_test editor_pages_test)
TABLET=(app_launch_test notebook_crud_test settings_test)

all_tests() {
  for f in integration_test/*_test.dart; do basename "$f" .dart; done
}

case "$shard" in
  phone-a) names=("${PHONE_A[@]}") ;;
  phone-b)
    names=()
    while read -r n; do
      [[ " ${PHONE_A[*]} " == *" $n "* ]] || names+=("$n")
    done < <(all_tests)
    ;;
  tablet) names=("${TABLET[@]}") ;;
  all) mapfile -t names < <(all_tests) ;;
  *) echo "unknown shard: $shard" >&2; exit 2 ;;
esac

files=()
for n in "${names[@]}"; do
  if [ ! -f "integration_test/$n.dart" ]; then
    echo "missing test file: integration_test/$n.dart" >&2
    exit 2
  fi
  files+=("integration_test/$n.dart")
done

mkdir -p "$out"
echo "e2e shard $shard: ${files[*]}" | tee "$out/test.log"
flutter test "${files[@]}" --no-pub >>"$out/test.log" 2>&1 || touch "$out/failed"
adb exec-out screencap -p >"$out/final-screen.png" || true
adb logcat -d -v time >"$out/logcat.txt" || true
