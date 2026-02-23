# QA Engineer Memory - StarNote Flutter Testing

## Widget Testing Patterns

### Theme Testing Setup
Always test widgets in both light and dark themes:
```dart
Widget buildTestWidget({required Widget child, bool isDark = false}) {
  return MaterialApp(
    theme: isDark ? AppTheme.dark : AppTheme.light,
    home: Scaffold(body: child),
  );
}
```

### Color Testing Pattern
To verify colors in widgets, use `tester.widget<T>()` to access widget properties:
```dart
// Container decoration colors
final container = tester.widget<Container>(find.byType(Container));
final decoration = container.decoration as BoxDecoration;
expect(decoration.color, equals(AppColors.surfaceLight));

// Text style colors
final text = tester.widget<Text>(find.text('some text'));
expect(text.style?.color, equals(AppColors.textPrimaryLight));

// Icon colors
final icon = tester.widget<Icon>(find.byIcon(Icons.some_icon));
expect(icon.color, equals(AppColors.textSecondaryLight));
```

### Riverpod Widgets
For ConsumerWidgets, wrap test widget in ProviderScope:
```dart
ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: MyWidget()),
  ),
)
```

### Testing StateNotifierProviders with ProviderContainer
For StateNotifierProvider (not StateProvider), use ProviderContainer with overrides:
```dart
final container = ProviderContainer(
  overrides: [
    sharedPreferencesProvider.overrideWithValue(null),
    platformBrightnessProvider.overrideWith((ref) => Brightness.dark),
  ],
);
addTearDown(container.dispose);

// Change state via notifier
container.read(provider.notifier).setMode(value);

// Read state
final state = container.read(provider);
```

Cannot use `.overrideWith((ref) => value)` on StateNotifierProvider - must override with notifier or use container.read(provider.notifier) to change state.

### Test Organization
Group tests by:
1. Theme (Light/Dark)
2. Variant (if applicable)
3. Interaction
4. Layout

Use snake_case for test names: `should_expectedBehavior_when_condition`

### Testing Responsive/Adaptive Widgets
For widgets using LayoutBuilder with breakpoints:
```dart
// Set window size to test specific breakpoint
tester.view.physicalSize = const Size(840, 600);
tester.view.devicePixelRatio = 1.0;
addTearDown(tester.view.resetPhysicalSize);

// Then test the widget normally
await tester.pumpWidget(...);
```

When testing icons that appear multiple times (e.g., expand_more in multiple places):
```dart
// Use byWidgetPredicate to filter by size or other properties
final chevronIcon = find.byWidgetPredicate(
  (widget) => widget is Icon &&
              widget.icon == Icons.expand_more &&
              widget.size == 20,
);
```

## Flutter Test Commands

Run specific test file:
```bash
cmd.exe /c "cd /d C:\\Users\\aktas\\source\\repos\\starnote_drawing_workspace\\example_app && flutter test test/path/to/test.dart"
```

Run multiple test files:
```bash
cmd.exe /c "cd /d C:\\Users\\aktas\\source\\repos\\starnote_drawing_workspace\\example_app && flutter test file1.dart file2.dart file3.dart"
```

## Design System Color Testing

### AppCard
- Elevated: surfaceLight/Dark, shadow when not selected, primary border when selected
- Filled: surfaceVariantLight/Dark, no border unless selected
- Outlined: surfaceLight/Dark, outlineLight/Dark border (1px), primary when selected (2px)

### AppEmptyState
- Icon: textSecondaryLight/Dark
- Title: textPrimaryLight/Dark
- Description: textSecondaryLight/Dark

### FolderCard
- Folder name: textPrimaryLight/Dark
- Document count: textSecondaryLight/Dark
- Selection checkbox unselected: surfaceLight/Dark background, outlineLight/Dark border
- Selection checkbox selected: primary background and border

## Test Coverage Achieved

### Core Widgets
- AppCard: 20 tests (all 3 variants, light/dark themes, selected states)
- AppEmptyState: 12 tests (light/dark themes, all parameters, minimal params)
- FolderCard: 17 tests (light/dark themes, selection checkbox, interactions)

