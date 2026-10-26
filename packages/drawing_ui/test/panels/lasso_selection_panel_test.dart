import 'package:drawing_core/drawing_core.dart' show SelectionType;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/panel_harness.dart';

void main() {
  const panel = LassoSelectionPanel();

  testWidgets('no overflow at 380 wide with textScaler 1.3', (tester) async {
    await pumpPanel(tester, panel, textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tappables are at least 48x48', (tester) async {
    await pumpPanel(tester, panel);
    expectMinTapTarget(tester, find.byType(ChromeIconButton));
    for (final type in SelectableType.values) {
      expectMinTapTarget(
        tester,
        find.byKey(ValueKey('lasso-type-${type.name}')),
      );
    }
  });

  testWidgets('close clears the active panel', (tester) async {
    final c = await pumpPanel(
      tester,
      panel,
      setup: (c) =>
          c.read(activePanelProvider.notifier).state = ToolType.selection,
    );
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pump();
    expect(c.read(activePanelProvider), isNull);
  });

  testWidgets('mode selector switches to rectangle selection', (tester) async {
    final c = await pumpPanel(tester, panel);
    expect(c.read(lassoSettingsProvider).mode, LassoMode.freeform);
    await tester.tap(find.byKey(const ValueKey('lasso-mode-rectangle')));
    await tester.pump();
    expect(c.read(lassoSettingsProvider).mode, LassoMode.rectangle);
    expect(
      c.read(activeSelectionToolTypeProvider),
      SelectionType.rectangle,
    );
    expect(find.text('Dikdörtgen Seçim'), findsOneWidget);
  });

  testWidgets('tapping a type chip toggles that selectable type',
      (tester) async {
    final c = await pumpPanel(tester, panel);
    expect(
      c.read(lassoSettingsProvider).selectableTypes[SelectableType.shape],
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('lasso-type-shape')));
    await tester.pump();
    expect(
      c.read(lassoSettingsProvider).selectableTypes[SelectableType.shape],
      isFalse,
    );
  });
}
