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

Total: 81 tests, all passing

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
