import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/buttons/app_icon_button.dart';

import '../../../helpers/a11y.dart';

Future<void> _pump(WidgetTester tester, AppIconButton button) {
  return tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: button)),
  ));
}

void main() {
  testWidgets('tooltip doubles as the semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    var taps = 0;
    await _pump(
      tester,
      AppIconButton(
        icon: Icons.add,
        tooltip: 'Ekle',
        onPressed: () => taps++,
      ),
    );

    // The tooltip itself stays in the tree for pointer users and finders.
    expect(find.byTooltip('Ekle'), findsOneWidget);

    final nodes = find.semantics.byLabel('Ekle');
    expect(nodes, findsOne);
    expect(
      nodes.evaluate().single,
      isSemantics(
        label: 'Ekle',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.byType(AppIconButton));
    expect(taps, 1);
  });

  testWidgets('semanticLabel wins over the tooltip', (tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await _pump(
      tester,
      AppIconButton(
        icon: Icons.star,
        tooltip: 'Favori',
        semanticLabel: 'Favorilerden çıkar',
        onPressed: () {},
      ),
    );

    expect(find.semantics.byLabel('Favorilerden çıkar'), findsOne);
    expect(find.semantics.byLabel('Favori'), findsNothing);
  });

  testWidgets('a label with no tooltip still reaches the tree', (tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await _pump(
      tester,
      AppIconButton(
        icon: Icons.close,
        semanticLabel: 'Kapat',
        onPressed: () {},
      ),
    );

    expect(find.semantics.byLabel('Kapat'), findsOne);
    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('disabled exposes no tap action', (tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await _pump(
      tester,
      const AppIconButton(icon: Icons.add, tooltip: 'Ekle'),
    );

    expect(
      find.semantics.byLabel('Ekle').evaluate().single,
      isSemantics(
        label: 'Ekle',
        isButton: true,
        isEnabled: false,
        hasEnabledState: true,
        hasTapAction: false,
      ),
    );
  });

  test('an unlabelled icon button is a programming error', () {
    expect(
      () => AppIconButton(icon: Icons.add, onPressed: () {}),
      throwsAssertionError,
    );
  });

  for (final size in AppIconButtonSize.values) {
    testWidgets('$size meets the 48dp tap-target guideline', (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(handle.dispose);
      await _pump(
        tester,
        AppIconButton(
          icon: Icons.add,
          tooltip: 'Ekle',
          size: size,
          onPressed: () {},
        ),
      );
      await expectTapTargets(tester);
    });
  }
}
