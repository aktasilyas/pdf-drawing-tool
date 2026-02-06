# Senior Architect Memory

## Key Files & Patterns
- Design tokens: `example_app/lib/core/theme/tokens/` (AppColors, AppSpacing, AppRadius, AppTypography, AppIconSize)
- Theme config: `example_app/lib/core/theme/app_theme.dart`
- Core widgets: `example_app/lib/core/widgets/` (inputs, buttons, layout, feedback, navigation)
- Documents feature: `example_app/lib/features/documents/`
- Barrel exports via `index.dart` files

## Critical Dark Theme Pattern
- Always check `isDark` via `Theme.of(context).brightness == Brightness.dark`
- Use `AppColors.xxxDark` vs `AppColors.xxxLight` conditional
- NEVER hardcode `AppColors.textPrimaryLight` in widgets that render in both themes
- AppCard, AppEmptyState, breadcrumb_navigation, selection_mode_header, document_card_helpers, folder_card all have dark theme bugs (hardcoded Light colors)

## Token Discrepancy (app_colors.dart)
- `outlineDark` in tokens file = `0xFF1C1C1C` (almost same as background `0xFF121212`) -- too subtle
- Spec says `outlineDark` should be `#2C2C2C` but code has `#1C1C1C`
- `outlineVariantDark` = `0xFF252525` vs spec value not explicitly mentioned
- This makes dark mode borders nearly invisible

## documents_screen.dart
- 1831 lines -- extreme violation of 300 line max rule
- Contains inline dialogs, menu builders, formatting helpers all in one file

## Keyboard Overflow
- Documents screen wraps content in Column with Expanded for grid, which is correct
- MoveToFolderDialog uses SingleChildScrollView for keyboard safety
- The header search field in DocumentsHeader is inside a Column (not scrollable), could cause overflow on very small screens when keyboard opens
- Rename dialogs use standard AlertDialog with TextField -- Flutter AlertDialog auto-scrolls, so keyboard is handled

## File line counts to watch
- documents_screen.dart: ~1831 lines (critical violation)
- new_document_dialog.dart: ~451 lines (violation)
