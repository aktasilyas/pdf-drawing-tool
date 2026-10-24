#!/bin/bash
# SessionStart hook: resolve workspace dependencies in cloud sessions only.
# Locally this exits immediately; run `./scripts/check.sh pub` yourself once per clone.
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Install Flutter when the environment has no setup script (e.g. routines on
# the Default environment). A setup script that already installed it makes this a no-op.
if ! command -v flutter >/dev/null 2>&1; then
  bash "$CLAUDE_PROJECT_DIR/scripts/cloud-setup.sh" >/tmp/flutter-setup.log 2>&1 \
    || { echo "Flutter install failed; see /tmp/flutter-setup.log" >&2; exit 0; }
fi

# Skip when pubspecs are unchanged since the last successful pub get.
stamp=.dart_tool/.bootstrap.sha256
mkdir -p .dart_tool
if sha256sum --check --status "$stamp" 2>/dev/null; then
  exit 0
fi
rm -f "$stamp"
if ./scripts/check.sh pub >/tmp/pub-get.log 2>&1; then
  sha256sum melos.yaml packages/*/pubspec.yaml example_app/pubspec.yaml > "$stamp"
else
  echo "pub get failed; see /tmp/pub-get.log" >&2
fi
exit 0
