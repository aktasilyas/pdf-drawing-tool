import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/inputs/app_search_field.dart';

Widget _app(String text) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: AppSearchField(text: text, onChanged: (_) {})),
    );

String _shown(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  testWidgets('enabled border is a 1dp palette.border hairline',
      (tester) async {
    await tester.pumpWidget(_app(''));
    final decoration =
        tester.widget<TextField>(find.byType(TextField)).decoration!;
    final side = (decoration.enabledBorder! as OutlineInputBorder).borderSide;
    expect(side.color, AppPalette.light.border);
    expect(side.width, 1);
  });

  testWidgets('rebuild with the same text keeps what the user typed',
      (tester) async {
    await tester.pumpWidget(_app(''));
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pumpWidget(_app(''));
    expect(_shown(tester), 'ab');
    // Let the debounce timer finish.
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('external text change updates the field', (tester) async {
    await tester.pumpWidget(_app('bio'));
    await tester.pumpWidget(_app('bio2'));
    expect(_shown(tester), 'bio2');
    await tester.pumpWidget(_app(''));
    expect(_shown(tester), '');
  });

  testWidgets('clearing text externally after typing clears the field',
      (tester) async {
    await tester.pumpWidget(_app('x'));
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pumpWidget(_app('ab'));
    await tester.pumpWidget(_app(''));
    expect(_shown(tester), '');
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('clear button exposes the given localized label',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppSearchField(
            text: 'ab',
            clearTooltip: 'Aramayı temizle',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppSearchField(
            text: 'abc',
            clearTooltip: 'Aramayı temizle',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.byTooltip('Aramayı temizle'), findsOneWidget);
    expect(find.bySemanticsLabel('Aramayı temizle'), findsOneWidget);
  });

  testWidgets('clear button falls back to the Material clear tooltip',
      (tester) async {
    await tester.pumpWidget(_app('x'));
    await tester.pumpWidget(_app('xy'));
    final material =
        MaterialLocalizations.of(tester.element(find.byType(AppSearchField)));
    expect(find.byTooltip(material.clearButtonTooltip), findsOneWidget);
  });
}
