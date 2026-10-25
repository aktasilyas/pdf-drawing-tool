#!/bin/bash
# Workspace checks without melos: ./scripts/check.sh [pub|analyze|test|all] [package-dir]
# Order matters: drawing_core → drawing_ui → example_app (path dependencies).
# In GitHub Actions, failures are also emitted as annotations so they are
# readable from the PR page and the API.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
PACKAGES=(packages/drawing_core packages/drawing_ui example_app)
STEP="${1:-all}"
ONLY="${2:-}"
status=0

is_flutter() { grep -qE 'sdk:[[:space:]]*flutter' "$1/pubspec.yaml"; }

annotate() { # $1=title $2=logfile
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    local msg
    # Failed test names first (they are usually far above the tail), then the tail.
    msg=$( { grep -E '❌|\[E\]|Some tests failed|EXCEPTION CAUGHT' "$2" | head -n 20; echo '...'; tail -n 40 "$2"; } \
      | sed -e 's/%/%25/g' | awk '{printf "%s%%0A", $0}')
    echo "::error title=$1::$msg"
  fi
}

benchmarks() { # $1=title $2=logfile: surface ink benchmark lines from a passing run
  local lines
  # The test reporter may prefix a line with progress output; keep from the label on.
  lines=$(grep -oE '(committed (build|raster)|active stroke|active-length|pen-up)[ :].*' "$2" \
    | grep -E '[0-9] ms|tiles: [0-9]' || true)
  [ -z "$lines" ] && return 0
  echo "$lines"
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    local msg
    msg=$(echo "$lines" | sed -e 's/%/%25/g' | awk '{printf "%s%%0A", $0}')
    echo "::notice title=ink benchmark ($1)::$msg"
  fi
}

run() { # $1=title $2=dir rest=command
  local title=$1 dir=$2; shift 2
  local log
  log=$(mktemp)
  echo "── $title"
  if (cd "$dir" && "$@") >"$log" 2>&1; then
    benchmarks "$title" "$log"
    tail -n 3 "$log"
  else
    cat "$log"
    annotate "$title" "$log"
    status=1
  fi
  rm -f "$log"
}

for pkg in "${PACKAGES[@]}"; do
  # pub get always covers every package (path deps); analyze/test can be scoped.
  if [[ $STEP == pub || $STEP == all ]]; then
    if is_flutter "$pkg"; then run "pub get $pkg" "$pkg" flutter pub get
    else run "pub get $pkg" "$pkg" dart pub get; fi
  fi
  if [ -n "$ONLY" ] && [ "$pkg" != "$ONLY" ]; then continue; fi
  if [[ $STEP == analyze || $STEP == all ]]; then
    run "analyze $pkg" "$pkg" dart analyze .
  fi
  if [[ $STEP == test || $STEP == all ]] && [ -d "$pkg/test" ]; then
    if ! is_flutter "$pkg"; then run "test $pkg" "$pkg" dart test --timeout=90s
    elif [ -d "$pkg/test/benchmark" ]; then
      # Wall-clock benchmarks run alone so parallel test processes do not
      # compete with them for the CPU (see dart_test.yaml).
      run "test $pkg" "$pkg" flutter test --timeout=90s --concurrency=4 --exclude-tags benchmark
      run "benchmark $pkg" "$pkg" flutter test --timeout=90s --concurrency=1 --tags benchmark
    else run "test $pkg" "$pkg" flutter test --timeout=90s --concurrency=4; fi
  fi
done

exit $status
