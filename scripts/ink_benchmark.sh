#!/bin/bash
# Ink benchmark: prints worst / p95 frame times for a 1,000-stroke page.
set -euo pipefail
cd "$(dirname "$0")/../packages/drawing_ui"
flutter test test/benchmark/ink_benchmark_test.dart --reporter expanded 2>&1 | grep -E "Ink benchmark|committed|active|All tests|failed|Some tests"
