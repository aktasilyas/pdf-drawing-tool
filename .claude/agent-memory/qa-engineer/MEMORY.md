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

### Test Organization
Group tests by:
1. Theme (Light/Dark)
2. Variant (if applicable)
3. Interaction
4. Layout

Use snake_case for test names: `should_expectedBehavior_when_condition`

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
- AppCard: 20 tests (all 3 variants, light/dark themes, selected states)
- AppEmptyState: 12 tests (light/dark themes, all parameters, minimal params)
- FolderCard: 17 tests (light/dark themes, selection checkbox, interactions)

Total: 49 tests, all passing
