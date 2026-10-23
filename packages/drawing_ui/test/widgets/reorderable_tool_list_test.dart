import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/widgets/reorderable_tool_list.dart';
import 'package:drawing_ui/src/providers/toolbar_config_provider.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        home: Scaffold(
          // ReorderableToolList scrolls itself; give it bounded height
          // like the settings panel does (Expanded).
          body: SizedBox(
            height: 900,
            child: ReorderableToolList(),
          ),
        ),
      ),
    );
  }

  testWidgets('displays all tools', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Grouped tools (pens, highlighters, erasers) are collapsed into one row.
    expect(find.text('Kalem'), findsOneWidget);
    expect(find.text('Fosforlu Kalem'), findsOneWidget);
    expect(find.text('Silgi'), findsOneWidget);
    expect(find.text('Şekiller'), findsOneWidget);
  });

  testWidgets('toggle switch works', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Find all switches
    final switches = find.byType(Switch);
    expect(switches, findsWidgets);

    // Toggle first switch
    await tester.tap(switches.first);
    await tester.pumpAndSettle();

    // Verify switch toggled (check if there's a switch with value false now)
    final switchWidgets = tester.widgetList<Switch>(switches);
    expect(switchWidgets.any((s) => s.value == false), isTrue);
  });

  testWidgets('shows drag handles', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(
        find.byWidgetPredicate(
          (w) => w is PhosphorIcon && w.icon == ElyanotesIcons.dragHandle,
        ),
        findsWidgets);
  });

  testWidgets('shows tool icons', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Check that icons are displayed
    expect(find.byType(PhosphorIcon), findsWidgets);
  });

  testWidgets('displays correct number of tools', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Default config has 9 tools; each group collapses into a single row.
    final listItems = find.byType(ReorderableDragStartListener);
    expect(listItems, findsNWidgets(9));
  });
}
