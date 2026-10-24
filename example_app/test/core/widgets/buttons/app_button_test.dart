import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/buttons/app_button.dart';

Future<Color?> _labelColor(
  WidgetTester tester,
  AppButtonVariant variant,
) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: AppButton(label: 'Go', variant: variant, onPressed: () {}),
    ),
  ));
  final style =
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).style;
  return style?.foregroundColor?.resolve(<WidgetState>{});
}

void main() {
  testWidgets('primary uses onAccent in dark theme', (tester) async {
    expect(await _labelColor(tester, AppButtonVariant.primary),
        AppPalette.dark.onAccent);
  });

  testWidgets('destructive uses onDanger in dark theme', (tester) async {
    expect(await _labelColor(tester, AppButtonVariant.destructive),
        AppPalette.dark.onDanger);
  });
}
