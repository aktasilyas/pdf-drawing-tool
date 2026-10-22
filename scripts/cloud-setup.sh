#!/bin/bash
# Setup script for Claude Code cloud environments (Ubuntu 24.04, runs as root).
# Paste this into: claude.ai/code → environment settings → Setup script.
# Network access level "Trusted" already allows github.com, storage.googleapis.com and pub.dev.
set -euo pipefail

FLUTTER_DIR=/opt/flutter
FLUTTER_BRANCH="${FLUTTER_BRANCH:-stable}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_BRANCH" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
git config --global --add safe.directory "$FLUTTER_DIR"

ln -sf "$FLUTTER_DIR/bin/flutter" /usr/local/bin/flutter
ln -sf "$FLUTTER_DIR/bin/dart" /usr/local/bin/dart

export PATH="$FLUTTER_DIR/bin:$HOME/.pub-cache/bin:$PATH"
flutter config --no-analytics >/dev/null
flutter --version            # downloads the Dart SDK on first run
# Host artifacts for analyze/test only; no Android/iOS SDKs in the cloud VM.
flutter precache --universal --no-android --no-ios || true

