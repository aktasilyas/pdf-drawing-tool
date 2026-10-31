import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/sticker_panel_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/panel_harness.dart';

/// Past the double-tap timeout, so a single tap on a cell is delivered.
const _tapDelay = Duration(milliseconds: 500);

void _openSticker(ProviderContainer c) =>
    c.read(activePanelProvider.notifier).state = ToolType.sticker;

void main() {
  const panel = StickerPanel();

  testWidgets('switching categories changes the grid', (tester) async {
    await pumpPanel(tester, panel);
    expect(find.text('😀'), findsOneWidget);
    expect(find.text('🐶'), findsNothing);

    await tester.tap(find.text('Hayvanlar'));
    await tester.pumpAndSettle();

    expect(find.text('🐶'), findsOneWidget);
    expect(find.text('😀'), findsNothing);
  });

  testWidgets('insert is disabled until a sticker is selected', (tester) async {
    final c = await pumpPanel(tester, panel, setup: _openSticker);
    await tester.tap(find.text('Çıkartma Ekle'));
    await tester.pump();

    expect(c.read(stickerPlacementProvider).isPlacing, isFalse);
    expect(c.read(activePanelProvider), ToolType.sticker);
  });

  testWidgets('selected sticker + insert starts placement and closes panel',
      (tester) async {
    final c = await pumpPanel(tester, panel, setup: _openSticker);
    await tester.tap(find.text('😃'));
    await tester.pump(_tapDelay);
    final cell = tester.widget<StickerCell>(
      find.ancestor(of: find.text('😃'), matching: find.byType(StickerCell)),
    );
    expect(cell.selected, isTrue);

    await tester.tap(find.text('Çıkartma Ekle'));
    await tester.pump();

    expect(c.read(stickerPlacementProvider).selectedEmoji, '😃');
    expect(c.read(activePanelProvider), isNull);
  });

  testWidgets('double-tapping a sticker starts placement', (tester) async {
    final c = await pumpPanel(tester, panel, setup: _openSticker);
    await tester.tap(find.text('Yiyecek'));
    await tester.pumpAndSettle();

    final pizza = find.text('🍕');
    await tester.tap(pizza);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(pizza);
    await tester.pumpAndSettle();

    expect(c.read(stickerPlacementProvider).selectedEmoji, '🍕');
    expect(c.read(activePanelProvider), isNull);
  });

  testWidgets('cells and the insert button are 48dp touch targets',
      (tester) async {
    await pumpPanel(tester, panel);
    expectMinTapTarget(tester, find.byType(StickerCell));
    expectMinTapTarget(tester, find.byType(StickerActionButton));
  });

  testWidgets('cells stay 48dp in a 300dp panel', (tester) async {
    await pumpPanel(
      tester,
      const Center(child: SizedBox(width: 300, child: panel)),
    );
    expectMinTapTarget(tester, find.byType(StickerCell));
  });

  testWidgets('cells announce as selectable buttons; semantics tap selects',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(tester, panel);

    expect(
      tester.getSemantics(find.bySemanticsLabel('😃')),
      isSemantics(
        label: '😃',
        isButton: true,
        hasSelectedState: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );

    tester.semantics.tap(find.semantics.byLabel('😃'));
    await tester.pump();

    expect(
      tester.getSemantics(find.bySemanticsLabel('😃')),
      isSemantics(
        label: '😃',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a cell offers an insert custom action (no double tap needed)',
      (tester) async {
    final handle = tester.ensureSemantics();
    final c = await pumpPanel(tester, panel, setup: _openSticker);

    final node = tester.getSemantics(find.bySemanticsLabel('😃'));
    final insert = CustomSemanticsAction(label: 'Çıkartma Ekle');
    final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
    owner.performAction(
      node.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(insert),
    );
    await tester.pumpAndSettle();

    expect(c.read(stickerPlacementProvider).selectedEmoji, '😃');
    expect(c.read(activePanelProvider), isNull);
    handle.dispose();
  });

  testWidgets('insert button is one labelled button node', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(tester, panel);
    await tester.tap(find.text('😃'));
    await tester.pump(_tapDelay);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Çıkartma Ekle')),
      isSemantics(
        label: 'Çıkartma Ekle',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  // Pumped on their own: the grid clips its last row, and a clipped cell's
  // semantics rect is smaller than the cell itself.
  testWidgets('cell and insert button meet the tap-target guidelines',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(
      tester,
      Row(
        children: [
          SizedBox.square(
            dimension: 56,
            child: StickerCell(
              emoji: '😀',
              selected: true,
              onTap: () {},
              onDoubleTap: () {},
            ),
          ),
          Expanded(
            child: StickerActionButton(
              label: 'Çıkartma Ekle',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('no overflow with textScaler 1.3', (tester) async {
    await pumpPanel(tester, panel, textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category tab bar is a 48dp target', (tester) async {
    await pumpPanel(tester, panel);
    expectMinTapTarget(tester, find.byType(TabBar));
  });

  testWidgets('full panel meets the tap-target guidelines at 380dp',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(tester, panel);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('selecting a tab via semantics switches the grid',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(tester, panel);
    expect(find.text('🐶'), findsNothing);

    tester.semantics.tap(find.semantics.byLabel(RegExp('Hayvanlar')));
    await tester.pumpAndSettle();

    expect(find.text('🐶'), findsOneWidget);
    handle.dispose();
  });
}
