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

    final context = tester.element(find.byType(PenSettingsPanel));
    final palette = ChromePalette.of(context);
    final sheet = find.byWidgetPredicate((w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == palette.surfaceElevated);
    expect(sheet, findsOneWidget);
    final decoration =
        tester.widget<DecoratedBox>(sheet).decoration as BoxDecoration;
    expect(
      decoration.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(ChromeRadius.xxl)),
    );
    // The pen panel is taller than the cap on a 700dp screen.
    expect(tester.getSize(sheet).height, closeTo(700 * 0.6, 0.01));
    expect(
      find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 32 && w.height == 4),
      findsOneWidget,
    );
    final barrier = tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
    expect(barrier.color, palette.textPrimary.withValues(alpha: 0.12));
    expect(find.byType(DraggableScrollableSheet), findsNothing);
  });
}
