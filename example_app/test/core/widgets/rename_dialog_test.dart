import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/core/theme/index.dart';

import '../../helpers/l10n.dart';

Future<Future<String?> Function()> _pumpHost(WidgetTester tester) async {
  String? result;
  var done = false;
  await tester.pumpWidget(localizedApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showDialog<String>(
              context: context,
              builder: (_) =>
                  const RenameDialog(initialTitle: 'Doc', labelText: 'Name'),
            );
            done = true;
          },
          child: const Text('open'),
        ),
      ),
    ),
  ));
  return () async => done ? result : null;
}

void main() {
  FilledButton saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('Enter submits the trimmed title', (tester) async {
    final result = await _pumpHost(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  New name ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(RenameDialog), findsNothing);
    expect(await result(), 'New name');
  });

  testWidgets('Save is disabled for whitespace-only input and Enter is a no-op',
      (tester) async {
    await _pumpHost(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(saveButton(tester).onPressed, isNotNull);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNull);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(RenameDialog), findsOneWidget);
  });

  testWidgets('Cancel pops null', (tester) async {
    final result = await _pumpHost(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Changed');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result(), isNull);
    expect(find.byType(RenameDialog), findsNothing);
  });

  testWidgets('input is limited to kMaxTitleLength', (tester) async {
    await _pumpHost(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField), 'a' * (kMaxTitleLength + 20));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, kMaxTitleLength);
  });
}
