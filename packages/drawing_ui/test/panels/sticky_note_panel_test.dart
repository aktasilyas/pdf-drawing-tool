import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/panel_harness.dart';

void main() {
  const panel = StickyNotePanel();

  testWidgets('no overflow at 380 wide with textScaler 1.3', (tester) async {
    await pumpPanel(tester, panel, textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('Yapışkan Not'), findsOneWidget);
    expect(find.text('Not Ekle'), findsOneWidget);
  });

  testWidgets('tappables are at least 48x48', (tester) async {
    await pumpPanel(tester, panel);
    expectMinTapTarget(tester, find.byType(ChromeIconButton));
    expectMinTapTarget(tester, find.byKey(const ValueKey('sticky-note-add')));
  });

  testWidgets('close clears the active panel', (tester) async {
    final c = await pumpPanel(
      tester,
      panel,
      setup: (c) =>
          c.read(activePanelProvider.notifier).state = ToolType.stickyNote,
    );
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pump();
    expect(c.read(activePanelProvider), isNull);
  });

  testWidgets('add tile creates an undoable note and closes the panel',
      (tester) async {
    final c = await pumpPanel(
      tester,
      panel,
      setup: (c) =>
          c.read(activePanelProvider.notifier).state = ToolType.stickyNote,
    );
    expect(c.read(canUndoProvider), isFalse);
    await tester.tap(find.byKey(const ValueKey('sticky-note-add')));
    await tester.pump();
    expect(c.read(canUndoProvider), isTrue);
    expect(c.read(activePanelProvider), isNull);
  });
}
