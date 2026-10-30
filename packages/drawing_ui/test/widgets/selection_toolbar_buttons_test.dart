import 'package:drawing_ui/src/models/selection_action.dart';
import 'package:drawing_ui/src/models/selection_action_kind.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/widgets/selection_toolbar_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SelectionAction _action(
  SelectionActionKind kind, {
  bool enabled = true,
  int? colorIndicator,
}) =>
    SelectionAction(
      id: kind.name,
      icon: ElyanotesIcons.more,
      kind: kind,
      isEnabled: enabled,
      colorIndicator: colorIndicator,
    );

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectionToolbarButton(
                key: const Key('cut'),
                action: _action(SelectionActionKind.cut),
                onTap: () {},
              ),
              SelectionToolbarButton(
                key: const Key('color'),
                action: _action(
                  SelectionActionKind.color,
                  colorIndicator: 0xFF000000,
                ),
                onTap: () {},
              ),
              SelectionToolbarButton(
                key: const Key('disabled'),
                action: _action(SelectionActionKind.duplicate, enabled: false),
                onTap: () {},
              ),
              SelectionToolbarIconButton(
                key: const Key('more'),
                icon: ElyanotesIcons.more,
                tooltip: 'Daha fazla',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  const keys = ['cut', 'color', 'disabled', 'more'];

  testWidgets('every selection toolbar button is at least 48x48',
      (tester) async {
    await _pump(tester);
    for (final k in keys) {
      final size = tester.getSize(find.byKey(Key(k)));
      expect(size.width, greaterThanOrEqualTo(48), reason: k);
      expect(size.height, greaterThanOrEqualTo(48), reason: k);
    }
  });

  testWidgets('buttons expose the button flag and the enabled state',
      (tester) async {
    await _pump(tester);
    for (final k in ['cut', 'color', 'more']) {
      expect(
        tester.getSemantics(find.byKey(Key(k))),
        containsSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
        reason: k,
      );
    }
    expect(
      tester.getSemantics(find.byKey(const Key('disabled'))),
      containsSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasTapAction: false,
      ),
    );
  });

  testWidgets('enabled buttons meet the tap target and label guidelines',
      (tester) async {
    await _pump(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
