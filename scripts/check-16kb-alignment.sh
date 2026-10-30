#!/bin/bash
# Fails when the Android build is not 16 KB page-size compatible (#584), which
# Google Play requires for apps targeting Android 15+
# (https://developer.android.com/guide/practices/page-sizes).
#
#   ./scripts/check-16kb-alignment.sh <app.apk | app.aab | app.apks>
#
# - Every lib/{arm64-v8a,x86_64}/*.so (base/lib/... in a bundle) must have all
#   ELF LOAD segments aligned to at least 2**14 (readelf -lW).
# - An APK (or the universal.apk inside a bundletool .apks) must also pass
#   `zipalign -c -P 16 -v 4`, so uncompressed libraries sit on 16 KB
#   boundaries. zipalign comes from the newest $ANDROID_HOME/build-tools
#   (or $ZIPALIGN); needs build-tools 35+.
# Each offending library is printed as a GitHub ::error annotation.
set -uo pipefail

input="${1:-}"
if [ -z "$input" ] || [ ! -f "$input" ]; then
  echo "::error title=16 KB page size::input not found: '${input}' (usage: $0 <apk|aab|apks>)"
  exit 2
fi

READELF="${READELF:-readelf}"
MIN_ALIGN=16384
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
status=0

apk=""
case "$input" in
  *.apks)
    unzip -q -o "$input" universal.apk -d "$work" || {
      echo "::error title=16 KB page size::no universal.apk in $input"
      exit 2
    }
    apk="$work/universal.apk"
    ;;
  *.apk) apk="$input" ;;
  *.aab) ;;
  *)
    echo "::error title=16 KB page size::unsupported input '$input' (expected .apk, .aab or .apks)"
    exit 2
    ;;
esac
archive="${apk:-$input}"

# ELF LOAD segment alignment of every 64-bit library.
mkdir -p "$work/x"
unzip -q -o "$archive" 'lib/arm64-v8a/*.so' 'lib/x86_64/*.so' \
  'base/lib/arm64-v8a/*.so' 'base/lib/x86_64/*.so' -d "$work/x" 2>/dev/null
mapfile -t libs < <(cd "$work/x" && find . -name '*.so' -type f | sed 's|^\./||' | sort)
if [ "${#libs[@]}" -eq 0 ]; then
  # Flutter always ships libflutter.so: an empty list means a wrong layout.
  echo "::error title=16 KB page size::no arm64-v8a/x86_64 native libraries in $input"
  status=1
fi
for lib in "${libs[@]}"; do
  aligns=$("$READELF" -lW "$work/x/$lib" 2>/dev/null | awk '$1 == "LOAD" { print $NF }')
  if [ -z "$aligns" ]; then
    echo "::error title=16 KB page size::$lib: no ELF LOAD segments found (not an ELF file?)"
    status=1
    continue
  fi
  worst=""
  for a in $aligns; do
    if [ "$((a))" -lt "$MIN_ALIGN" ]; then worst="$a"; fi
  done
  if [ -n "$worst" ]; then
    echo "::error title=16 KB page size::$lib: ELF LOAD segment alignment $worst < 0x4000 (rebuild or bump the dependency that ships it)"
    status=1
  else
    echo "ok   $lib"
  fi
done

# Zip alignment of uncompressed libraries in an APK.
if [ -n "$apk" ]; then
  zipalign="${ZIPALIGN:-}"
  if [ -z "$zipalign" ]; then
    sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
    # Stable releases only (no -rc); -P needs build-tools 35+.
    bt=$(ls -d "$sdk"/build-tools/*/ 2>/dev/null | grep -E '/[0-9]+(\.[0-9]+)*/$' |
      sort -V | tail -n 1)
    if [ -n "$bt" ]; then
      major=$(basename "$bt" | cut -d. -f1)
      if [ "$major" -lt 35 ]; then
        echo "::error title=16 KB page size::newest build-tools is $(basename "$bt"); zipalign -P needs 35+"
        status=1
      fi
      zipalign="${bt}zipalign"
    fi
  fi
  if [ -z "$zipalign" ] || [ ! -x "$zipalign" ]; then
    echo "::error title=16 KB page size::zipalign not found (set ANDROID_HOME or ZIPALIGN)"
    status=1
  elif ! out=$("$zipalign" -c -P 16 -v 4 "$apk" 2>&1); then
    echo "$out" | grep -E '\.so' | grep -v -E '\(OK' | while read -r line; do
      echo "::error title=16 KB page size::zip alignment: $line"
    done
    echo "$out" | tail -n 3
    echo "::error title=16 KB page size::zipalign -c -P 16 failed for $(basename "$input")"
    status=1
  else
    echo "ok   zip alignment (zipalign -c -P 16 -v 4)"
  fi
fi

if [ "$status" -eq 0 ]; then
  echo "16 KB page size: all ${#libs[@]} libraries aligned in $(basename "$input")."
fi
exit "$status"
