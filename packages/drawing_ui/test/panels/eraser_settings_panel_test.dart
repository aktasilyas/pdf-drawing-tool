import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/panel_harness.dart';

void main() {
  const panel = EraserSettingsPanel();

  testWidgets('no overflow at 380 wide with textScaler 1.3', (tester) async {
    await pumpPanel(tester, panel, textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tappables are at least 48x48', (tester) async {
    await pumpPanel(tester, panel);
    expectMinTapTarget(tester, find.byType(ChromeIconButton));
    expectMinTapTarget(tester, find.byType(CompactToggle));
    expectMinTapTarget(
      tester,
      find.byKey(const ValueKey('eraser-clear-page')),
    );
  });

  testWidgets('close clears the active panel', (tester) async {
    final c = await pumpPanel(
      tester,
      panel,
      setup: (c) =>
          c.read(activePanelProvider.notifier).state = ToolType.pixelEraser,
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

  testWidgets('type selector switches to the stroke eraser', (tester) async {
    final c = await pumpPanel(tester, panel);
    await tester.tap(find.byKey(const ValueKey('eraser-type-strokeEraser')));
    await tester.pump();
    expect(c.read(currentToolProvider), ToolType.strokeEraser);
    expect(c.read(eraserSettingsProvider).mode, EraserMode.stroke);
  });

  testWidgets('clear page asks for confirmation and closes the panel',
      (tester) async {
    final c = await pumpPanel(
      tester,
      panel,
      setup: (c) =>
          c.read(activePanelProvider.notifier).state = ToolType.pixelEraser,
    );
    await tester.tap(find.byKey(const ValueKey('eraser-clear-page')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Sayfayı Temizle?'), findsOneWidget);
    expect(c.read(activePanelProvider), isNull);
  });
}
