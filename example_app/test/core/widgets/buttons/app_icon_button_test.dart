import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/buttons/app_icon_button.dart';

Future<void> _pump(
  WidgetTester tester,
  AppIconButton button, {
  ThemeData? theme,
}) {
  return tester.pumpWidget(MaterialApp(
    theme: theme ?? AppTheme.light,
    home: Scaffold(body: Center(child: button)),
  ));
}

Color? _iconColor(WidgetTester tester) =>
    IconTheme.of(tester.element(find.byIcon(Icons.add))).color;

Color? _fill(WidgetTester tester) => tester
    .widget<Material>(find
        .descendant(
          of: find.byType(AppIconButton),
          matching: find.byType(Material),
        )
        .first)
    .color;

void main() {
  group('ghost', () {
    testWidgets('icon is textMuted in light theme', (tester) async {
      await _pump(
        tester,
        AppIconButton(
          icon: Icons.add,
          variant: AppIconButtonVariant.ghost,
          onPressed: () {},
        ),
      );
      expect(_iconColor(tester), AppPalette.light.textMuted);
    });

    testWidgets('icon is textMuted in dark theme', (tester) async {
      await _pump(
        tester,
        AppIconButton(
          icon: Icons.add,
          variant: AppIconButtonVariant.ghost,
          onPressed: () {},
        ),
        theme: AppTheme.dark,
      );
      expect(_iconColor(tester), AppPalette.dark.textMuted);
    });

    testWidgets('selected uses accentContainer fill and accent icon',
        (tester) async {
      await _pump(
        tester,
        AppIconButton(
          icon: Icons.add,
          variant: AppIconButtonVariant.ghost,
          isSelected: true,
          onPressed: () {},
        ),
      );
      expect(_iconColor(tester), AppPalette.light.accent);
      expect(_fill(tester), AppPalette.light.accentContainer);
    });

    testWidgets('disabled uses textDisabled and no Opacity', (tester) async {
      await _pump(
        tester,
        const AppIconButton(
          icon: Icons.add,
          variant: AppIconButtonVariant.ghost,
        ),
      );
      expect(_iconColor(tester), AppPalette.light.textDisabled);
      expect(
        find.descendant(
          of: find.byType(AppIconButton),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });

    testWidgets('honours iconColor', (tester) async {
      await _pump(
        tester,
        AppIconButton(
          icon: Icons.add,
          variant: AppIconButtonVariant.ghost,
          iconColor: AppPalette.light.danger,
          onPressed: () {},
        ),
      );
      expect(_iconColor(tester), AppPalette.light.danger);
    });
  });

  group('filled', () {
    testWidgets('uses accent fill and onAccent icon', (tester) async {
      await _pump(
        tester,
        AppIconButton(icon: Icons.add, onPressed: () {}),
      );
      expect(_fill(tester), AppPalette.light.accent);
      expect(_iconColor(tester), AppPalette.light.onAccent);
    });
  });
}
