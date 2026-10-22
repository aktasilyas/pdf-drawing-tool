#!/bin/bash
# Workspace checks without melos: ./scripts/check.sh [pub|analyze|test|all]
# Order matters: drawing_core → drawing_ui → example_app (path dependencies).
# In GitHub Actions, failures are also emitted as annotations so they are
# readable from the PR page and the API.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
PACKAGES=(packages/drawing_core packages/drawing_ui example_app)
STEP="${1:-all}"
status=0

is_flutter() { grep -qE 'sdk:[[:space:]]*flutter' "$1/pubspec.yaml"; }

annotate() { # $1=title $2=logfile
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    local msg
    msg=$(tail -n 60 "$2" | sed -e 's/%/%25/g' | awk '{printf "%s%%0A", $0}')
    echo "::error title=$1::$msg"
  fi
}

run() { # $1=title $2=dir rest=command
  local title=$1 dir=$2; shift 2
  local log
  log=$(mktemp)
  echo "── $title"
  if (cd "$dir" && "$@") >"$log" 2>&1; then
    tail -n 3 "$log"
  else
    cat "$log"
    annotate "$title" "$log"
    status=1
  fi
  rm -f "$log"
}

for pkg in "${PACKAGES[@]}"; do
  if [[ $STEP == pub || $STEP == all ]]; then
    if is_flutter "$pkg"; then run "pub get $pkg" "$pkg" flutter pub get
    else run "pub get $pkg" "$pkg" dart pub get; fi
  fi
  if [[ $STEP == analyze || $STEP == all ]]; then
    run "analyze $pkg" "$pkg" dart analyze --no-fatal-warnings .
  fi
  if [[ $STEP == test || $STEP == all ]] && [ -d "$pkg/test" ]; then
    if is_flutter "$pkg"; then run "test $pkg" "$pkg" flutter test --timeout=90s
    else run "test $pkg" "$pkg" dart test --timeout=90s; fi
  fi
done

exit $status
