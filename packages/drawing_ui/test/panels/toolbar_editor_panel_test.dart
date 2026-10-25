import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget body) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: body)),
    );

void main() {
  testWidgets('lays out with a bounded height (list scrolls)', (tester) async {
    const box = SizedBox(width: 400, height: 300, child: ToolbarEditorPanel());
    await tester.pumpWidget(_app(box));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ReorderableToolList), findsOneWidget);
    // The list is bounded by the panel, not taller than the 300 dp box.
    final list = tester.getSize(find.byType(ReorderableToolList));
    expect(list.height, lessThan(300));
  });

  testWidgets('lays out inside a scroll view (unbounded height)',
      (tester) async {
    await tester.pumpWidget(
      _app(const SingleChildScrollView(child: ToolbarEditorPanel())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ReorderableToolList), findsOneWidget);
  });
}
