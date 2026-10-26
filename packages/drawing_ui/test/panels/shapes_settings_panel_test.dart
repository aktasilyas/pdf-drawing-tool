import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/panel_harness.dart';

void main() {
  const panel = ShapesSettingsPanel();

  testWidgets('no overflow at 380 wide with textScaler 1.3', (tester) async {
    await pumpPanel(tester, panel, textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tappables are at least 48x48', (tester) async {
    await pumpPanel(tester, panel);
    expectMinTapTarget(tester, find.byType(ChromeIconButton));
    expectMinTapTarget(tester, find.byType(CompactToggle));
    for (final shape in ShapeType.values) {
      expectMinTapTarget(tester, find.byKey(ValueKey('shape-${shape.name}')));
    }
  });

  testWidgets('close clears the active panel', (tester) async {
    final c = await pumpPanel(
      tester,
      panel,
      setup: (c) =>
          c.read(activePanelProvider.notifier).state = ToolType.shapes,
    );
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pump();
    expect(c.read(activePanelProvider), isNull);
  });

  testWidgets('slider keeps the default 8 divisions', (tester) async {
    await pumpPanel(tester, panel);
    final slider = tester.widget<Slider>(find.byType(Slider).first);
    expect(slider.divisions, 8);
  });

  testWidgets('tapping a shape selects it', (tester) async {
    final c = await pumpPanel(tester, panel);
    expect(c.read(shapesSettingsProvider).selectedShape, ShapeType.rectangle);
    await tester.tap(find.byKey(const ValueKey('shape-star')));
    await tester.pump();
    expect(c.read(shapesSettingsProvider).selectedShape, ShapeType.star);
  });

  testWidgets('fill toggle reveals the fill colour strip', (tester) async {
    final c = await pumpPanel(tester, panel);
    expect(find.text('Dolgu Rengi'), findsNothing);
    await tester.tap(find.text('Şekil dolgusu'));
    await tester.pump();
    expect(c.read(shapesSettingsProvider).fillEnabled, isTrue);
    expect(find.text('Dolgu Rengi'), findsOneWidget);
  });
}
