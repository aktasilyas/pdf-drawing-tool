import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: PenSettingsPanel(toolType: ToolType.ballpointPen),
            ),
          ),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('type row is the v2 picker (5 presets, no legacy pens)',
      (tester) async {
    await _pump(tester);
    expect(find.byType(PenTypePicker), findsOneWidget);
    expect(find.byType(PenPresetPreview), findsNWidgets(5));
    expect(find.text('Dolma Kalem'), findsOneWidget);
    expect(find.text('Kesik Çizgi'), findsNothing);
    expect(find.text('Cetvelli Kalem'), findsNothing);
  });

  testWidgets('choosing a pen switches the current tool', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.text('Fırça Kalem'));
    await tester.pump();
    expect(c.read(currentToolProvider), ToolType.brushPen);
  });

  testWidgets('choosing the highlighter opens its panel', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.text('Fosforlu Kalem'));
    await tester.pump();
    expect(c.read(currentToolProvider), ToolType.highlighter);
    expect(c.read(activePanelProvider), ToolType.highlighter);
  });
}
