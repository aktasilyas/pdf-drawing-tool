import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/page_options_widgets.dart';
import 'package:drawing_ui/src/widgets/color_picker_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

DrawingStrings _strings(WidgetTester tester) =>
    tester.element(find.byType(Scaffold)).drawingStrings;

void main() {
  testWidgets('panel close and action buttons are labelled 48dp buttons',
      (tester) async {
    final handle = tester.ensureSemantics();
    var closed = 0;
    await tester.pumpWidget(_host(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PanelCloseButton(onTap: () => closed++),
          PanelActionButton(label: 'Clear page', onPressed: () {}),
        ],
      ),
    ));

    final close = _strings(tester).panels.close;
    expect(
      tester.getSemantics(find.bySemanticsLabel(close)),
      isSemantics(label: close, isButton: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Clear page')),
      isSemantics(label: 'Clear page', isButton: true, hasTapAction: true),
    );
    tester.semantics.tap(find.semantics.byLabel(close));
    expect(closed, 1);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('color picker cancel/done are separate labelled buttons',
      (tester) async {
    final handle = tester.ensureSemantics();
    var done = 0;
    await tester.pumpWidget(_host(
      SizedBox(
        width: 320,
        child: ColorPickerActions(
          onCancel: () {},
          onDone: () => done++,
          textColor: Colors.black,
          primaryColor: Colors.blue,
          dividerColor: Colors.grey,
        ),
      ),
    ));

    final p = _strings(tester).panels;
    for (final label in [p.colorCancel, p.colorDone]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(label: label, isButton: true, hasTapAction: true),
        reason: label,
      );
    }
    tester.semantics.tap(find.semantics.byLabel(p.colorDone));
    expect(done, 1);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  for (final compact in [false, true]) {
    testWidgets('page option rows are 48dp buttons (compact: $compact)',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(
        SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PageOptionsMenuItem(
                icon: ElyanotesIcons.sliders,
                label: 'Enabled row',
                compact: compact,
                onTap: () {},
              ),
              PageOptionsMenuItem(
                icon: ElyanotesIcons.sliders,
                label: 'Disabled row',
                compact: compact,
              ),
            ],
          ),
        ),
      ));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Enabled row')),
        isSemantics(
          label: 'Enabled row',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Disabled row')),
        isSemantics(
          label: 'Disabled row',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      for (final row in tester.widgetList(find.byType(PageOptionsMenuItem))) {
        expect(
          tester.getSize(find.byWidget(row)).height,
          greaterThanOrEqualTo(48),
        );
      }

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
