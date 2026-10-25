#!/bin/bash
# Line coverage summary for one package: ./scripts/coverage.sh <package-dir>
# Reads <pkg>/coverage/lcov.info (written by COVERAGE=1 ./scripts/check.sh test <pkg>),
# counts only hand-written files under lib/ (generated *.g/*.freezed/... excluded;
# Flutter only reports files the tests load), prints the percentage, appends a row to the
# GitHub job summary, and fails when the package has a floor in
# scripts/coverage-thresholds.txt and coverage is below it.
# Raise the floor when coverage goes up; never lower it to make CI pass.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
PKG="${1:?usage: coverage.sh <package-dir>}"
LCOV="$PKG/coverage/lcov.info"
THRESHOLDS=scripts/coverage-thresholds.txt

if [ ! -s "$LCOV" ]; then
  echo "::error title=coverage $PKG::$LCOV missing or empty"
  exit 1
fi

# Sum LF (lines found) / LH (lines hit) of lib/ records only.
read -r found hit files < <(awk '
  /^SF:/ { inlib = ($0 ~ /(^SF:|\/)lib\//) && ($0 !~ /\.(g|freezed|config|gr|mocks)\.dart$/); if (inlib) n++ }
  inlib && /^LF:/ { split($0, a, ":"); f += a[2] }
  inlib && /^LH:/ { split($0, a, ":"); h += a[2] }
  END { printf "%d %d %d\n", f, h, n }' "$LCOV")

if [ "$found" -eq 0 ]; then
  echo "::error title=coverage $PKG::no lib/ lines in $LCOV"
  exit 1
fi

pct=$(awk -v h="$hit" -v f="$found" 'BEGIN { printf "%.1f", 100 * h / f }')
min=$(awk -v p="$PKG" '$1 == p { print $2 }' "$THRESHOLDS" 2>/dev/null)

status=0
verdict="—"
if [ -n "$min" ]; then
  # Exact compare on the raw counts (pct is rounded for display only).
  if awk -v h="$hit" -v f="$found" -v m="$min" 'BEGIN { exit !(100 * h < m * f) }'; then
    verdict="❌ below floor $min%"
    echo "::error title=coverage $PKG::line coverage $pct% is below the floor $min% ($THRESHOLDS)"
    status=1
  else
    verdict="✅ floor $min%"
  fi
fi

echo "coverage $PKG: $pct% ($hit/$found lines, $files files) $verdict"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "| Package | Line coverage | Lines | Files | Floor |"
    echo "|---|---|---|---|---|"
    echo "| \`$PKG\` | **$pct%** | $hit / $found | $files | $verdict |"
  } >>"$GITHUB_STEP_SUMMARY"
fi
if [ -n "${GITHUB_ACTIONS:-}" ]; then
  echo "::notice title=coverage $PKG::$pct% ($hit/$found lines) $verdict"
fi
exit $status
