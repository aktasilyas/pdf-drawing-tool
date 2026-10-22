---
name: design-tokens
description: How colors, spacing, typography and theming must be used in Elyanotes widgets, and how to migrate legacy isDark ternaries to the AppPalette ThemeExtension. Use when building or restyling any UI.
---
# Design tokens

## Rule
Widgets never decide light vs dark themselves. They read semantic tokens from
the theme:

```dart
final p = context.palette;          // AppPalette ThemeExtension
Container(color: p.surfaceElevated, child: Text('x', style: context.text.body));
```

Forbidden in new or touched code:
- `Theme.of(context).brightness == Brightness.dark` / `isDark ? … : …` for colors
- `Color(0x…)` outside `core/theme/tokens/`
- Raw numbers for padding/margins/radius (use `AppSpacing`, `AppRadius`)

## Migration (M2)
1. `AppPalette` (ThemeExtension) defines semantic roles: surface, surfaceElevated,
   border, textPrimary, textMuted, accent, danger, canvasBackground, toolbar.
   Light and dark instances are registered in `app_theme.dart`.
2. When you touch a file containing `isDark` ternaries, replace them with the
   matching palette role in the same PR (boy-scout rule). Do not mass-migrate
   unrelated files in feature PRs.
3. Every restyled widget gets a golden test in light and dark.

Progress check: `grep -rE 'isDark \?' example_app/lib packages/drawing_ui/lib | wc -l`
(baseline 213 at M0) must only go down.
