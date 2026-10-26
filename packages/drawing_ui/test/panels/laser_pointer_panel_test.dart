import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/panel_harness.dart';

void main() {
  const panel = LaserPointerPanel();

  testWidgets('no overflow at 380 wide with textScaler 1.3', (tester) async {
    await pumpPanel(tester, panel, textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rainbow variant has no overflow and hides the colour strip',
      (tester) async {
    await pumpPanel(
      tester,
      panel,
      textScale: 1.3,
      setup: (c) => c
          .read(laserSettingsProvider.notifier)
          .setLineStyle(LaserLineStyle.rainbow),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Lazer Gökkuşağı'), findsOneWidget);
    expect(find.byType(ColorPickerStrip), findsNothing);
  });

  testWidgets('tappables are at least 48x48', (tester) async {
    await pumpPanel(tester, panel);
    expectMinTapTarget(tester, find.byType(ChromeIconButton));
  });

  testWidgets('close clears the active panel', (tester) async {
    final c = await pumpPanel(
      tester,
      panel,
      setup: (c) =>
          c.read(activePanelProvider.notifier).state = ToolType.laserPointer,
    );
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pump();
    expect(c.read(activePanelProvider), isNull);
  });

  testWidgets('sliders keep the default 8 divisions', (tester) async {
    await pumpPanel(tester, panel);
    final sliders = tester.widgetList<Slider>(find.byType(Slider));
    expect(sliders, hasLength(2));
    for (final slider in sliders) {
      expect(slider.divisions, 8);
    }
  });

  testWidgets('type selector switches the line style and the dot mode',
      (tester) async {
    final c = await pumpPanel(tester, panel);
    await tester.tap(find.byKey(const ValueKey('laser-type-rainbow')));
    await tester.pump();
    expect(c.read(laserSettingsProvider).mode, LaserMode.line);
    expect(c.read(laserSettingsProvider).lineStyle, LaserLineStyle.rainbow);

    await tester.tap(find.byKey(const ValueKey('laser-type-dot')));
    await tester.pump();
    expect(c.read(laserSettingsProvider).mode, LaserMode.dot);
    expect(find.text('Lazer Nokta'), findsOneWidget);
  });
}
