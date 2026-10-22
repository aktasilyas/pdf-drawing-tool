# Roadmap to v1.0

Each milestone is a GitHub milestone and every bullet is an issue with
acceptance criteria and dependencies (issues #35–#62). The issue list is the
source of truth for status; this file changes only when scope changes.

## M0 — Development system (done when merged)
CLAUDE.md, subagents, vendored skills, hooks, CI, cloud setup script.

## M1 — Ink engine v2
- Input stabilization (One Euro filter) and point resampling.
- Pressure-aware outline geometry (perfect-freehand style) replacing per-point normals.
- Incremental raster cache for committed strokes, tiled for zoom; undo invalidates tiles.
- Pen presets: fountain, ballpoint, brush, highlighter, pencil (texture).
- Benchmark harness: 1,000-stroke page, frame times on a mid-range Android tablet.
Exit: no frame > 16 ms while drawing on the benchmark page; side-by-side video review.

## M2 — Visual identity
- `AppPalette` ThemeExtension; remove `isDark` ternaries and hardcoded colors.
- Typography pairing and type scale; notebook cover set (original artwork).
- Library screen and editor chrome redesign, approved via golden tests.

## M3 — Scope freeze and cleanup
- Feature flags for AI, sync, premium, audio (off in release builds).
- Split oversized canvas files; dead code removal; coverage report in CI.

## M4 — Android release
- App id, icons, splash, signing config, privacy policy, store listing.
- Release workflow: build appbundle in CI → Play Console internal testing track.
- Crash reporting.

## M5 — iOS / iPadOS release (needs a Mac or macOS CI runner)
- Add `ios/` platform, Apple Pencil latency work (predicted touches via platform channel).
- TestFlight → App Store.
