import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('picking the highlighter in the pen sheet shows its panel',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => showToolPanelSheet(
                  context: context,
                  ref: ref,
                  tool: ToolType.ballpointPen,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(PenSettingsPanel), findsOneWidget);

    await tester.tap(find.text('Fosforlu Kalem').first);
    await tester.pumpAndSettle();

    expect(find.byType(HighlighterSettingsPanel), findsOneWidget);
    expect(find.byType(PenSettingsPanel), findsNothing);
  });

  testWidgets('sheet height is capped at 60% and uses the elevated surface',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 700);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => showToolPanelSheet(
                  context: context,
                  ref: ref,
                  tool: ToolType.ballpointPen,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final sheet = find.ancestor(
      of: find.byType(PenSettingsPanel),
      matching: find.byType(ConstrainedBox),
    );
    final height = tester.getSize(sheet.first).height;
    expect(height, lessThanOrEqualTo(700 * 0.6 + 0.01));
    expect(find.byType(DraggableScrollableSheet), findsNothing);
  });
}
