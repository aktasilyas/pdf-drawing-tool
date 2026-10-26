import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/panel_harness.dart';

void main() {
  const panel = TextSettingsPanel();

  testWidgets('no overflow at 380 wide with textScaler 1.3', (tester) async {
    await pumpPanel(tester, panel, textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tappables are at least 48x48', (tester) async {
    await pumpPanel(tester, panel);
    expectMinTapTarget(tester, find.byType(ChromeIconButton));
    expectMinTapTarget(tester, find.byKey(const ValueKey('text-style-bold')));
    expectMinTapTarget(tester, find.byKey(const ValueKey('text-style-italic')));
    expectMinTapTarget(
      tester,
      find.byKey(const ValueKey('text-style-underline')),
    );
  });

  testWidgets('close clears the active panel', (tester) async {
    final c = await pumpPanel(
      tester,
      panel,
      setup: (c) => c.read(activePanelProvider.notifier).state = ToolType.text,
    );
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pump();
    expect(c.read(activePanelProvider), isNull);
  });

  testWidgets('slider keeps 16 divisions', (tester) async {
    await pumpPanel(tester, panel);
    final slider = tester.widget<Slider>(find.byType(Slider).first);
    expect(slider.divisions, 16);
  });

  testWidgets('bold toggle updates the setting', (tester) async {
    final c = await pumpPanel(tester, panel);
    expect(c.read(textSettingsProvider).isBold, isFalse);
    await tester.tap(find.byKey(const ValueKey('text-style-bold')));
    await tester.pump();
    expect(c.read(textSettingsProvider).isBold, isTrue);
  });
}
