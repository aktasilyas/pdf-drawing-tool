import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SelectionAction _action(
  SelectionActionKind kind, {
  bool enabled = true,
  bool destructive = false,
}) =>
    SelectionAction(
      id: kind.name,
      icon: ElyanotesIcons.more,
      kind: kind,
      isEnabled: enabled,
      isDestructive: destructive,
    );

/// Labels come from the strings object, not hard-coded Turkish copy.
String _label(SelectionActionKind kind) => kind.label(const DrawingStringsTr());

Widget _host(ValueChanged<SelectionAction> onTap) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SelectionOverflowMenu(
            topRowActions: [
              _action(SelectionActionKind.cut),
              _action(SelectionActionKind.copy, enabled: false),
              _action(SelectionActionKind.duplicate),
            ],
            actions: [
              _action(SelectionActionKind.bringToFront),
              _action(SelectionActionKind.paste, enabled: false),
              _action(SelectionActionKind.delete, destructive: true),
            ],
            onActionTap: onTap,
          ),
        ),
      ),
    );

void main() {
  void tablet(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('enabled actions are named, enabled buttons', (tester) async {
    tablet(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host((_) {}));

    for (final kind in [
      SelectionActionKind.cut,
      SelectionActionKind.duplicate,
      SelectionActionKind.bringToFront,
      SelectionActionKind.delete,
    ]) {
      final label = _label(kind);
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: kind.name);
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(
          label: label,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
        reason: kind.name,
      );
    }
    handle.dispose();
  });

  testWidgets('disabled actions report disabled and have no tap action',
      (tester) async {
    tablet(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host((_) {}));

    for (final kind in [SelectionActionKind.copy, SelectionActionKind.paste]) {
      final label = _label(kind);
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(
          label: label,
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
        reason: kind.name,
      );
    }
    handle.dispose();
  });

  testWidgets('tapping an enabled action calls the handler', (tester) async {
    tablet(tester);
    final handle = tester.ensureSemantics();
    final tapped = <SelectionActionKind>[];
    await tester.pumpWidget(_host((a) => tapped.add(a.kind)));

    tester.semantics.tap(
      find.semantics.byLabel(_label(SelectionActionKind.duplicate)),
    );
    tester.semantics.tap(
      find.semantics.byLabel(_label(SelectionActionKind.bringToFront)),
    );
    await tester.tap(find.text(_label(SelectionActionKind.delete)));
    // A disabled item ignores pointer taps.
    await tester.tap(find.text(_label(SelectionActionKind.paste)));

    expect(tapped, [
      SelectionActionKind.duplicate,
      SelectionActionKind.bringToFront,
      SelectionActionKind.delete,
    ]);
    handle.dispose();
  });

  testWidgets('meets tap-target and label guidelines', (tester) async {
    tablet(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host((_) {}));

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