### Documents Feature (Refactor - Feb 2025)
- documents_error_views_test.dart: 4 tests
- documents_empty_states_test.dart: 6 tests
- document_list_tile_test.dart: 4 tests
- documents_header_test.dart: 5 tests
- documents_content_view_test.dart: 4 tests
- documents_combined_grid_test.dart: 4 tests
- documents_list_view_test.dart: 5 tests

### Drawing UI - Responsive Toolbar (Phase M1 - Feb 2025)
- responsive_toolbar_test.dart: 21 tests
  - ToolbarLayoutMode enum: 2 tests
  - AdaptiveToolbar breakpoints: 4 tests
  - MediumToolbar: 6 tests
  - CompactBottomBar: 5 tests
  - ToolbarOverflowMenu: 2 tests
  - TopNavigationBar compact mode: 3 tests

### Drawing UI - Canvas Dark Mode (Phase M1 - Feb 2025)
- canvas_dark_mode_test.dart: 10 tests
  - canvasColorSchemeProvider with different modes: 4 tests
  - CanvasColorScheme effective color methods: 3 tests
  - Painter colorScheme support: 3 tests

### Drawing UI - Long Press Paste Menu (Feb 2025)
- paste_menu_provider_test.dart: 22 tests
  - PasteMenuState model: 4 tests
  - pasteMenuProvider defaults/set/clear: 3 tests
  - pasteFromClipboardAt delta logic: 9 tests (pure math, no WidgetRef needed)
  - selectionClipboardProvider: 4 tests (missing clipboard - no crash; strokes; shapes; clear)
  - Strategy: unit-test the math (delta computation) directly without WidgetRef.
    pasteFromClipboardAt requires WidgetRef so test its logic by verifying the
    arithmetic separately, and test side-effects (pasteMenuProvider cleared) in
    widget tests.
- paste_context_menu_test.dart: 23 tests
  - Rendering (light/dark theme, icon, text, Positioned, Row): 10 tests
  - Positioning (clamp left/right, above/below, center): 6 tests
  - Interactions (tap clears provider, GestureDetector, Listener.opaque): 5 tests
  - State acceptance: 2 tests

Total: 157 tests, all passing

### Patterns learned during paste menu tests
- **Fixed-width pill overflow in tests**: The "Ahem" test font has wider metrics than real
  device fonts. When a widget has a fixed pixel size (e.g., 120x40 pill), suppress
  RenderFlex overflow with:
  ```dart
  void _ignoreOverflow() {
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('RenderFlex overflowed')) return;
      prev?.call(d);
    };
    addTearDown(() => FlutterError.onError = prev);
  }
  ```
  Call `_ignoreOverflow()` at the top of each affected `testWidgets` body.

- **Multiple Listeners in widget tree**: `tester.widget<Listener>(find.descendant(...))`
  fails with "Too many elements". Use `.widgetList<Listener>()` then `.where()`:
  ```dart
  final opaqueListeners = tester.widgetList<Listener>(...).where(
    (l) => l.behavior == HitTestBehavior.opaque).toList();
  expect(opaqueListeners, isNotEmpty);
  ```

- **ProviderContainer capture in testWidgets**: To read provider state after tap,
  capture the container via `ProviderScope.containerOf(context)` inside a Builder.

- **textScaler in MaterialApp.builder**: To prevent font-scale from blowing up
  fixed-dimension widgets in tests, add `textScaler: TextScaler.noScaling` in the
  `MaterialApp.builder` MediaQuery override.

## Entity Structure Reference (for tests)

### DocumentInfo
- Use `title` not `name`
- Required: id, title, createdAt, updatedAt, templateId
- Use `updatedAt` not `modifiedAt`
- No `coverColor` field

### Folder
- Use `colorValue` not `color`
- Required: id, name, createdAt
- Optional: parentId, documentCount, sortOrder

### SortOption enum
- Values: `date`, `name`, `size`
- NOT: `modifiedDate`, `createdDate`
