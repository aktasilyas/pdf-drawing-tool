# Elyanotes

Flutter note-taking app (GoodNotes/Flexcil class) for tablets first, phones second.
Melos monorepo: `packages/drawing_core` (pure Dart models, tools, history) →
`packages/drawing_ui` (canvas, painters, toolbar) → `example_app` (the product).

Talk to the user in Turkish. Code, comments, commits and docs in English.

## Current goal
Ship v1.0 to the stores. Status and priorities live in GitHub Issues and the
milestones in `docs/ROADMAP.md` — not in markdown status files. Do not create
new STATUS/HANDOFF/PHASE documents; old ones are in `docs/archive/` and are
historical only (do not read them unless asked).

v1.0 scope: ink engine, notebooks + covers, PDF import/annotate/export, local storage.
Frozen behind flags until after v1.0: AI chat, cloud sync, premium, audio recording.

## Commands
```bash
./scripts/check.sh pub          # pub get in dependency order (once per clone / pubspec change)
./scripts/check.sh analyze      # dart analyze all packages (what CI runs)
./scripts/check.sh test         # dart test / flutter test per package (what CI runs)
cd example_app && flutter run   # needs example_app/.env (SUPABASE_URL, SUPABASE_ANON_KEY)
flutter test path/to/file_test.dart                 # single test
dart run build_runner build --delete-conflicting-outputs   # example_app codegen
```

## Workflow (every task)
1. Non-trivial work starts from a GitHub issue with acceptance criteria.
2. Plan first for anything touching more than ~3 files (`writing-plans` skill);
   plans go in `docs/plans/`, specs in `docs/specs/`.
3. TDD for logic (`test-driven-development` skill). UI changes need a widget test
   or golden test.
4. Before saying "done": run analyze + the affected tests and show the output
   (`verification-before-completion`). A Stop hook enforces this.
5. One branch + one PR per issue, branch `claude/<issue>-<slug>`.
   Commits: `type(scope): message`. Never push to `main` directly.
6. GitHub access via `gh api` REST only (GraphQL is unavailable in cloud sessions).
7. History is append-only: to update a branch use `git merge origin/main`, never
   rebase/amend/force-push a pushed branch. Agents never merge PRs or push to main.
   A denied action is reported, never retried another way.

## Autopilot
The backlog is the GitHub issue list (milestones M0b…M5). Labels:
`agent-ready` (agents may take it), `needs-architect` (question for the architect),
`needs-decision` / `needs-owner` / `needs-owner-review` (owner only),
`in-progress`, `in-review`, `ready-to-merge` (verified by autopilot),
`architect-approved` (architect approved; a workflow merges it).
Routines: `/autopilot` (builds) and `/architect-desk` (answers questions,
approves PRs, escalates only owner-level matters). Agents never ask the owner
directly. Log: the "Autopilot status" issue. Never pick up an issue without `agent-ready`.

Subagents: `architect` (technical design, plans), `ui-designer` (visual specs
and reviews of rendered goldens), `implementer` (scoped coding),
`reviewer` (final diff before a PR).

## Design
Visual direction and decisions: `docs/design/BRIEF.md` (owner-approved; do not
change without asking). Any UI work follows the `design-loop` skill: spec from
`ui-designer` → golden test → render → review the PNGs → fix. Quality bar:
`flutter-ui-craft` skill. Tokens and theming: `design-tokens` skill.

## Architecture rules
- Feature-first Clean Architecture in `example_app/lib/features/<f>/{data,domain,presentation}`.
  `presentation → domain ← data`. Cross-feature access only via domain interfaces.
- Riverpod for state, `Either<Failure, T>` (dartz) in repositories/use cases,
  GetIt + Injectable for DI, Drift for local DB, GoRouter for navigation.
- `drawing_core` never imports Flutter. `drawing_ui` never imports `example_app`.
- Import through barrel files (`.../index.dart`, `feature.dart`); no relative `../../` imports.

## Code constraints
- Max ~300 lines per file. Known offenders to split when touched:
  `drawing_canvas_gesture_handlers.dart` (2.2k), `drawing_canvas.dart` (1.5k).
- No hardcoded colors or spacing in widgets: colors from theme tokens, spacing
  from `AppSpacing` (4dp grid). Do not add new `isDark ? … : …` ternaries —
  the theme is being migrated to a `ThemeExtension` (see `design-tokens` skill).
- Touch targets ≥ 48dp. No `print()` (use `logger`). No business logic in widgets.
- Entities immutable. Tests use `mocktail`.

## Ink / canvas performance (see `ink-engine` skill before touching canvas code)
- No `setState` in pointer handlers; no allocation in `paint()`;
  never `shouldRepaint => true`.
- Committed strokes are cached (raster/picture); only the active stroke is drawn as vectors.
- Hit tests use bounding-box pre-filter. History commands are batched per stroke.

## Environment notes
- The owner develops on Windows (WSL paths like `/mnt/c/...`). Cloud sessions run
  Ubuntu with Flutter installed by `scripts/cloud-setup.sh`.
- Flutter SDK is pinned in `.flutter-version` (read by CI and cloud-setup). Bump it
  there only, together with regenerated `pubspec.lock` files.
- No `ios/` folder yet; Android is the first release target.
- `flutter_pen_toolbar` is a git dependency (github.com/aktasilyas/flutter_pen_toolbar).
