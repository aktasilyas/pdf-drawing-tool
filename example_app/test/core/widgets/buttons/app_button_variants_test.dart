import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/buttons/index.dart';

class _MockCallback extends Mock {
  void call();
}

Type _buttonType(AppButtonVariant v) => switch (v) {
      AppButtonVariant.outline => OutlinedButton,
      AppButtonVariant.text => TextButton,
      _ => ElevatedButton,
    };

Future<void> _pump(WidgetTester tester, Widget button) =>
    tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: button)),
    ));

void main() {
  for (final variant in AppButtonVariant.values) {
    group('AppButton ${variant.name}', () {
      testWidgets('enabled: renders label and fires onPressed', (tester) async {
        final onPressed = _MockCallback();
        await _pump(
          tester,
          AppButton(label: 'Go', variant: variant, onPressed: onPressed.call),
        );

        expect(find.byType(_buttonType(variant)), findsOneWidget);
        expect(find.text('Go'), findsOneWidget);
        await tester.tap(find.byType(AppButton));
        verify(onPressed.call).called(1);
      });

      testWidgets('disabled: no callback and dimmed', (tester) async {
        await _pump(tester, AppButton(label: 'Go', variant: variant));

        final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
        expect(opacity.opacity, 0.5);
        await tester.tap(find.byType(AppButton), warnIfMissed: false);
        expect(find.byType(_buttonType(variant)), findsOneWidget);
      });

      testWidgets('loading: spinner replaces label, tap ignored',
          (tester) async {
        final onPressed = _MockCallback();
        await _pump(
          tester,
          AppButton(
            label: 'Go',
            variant: variant,
            isLoading: true,
            onPressed: onPressed.call,
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Go'), findsNothing);
        await tester.tap(find.byType(AppButton), warnIfMissed: false);
        verifyNever(onPressed.call);
      });
    });
  }

  testWidgets('sizes map to 36/44/52dp heights', (tester) async {
    const heights = {
      AppButtonSize.small: 36.0,
      AppButtonSize.medium: 44.0,
      AppButtonSize.large: 52.0,
    };
    for (final e in heights.entries) {
      await _pump(
          tester, AppButton(label: 'Go', size: e.key, onPressed: () {}));
      expect(tester.getSize(find.byType(AppButton)).height, e.value);
    }
  });

  testWidgets('shows leading and trailing icons; expanded fills width',
      (tester) async {
    await _pump(
      tester,
      AppButton(
        label: 'Go',
        leadingIcon: Icons.add,
        trailingIcon: Icons.chevron_right,
        isExpanded: true,
        onPressed: () {},
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(tester.getSize(find.byType(AppButton)).width, 800);
  });
}
