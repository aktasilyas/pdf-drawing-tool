import 'package:drawing_core/drawing_core.dart' hide Page;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/infinite_background_chips.dart';
import 'package:drawing_ui/src/panels/infinite_background_logic.dart';
import 'package:drawing_ui/src/panels/infinite_background_panel.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/panel_harness.dart';

void main() {
  final panel = InfiniteBackgroundPanel(onClose: () {});

  testWidgets('choosing a pattern updates the page and keeps its colour',
      (tester) async {
    final c = await pumpPanel(tester, panel);
    await tester.tap(find.text('Sarı'));
    await tester.pump();
    await tester.tap(find.text('Izgara'));
    await tester.pump();

    final bg = c.read(currentPageProvider).background;
    expect(bg.type, BackgroundType.grid);
    expect(bg.color, InfiniteBackgroundColors.yellow);
  });

  testWidgets('choosing a colour keeps the pattern', (tester) async {
    final c = await pumpPanel(tester, panel);
    await tester.tap(find.text('Noktalı'));
    await tester.pump();
    await tester.tap(find.text('Siyah'));
    await tester.pump();

    final bg = c.read(currentPageProvider).background;
    expect(bg.type, BackgroundType.dotted);
    expect(bg.color, InfiniteBackgroundColors.black);
  });

  testWidgets('selected chips are marked', (tester) async {
    await pumpPanel(tester, panel);
    expect(find.byIcon(Icons.check), findsOneWidget); // white colour
    await tester.tap(find.text('Sarı'));
    await tester.pump();
    final yellow = tester.widget<InfiniteBackgroundColorChip>(
        find.widgetWithText(InfiniteBackgroundColorChip, 'Sarı'));
    expect(yellow.isSelected, isTrue);
    final plain = tester.widget<InfiniteBackgroundPatternChip>(
        find.widgetWithText(InfiniteBackgroundPatternChip, 'Düz'));
    expect(plain.isSelected, isTrue);
  });

  testWidgets('every chip is at least 48dp', (tester) async {
    await pumpPanel(tester, panel);
    expectMinTapTarget(tester, find.byType(InfiniteBackgroundPatternChip));
    expectMinTapTarget(tester, find.byType(InfiniteBackgroundColorChip));
  });

  testWidgets('no overflow at textScaler 1.3', (tester) async {
    await pumpPanel(tester, panel, textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  test('mini painter repaints only when fields change', () {
    final a = MiniPatternPainter(
        pattern: InfiniteBackgroundPattern.grid, color: Colors.black);
    expect(
        a.shouldRepaint(MiniPatternPainter(
            pattern: InfiniteBackgroundPattern.grid, color: Colors.black)),
        isFalse);
    expect(
        a.shouldRepaint(MiniPatternPainter(
            pattern: InfiniteBackgroundPattern.dotted, color: Colors.black)),
        isTrue);
  });
}
