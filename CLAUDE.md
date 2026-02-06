# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StarNote is a professional Flutter drawing/note-taking application (GoodNotes/Notability quality) structured as a Melos monorepo. It consists of two parts:
1. **pub.dev library** (`packages/`) - Drawing engine (drawing_core + drawing_ui)
2. **Application** (`example_app/`) - Full-featured note-taking app

**Current Phase:** Design System Implementation. Phases 0-9 complete. Phase 10 (Drawing/Editor Screen) is next.

## Build & Development Commands

```bash
# Monorepo-wide (from workspace root)
melos analyze          # Lint all packages
melos test             # Test all packages
melos format           # Format all packages
melos clean            # Clean all packages
melos build:runner     # Run build_runner (code generation) in all packages

# Per-package (from example_app/)
flutter run            # Run the app
flutter analyze        # Lint
flutter test           # Run all tests
flutter test test/path/to/specific_test.dart  # Single test file
dart format lib/       # Format
dart run build_runner build --delete-conflicting-outputs  # Code generation
```

**Environment:** Requires `.env` file in `example_app/` with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

## Architecture

### Package Dependency Graph

```
example_app (Application)
    └── drawing_toolkit (Umbrella - stable public API)
            ├── drawing_core (Pure Dart, no Flutter - models, tools, history)
            └── drawing_ui (Flutter widgets, painters - depends on drawing_core)
```

### Clean Architecture (Feature-First)

Each feature under `example_app/lib/features/` follows:

```
feature_name/
├── data/          # Datasources, models, repository implementations
├── domain/        # Entities, abstract repository interfaces, use cases
└── presentation/  # Providers (Riverpod), screens, widgets
```

**Dependency rules:**
- `presentation → domain` and `data → domain` are allowed
- `domain → presentation` and `domain → data` are forbidden
- Cross-feature imports only via domain layer (entities/repository interfaces)
- All layers can import from `core/`

### Core Module (`example_app/lib/core/`)

- `theme/tokens/` - Design tokens: AppColors, AppSpacing, AppRadius, AppTypography, AppIconSizes, AppShadows, AppDurations
- `theme/app_theme.dart` - ThemeData for light and dark modes
- `widgets/` - Reusable component library (buttons, inputs, feedback, layout, navigation)
- `utils/responsive.dart` - Breakpoints and device type detection
- `routing/` - GoRouter configuration
- `di/` - GetIt + Injectable dependency injection setup
- `errors/` - Failure/Exception classes for Either pattern

### Key Technical Patterns

- **State management:** Riverpod (`flutter_riverpod`). Providers suffixed with `Provider`.
- **Error handling:** `Either<Failure, T>` from dartz throughout repositories and use cases.
- **DI:** GetIt + Injectable. Repositories annotated with `@Injectable(as: RepositoryInterface)`.
- **Database:** Drift (SQLite) for local storage.
- **Backend:** Supabase for auth and cloud sync.
- **Responsive:** Phone (<600px) uses BottomNavigationBar; Tablet (>=600px) uses NavigationRail. Modals render as bottom sheets on phone, center dialogs on tablet.

## Critical Rules

**Read before any implementation:** `docs/DESIGN_SYSTEM_MASTER_PLAN.md` and `.cursorrules`.

**Interface contracts** between features are defined in `CONTRACTS.md` — architect approval required to change them.

### Code Constraints

- **Max 300 lines per file.** Split if exceeding.
- **No hardcoded colors** — use `AppColors.*` or `Theme.of(context).colorScheme.*`
- **No hardcoded spacing** — use `AppSpacing.*` (4dp grid: xxs=2, xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48)
- **Minimum 48x48dp touch targets** — non-negotiable
- **No `print()` statements** — use `logger`
- **No business logic in widgets** — delegate to providers
- **Entities must be immutable** — use `final` fields

### Import Conventions

```dart
// Use barrel exports, not direct file paths
import 'package:example_app/core/theme/index.dart';    // ✅
import 'package:example_app/core/widgets/index.dart';   // ✅
import 'package:example_app/features/auth/auth.dart';   // ✅

// Don't use relative imports or direct src paths
import '../../../core/database/app_database.dart';                    // ❌
import 'package:example_app/core/theme/tokens/app_colors.dart';      // ❌
import 'package:example_app/features/auth/data/models/user_model.dart'; // ❌
```

### Drawing Canvas Performance Rules

- No `setState` in pointer handlers — use `ChangeNotifier`/`ValueNotifier`
- No allocation in `paint()`, no `shouldRepaint => true`
- Use `RepaintBoundary` isolation
- Cache Paint/Path objects
- Bounding box pre-filter for hit tests
- Command batching (not one command per pointer move)

## Testing

Every component requires: widget test (renders), interaction test (taps/focus), state test (loading/disabled/error), and theme test (light + dark). Test both phone and tablet sizes.

Mock library: `mocktail`.

## Git Conventions

**Branch naming:** `feature/<name>`, `fix/<description>`, `refactor/<scope>`

**Commit format:** `type(scope): message` — e.g., `feat(widgets): add AppButton with 5 variants`

**Pre-commit:** Run `flutter analyze` and `flutter test` before committing.
