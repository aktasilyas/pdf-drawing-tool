#!/bin/bash
# Ink benchmark: prints worst / p95 frame times for a 1,000-stroke page.
set -euo pipefail
cd "$(dirname "$0")/../packages/drawing_ui"
out=$(mktemp)
if ! flutter test test/benchmark/ink_benchmark_test.dart >"$out" 2>&1; then
  cat "$out"
  exit 1
fi
grep -E '^(──|committed|active|pen-up)' "$out" || true
