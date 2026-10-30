#!/bin/bash
# Self-test for scripts/check-16kb-alignment.sh (#584): builds two tiny x86_64
# shared libraries with gcc (4 KB and 16 KB max page size), packs each into a
# bundle-shaped zip (base/lib/x86_64/) and expects the check to fail on the
# first and pass on the second. Needs gcc, zip and readelf (ubuntu runners).
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
CHECK=scripts/check-16kb-alignment.sh
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
status=0

echo 'int answer(void) { return 42; }' >"$work/answer.c"

# $1 = max page size, $2 = output bundle path
make_bundle() {
  local dir="$work/b$1"
  mkdir -p "$dir/base/lib/x86_64"
  gcc -shared -fPIC -Wl,-z,max-page-size="$1" -Wl,-z,common-page-size="$1" \
    -o "$dir/base/lib/x86_64/libanswer.so" "$work/answer.c" || exit 1
  (cd "$dir" && zip -q -0 -r "$2" base) || exit 1
}

make_bundle 4096 "$work/aligned4k.aab"
make_bundle 16384 "$work/aligned16k.aab"

out=$("$CHECK" "$work/aligned4k.aab" 2>&1)
code=$?
echo "$out" | sed 's/^::error/(expected) error/'
if [ "$code" -eq 0 ]; then
  echo "::error title=16 KB self-test::4 KB-aligned library passed the check"
  status=1
elif ! echo "$out" | grep -q '::error.*lib/x86_64/libanswer.so'; then
  echo "::error title=16 KB self-test::no ::error annotation naming the library"
  status=1
fi

if ! "$CHECK" "$work/aligned16k.aab"; then
  echo "::error title=16 KB self-test::16 KB-aligned library failed the check"
  status=1
fi

# $1 = description; the rest = command expected to fail.
expect_fail() {
  local what="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "::error title=16 KB self-test::$what passed the check"
    status=1
  fi
}

expect_fail "missing input" "$CHECK" "$work/missing.apk"

# Bundle without any native library (wrong layout must not pass silently).
mkdir -p "$work/empty/base/manifest" && touch "$work/empty/base/manifest/AndroidManifest.xml"
(cd "$work/empty" && zip -q -r "$work/nolibs.aab" base) || exit 1
expect_fail "bundle without native libraries" "$CHECK" "$work/nolibs.aab"

# APK path: aligned ELF but no zipalign available must fail closed.
(cd "$work/b16384/base" && zip -q -0 -r "$work/aligned16k.apk" lib) || exit 1
expect_fail "APK without zipalign" env ZIPALIGN=/nonexistent "$CHECK" "$work/aligned16k.apk"

# .apks without universal.apk.
cp "$work/aligned16k.aab" "$work/nouniversal.apks"
expect_fail ".apks without universal.apk" "$CHECK" "$work/nouniversal.apks"

[ "$status" -eq 0 ] && echo "16 KB alignment self-test passed."
exit "$status"
