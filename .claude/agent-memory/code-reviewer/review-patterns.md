# Recurring Review Patterns

## Dark Theme Implementation
- Correct pattern: `final isDark = Theme.of(context).brightness == Brightness.dark;`
- Always at start of `build()` method
- Ternary ordering convention: `isDark ? darkVariant : lightVariant`
- For private sub-widgets, passing `isDark` as param is acceptable (e.g., `_SelectionCheckbox`)
- For public reusable widgets, prefer `Theme.of(context)` internally

## Common Violations
1. **Hardcoded colors in utility classes**: Paper colors, dynamic mappings tend to have raw Color() values
2. **Touch targets on small visual elements**: Checkboxes (24dp), back buttons (32dp) that are independently tappable
3. **Hardcoded numeric sizes**: Devs write `24` instead of `AppIconSize.lg`, `16` instead of `AppIconSize.sm`
4. **Font size overrides**: `fontSize: 9` for badges -- no token exists for sub-caption sizes
5. **Icon size arithmetic**: `AppIconSize.xl + AppIconSize.lg` instead of defining a semantic token

## Acceptable Exceptions
- `Colors.transparent` for Material widget backgrounds
- `Color(entity.colorValue)` for user-data-driven colors (e.g., folder color from DB)
- `width: 2` for border widths (no border width tokens defined)
- Sub-barrel imports within `core/widgets/` to avoid circular dependencies

## Shadows in Dark Theme
- `AppShadows.sm` uses black opacity shadows -- nearly invisible on dark backgrounds
- Suggestion: suppress shadows or use border-based elevation in dark mode
- Not a blocker, but worth noting in future reviews

## Barrel Export Issues (Issue 12-17 era)
- `documents.dart` barrel only exports original files, not refactored split files
- No `index.dart` exists for `presentation/widgets/` or `presentation/screens/`
- New files use direct path imports like `import '...widgets/document_card.dart'` instead of barrel
- Pre-existing files (sidebar.dart, empty_state.dart, document_context_menu.dart, document_grid.dart) were never tokenized for spacing

## Colors.red Pattern
- `Colors.red` / `Colors.red.shade400` used extensively for destructive actions (delete buttons, error snackbars)
- Should define `AppColors.destructive` / `AppColors.error` tokens and migrate
- Found in: documents_menus.dart, folder_menus.dart, new_document_importers.dart
