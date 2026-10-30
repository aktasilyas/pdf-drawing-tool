import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/buttons/app_icon_button.dart';
import 'package:example_app/core/widgets/layout/app_chip.dart';
import 'package:example_app/l10n/l10n.dart';

import '../../../helpers/l10n.dart';

Future<void> _pump(WidgetTester tester, Widget chip) {
  return tester.pumpWidget(localizedApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: chip)),
  ));
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(AppChip)))!;

void main() {
  for (final selected in [false, true]) {
    testWidgets('announces label and selected state (selected: $selected)',
        (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await _pump(
        tester,
        AppChip(label: 'A4', isSelected: selected, onTap: () => taps++),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('A4')),
        isSemantics(
          label: 'A4',
          isButton: true,
          hasSelectedState: true,
          isSelected: selected,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.byType(AppChip));
      expect(taps, 1);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  testWidgets('tap area is 48dp tall while the pill stays compact',
      (tester) async {
    await _pump(tester, AppChip(label: 'A4', onTap: () {}));
    expect(
      tester.getSize(find.byType(AppChip)).height,
      greaterThanOrEqualTo(AppSpacing.minTouchTarget),
    );

    // A tap just above the pill (inside the 48dp band) still selects.
    var taps = 0;
    await _pump(tester, AppChip(label: 'A4', onTap: () => taps++));
    final rect = tester.getRect(find.byType(AppChip));
    await tester.tapAt(Offset(rect.center.dx, rect.top + 2));
    expect(taps, 1);
  });

  testWidgets('delete is a separate labelled 48dp button', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    var deletes = 0;
    await _pump(
      tester,
      AppChip(
        label: 'Kırtasiye',
        onTap: () => taps++,
        onDelete: () => deletes++,
      ),
    );
    final removeLabel = _l10n(tester).commonRemoveItem('Kırtasiye');

    expect(
      tester.getSemantics(find.bySemanticsLabel(removeLabel)),
      isSemantics(label: removeLabel, isButton: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Kırtasiye')),
      isSemantics(label: 'Kırtasiye', isButton: true, hasTapAction: true),
    );

    await tester.tap(find.byTooltip(removeLabel));
    expect(deletes, 1);
    expect(taps, 0);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('no delete button without onDelete', (tester) async {
    await _pump(tester, AppChip(label: 'A4', onTap: () {}));
    expect(find.byType(AppIconButton), findsNothing);
  });
}
