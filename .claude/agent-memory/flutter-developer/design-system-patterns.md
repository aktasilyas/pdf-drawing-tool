# Design System Migration Patterns

## Color Mapping Rules
- `Colors.white` (bg surface) -> `colorScheme.surface`
- `Colors.white` (icon/text on dark/colored bg) -> KEEP as is
- `Colors.black` (shadow) -> `colorScheme.shadow`
- `Colors.black` (overlay/scrim) -> `colorScheme.scrim.withValues(alpha: X)`
- `Colors.black` (text) -> `colorScheme.onSurface`
- `Colors.grey.shade100-200` (bg) -> `colorScheme.surfaceContainerHighest`
- `Colors.grey.shade300-400` (border) -> `colorScheme.outlineVariant`
- `Colors.transparent` for Material wrappers -> KEEP (standard Flutter pattern)
- Semantic colors (Colors.red, Colors.green) -> KEEP

## Shadow Mapping (DrawingShadows)
- Panel/popover/selection toolbar -> `DrawingShadows.panel(brightness)`
- Floating widgets/popups -> `DrawingShadows.floating(brightness)`
- Toolbars/bars -> `DrawingShadows.toolbar(brightness)`
- Page thumbnails -> `DrawingShadows.page(brightness)`
- Selected items -> `DrawingShadows.selection(brightness, [tintColor])`

## Getting Brightness
- `Theme.of(context).brightness`
- Or from existing `theme` variable: `theme.brightness`

## Common Pattern for Accessing ColorScheme
```dart
final colorScheme = Theme.of(context).colorScheme;
final brightness = Theme.of(context).brightness;
```

## Divider Color in Menus
Use `Builder` wrapper when `_divider()` is called from a method without `context`:
```dart
Widget _divider() => Builder(
  builder: (context) => Divider(
    height: 1,
    thickness: 0.5,
    color: Theme.of(context).colorScheme.outlineVariant,
  ),
);
```
