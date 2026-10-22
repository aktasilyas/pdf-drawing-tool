#!/bin/bash
# SessionStart hook: resolve workspace dependencies in cloud sessions only.
# Locally this exits immediately; run `./scripts/check.sh pub` yourself once per clone.
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

# example_app declares .env as an asset; builds and tests fail without it.
if [ ! -f example_app/.env ]; then
  printf 'SUPABASE_URL=https://example.supabase.co\nSUPABASE_ANON_KEY=placeholder\n' > example_app/.env
fi

command -v flutter >/dev/null 2>&1 || exit 0

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
