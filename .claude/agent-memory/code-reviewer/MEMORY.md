# Code Reviewer Memory

## Project Context
- StarNote is a Flutter note-taking app targeting GoodNotes/Flexcil quality
- Design system uses explicit Light/Dark token pairs (e.g., `textPrimaryLight`/`textPrimaryDark`)
- Theme detection pattern: `final isDark = Theme.of(context).brightness == Brightness.dark;`
- `.cursorrules` and `docs/DESIGN_SYSTEM_MASTER_PLAN.md` are the source of truth

## Key Rules (from .cursorrules)
- Max 300 lines per file
- Min 48x48dp touch targets (non-negotiable)
- No hardcoded colors (`Color(0xFF...)`, `Colors.xxx`) -- use `AppColors.*`
- No hardcoded spacing -- use `AppSpacing.*`
- Imports must use barrel exports (`index.dart`), except within same package (to avoid circular deps)
- `Colors.transparent` is acceptable for Material widget backgrounds (not a design color)

## Common Issues Found
- See [review-patterns.md](review-patterns.md) for recurring patterns

## Git Setup
- Working dir is `/mnt/c/Users/aktas/source/repos/starnote_drawing_workspace`
- Git commands need `--git-dir` and `--work-tree` flags or `cd` to the workspace
- The shell env does not persist `cd` between bash calls

## Token Reference (quick lookup)
- AppIconSize: xs=12, sm=16, md=20, lg=24, xl=28, xxl=32, huge=48
- AppSpacing: xxs=2, xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48, huge=64
- AppRadius: xs=4, sm=8, md=10, lg=12, xl=16, xxl=20, card=12, modal=16
- AppSpacing.minTouchTarget = 48
