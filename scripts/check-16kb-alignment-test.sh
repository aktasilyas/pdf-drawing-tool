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

if "$CHECK" "$work/missing.apk" >/dev/null 2>&1; then
  echo "::error title=16 KB self-test::missing input passed the check"
  status=1
fi

[ "$status" -eq 0 ] && echo "16 KB alignment self-test passed."
exit "$status"
