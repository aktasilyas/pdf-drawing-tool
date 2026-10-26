import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/panel_harness.dart';

void main() {
  const panel = HighlighterSettingsPanel();

  testWidgets('no overflow at 380 wide with textScaler 1.3', (tester) async {
    await pumpPanel(tester, panel, textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('neon variant has no overflow at textScaler 1.3', (tester) async {
    await pumpPanel(
      tester,
      panel,
      textScale: 1.3,
      setup: (c) => c
          .read(currentToolProvider.notifier)
          .selectTool(ToolType.neonHighlighter),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Neon Fosforlu'), findsOneWidget);
    expect(find.text('Parlaklık'), findsOneWidget);
  });

  testWidgets('tappables are at least 48x48', (tester) async {
    await pumpPanel(tester, panel);
    expectMinTapTarget(tester, find.byType(ChromeIconButton));
    expectMinTapTarget(tester, find.byType(CompactToggle));
  });

  testWidgets('close clears the active panel', (tester) async {
    final c = await pumpPanel(
      tester,
      panel,
      setup: (c) =>
          c.read(activePanelProvider.notifier).state = ToolType.highlighter,
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

  testWidgets('type selector switches to the neon highlighter', (tester) async {
    final c = await pumpPanel(tester, panel);
    await tester.tap(
      find.byKey(const ValueKey('highlighter-type-neonHighlighter')),
    );
    await tester.pump();
    expect(c.read(currentToolProvider), ToolType.neonHighlighter);
  });

  testWidgets('straight-line toggle updates the setting', (tester) async {
    final c = await pumpPanel(tester, panel);
    expect(c.read(highlighterSettingsProvider).straightLineMode, isFalse);
    await tester.tap(find.text('Düz çizgi'));
    await tester.pump();
    expect(c.read(highlighterSettingsProvider).straightLineMode, isTrue);
  });
}
