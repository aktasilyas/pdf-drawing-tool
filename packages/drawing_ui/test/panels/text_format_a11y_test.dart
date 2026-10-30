import 'package:drawing_core/drawing_core.dart' hide Page;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/infinite_background_panel.dart';
import 'package:drawing_ui/src/panels/panels.dart';
import 'package:drawing_ui/src/widgets/color_swatch_target.dart';
import 'package:drawing_ui/src/widgets/text_style_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/panel_harness.dart';

const _toggleKeys = [
  'text-style-bold',
  'text-style-italic',
  'text-style-underline',
];

void main() {
  testWidgets('text settings: style toggles are labelled toggle buttons',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(tester, const TextSettingsPanel());
    final s = tester.element(find.byType(TextSettingsPanel)).drawingStrings;

    for (final label in [
      s.panels.bold,
      s.panels.italic,
      s.panels.underline,
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(
          label: label,
          isButton: true,
          hasToggledState: true,
          isToggled: false,
          hasTapAction: true,
        ),
      );
    }

    await tester.tap(find.byKey(const ValueKey('text-style-bold')));
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel(s.panels.bold)),
      isSemantics(
        label: s.panels.bold,
        isButton: true,
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
      ),
    );

    for (final k in _toggleKeys) {
      expectMinTapTarget(tester, find.byKey(ValueKey(k)));
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('text style popup: toggles and close meet a11y guidelines',
      (tester) async {
    final handle = tester.ensureSemantics();
    var closed = 0;
    TextElement? changed;
    await pumpPanel(
      tester,
      SizedBox(
        width: 400,
        height: 800,
        child: Stack(
          children: [
            TextStylePopup(
              textElement: const TextElement(id: 't', text: 'Hi', x: 0, y: 0),
              zoom: 1,
              canvasOffset: Offset.zero,
              onStyleChanged: (e) => changed = e,
              onClose: () => closed++,
            ),
          ],
        ),
      ),
    );
    final s = tester.element(find.byType(TextStylePopup)).drawingStrings;

    expect(
      tester.getSemantics(find.bySemanticsLabel(s.panels.italic)),
      isSemantics(
        label: s.panels.italic,
        isButton: true,
        hasToggledState: true,
        isToggled: false,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.bySemanticsLabel(s.panels.italic));
    await tester.pump();
    expect(changed, isNotNull);
    expect(
      tester.getSemantics(find.bySemanticsLabel(s.panels.italic)),
      isSemantics(
        label: s.panels.italic,
        isButton: true,
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
      ),
    );

    expectMinTapTarget(tester, find.byType(IconButton));
    for (final label in [s.panels.bold, s.panels.italic, s.panels.underline]) {
      expect(
        tester.getSize(find.bySemanticsLabel(label)).shortestSide,
        greaterThanOrEqualTo(48),
      );
    }
    await tester.tap(find.byTooltip(s.panels.close));
    expect(closed, 1);
    handle.dispose();
  });

  testWidgets(
      'text style popup: four labelled 48dp swatches and More fit one row',
      (tester) async {
    final handle = tester.ensureSemantics();
    TextElement? changed;
    await pumpPanel(
      tester,
      SizedBox(
        width: 400,
        height: 800,
        child: Stack(
          children: [
            TextStylePopup(
              textElement: const TextElement(id: 't', text: 'Hi', x: 0, y: 0),
              zoom: 1,
              canvasOffset: Offset.zero,
              onStyleChanged: (e) => changed = e,
              onClose: () {},
            ),
          ],
        ),
      ),
    );
    final s = tester.element(find.byType(TextStylePopup)).drawingStrings;
    final row = find.byKey(const ValueKey('text-style-colors'));
    final swatches = find.descendant(
      of: row,
      matching: find.byType(ColorSwatchTarget),
    );
    final more = find.descendant(
      of: row,
      matching: find.bySemanticsLabel(s.selection.more),
    );

    expect(swatches, findsNWidgets(4));
    expect(more, findsOneWidget);
    expectMinTapTarget(tester, swatches);
    expectMinTapTarget(tester, more);

    // One row: every target shares the vertical centre of the first.
    final rowY = tester.getCenter(swatches.first).dy;
    for (final e in swatches.evaluate()) {
      final box = e.renderObject! as RenderBox;
      expect(box.localToGlobal(box.size.center(Offset.zero)).dy, rowY);
    }
    expect(tester.getCenter(more).dy, rowY);

    final label = s.toolbar.color('#E53935');
    expect(
      tester.getSemantics(find.bySemanticsLabel(label)),
      isSemantics(
        label: label,
        isButton: true,
        hasSelectedState: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.bySemanticsLabel(label));
    // Swatches also accept a double tap (full palette), so a single tap
    // resolves only after the double-tap timeout.
    await tester.pump(kDoubleTapTimeout);
    expect(changed?.color, 0xFFE53935);
    expect(
      tester.getSemantics(find.bySemanticsLabel(label)),
      isSemantics(
        label: label,
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('infinite background close is a labelled 48dp button',
      (tester) async {
    final handle = tester.ensureSemantics();
    var closed = 0;
    await pumpPanel(tester, InfiniteBackgroundPanel(onClose: () => closed++));
    final s =
        tester.element(find.byType(InfiniteBackgroundPanel)).drawingStrings;

    final close = find.byTooltip(s.panels.close);
    expect(close, findsOneWidget);
    expectMinTapTarget(tester, close);
    await tester.tap(close);
    expect(closed, 1);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
