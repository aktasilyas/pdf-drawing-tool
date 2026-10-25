import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _labels = [
  'Dolma Kalem',
  'Tükenmez Kalem',
  'Fırça Kalem',
  'Fosforlu Kalem',
  'Kurşun Kalem',
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  double width = 376,
  double textScale = 1,
  ValueChanged<ToolType>? onSelected,
  ToolType tool = ToolType.ballpointPen,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  container.read(currentToolProvider.notifier).selectTool(tool);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 400),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: PenTypePicker(onPenSelected: onSelected),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('shows five previews and labels in order', (tester) async {
    await _pump(tester);
    expect(find.byType(PenPresetPreview), findsNWidgets(5));
    final xs = [for (final l in _labels) tester.getCenter(find.text(l)).dx];
    expect([...xs]..sort(), xs);
    expect(find.text('Kesik Çizgi'), findsNothing);
    expect(find.text('Cetvelli Kalem'), findsNothing);
  });

  testWidgets('tap selects tool and calls onPenSelected', (tester) async {
    ToolType? got;
    final c = await _pump(tester, onSelected: (t) => got = t);
    await tester.tap(find.text('Fosforlu Kalem'));
    await tester.pump();
    expect(c.read(currentToolProvider), ToolType.highlighter);
    expect(got, ToolType.highlighter);
  });

  testWidgets('only current tool tile is selected; legacy selects none',
      (tester) async {
    await _pump(tester);
    int selected() => tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where(
            (s) => s.properties.button == true && s.properties.selected == true)
        .length;
    expect(selected(), 1);
  });

  testWidgets('legacy tool selects no tile', (tester) async {
    await _pump(tester, tool: ToolType.dashedPen);
    final n = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where(
            (s) => s.properties.button == true && s.properties.selected == true)
        .length;
    expect(n, 0);
  });

  testWidgets('tiles are at least 48x48', (tester) async {
    await _pump(tester);
    for (final l in _labels) {
      final size = tester.getSize(
        find.ancestor(of: find.text(l), matching: find.byType(InkWell)).first,
      );
      expect(size.width, greaterThanOrEqualTo(48), reason: l);
      expect(size.height, greaterThanOrEqualTo(48), reason: l);
    }
  });

  testWidgets('preview follows the tool style provider', (tester) async {
    final c = await _pump(tester);
    c
        .read(penSettingsProvider(ToolType.brushPen).notifier)
        .setColor(const Color(0xFFFF0000));
    await tester.pump();
    final previews = tester
        .widgetList<PenPresetPreview>(find.byType(PenPresetPreview))
        .toList();
    expect(
      previews[2].style,
      c.read(strokeStyleForToolProvider(ToolType.brushPen)),
    );
    expect(previews[2].style.color, 0xFFFF0000);
  });

  for (final (w, scale) in [(390.0, 1.0), (376.0, 1.0), (390.0, 1.3)]) {
    testWidgets('no overflow at width $w scale $scale', (tester) async {
      await _pump(tester, width: w, textScale: scale);
      expect(tester.takeException(), isNull);
    });
  }
}
