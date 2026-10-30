import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _field = find.byKey(const ValueKey('go-to-page-field'));
final _go = find.byKey(const ValueKey('go-to-page-go'));
const _tr = PageStringsTr();

/// Opens the dialog for [pageCount] pages; [results] receives the pop value.
Future<void> _open(
  WidgetTester tester,
  List<int?> results, {
  int pageCount = 12,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => results
                .add(await pickGoToPageIndex(context, pageCount: pageCount)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

bool _goEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_go).onPressed != null;

void main() {
  group('GoToPageDialog', () {
    testWidgets('valid page closes the dialog with its 0-based index',
        (tester) async {
      final results = <int?>[];
      await _open(tester, results);

      await tester.enterText(_field, '7');
      await tester.pump();
      await tester.tap(_go);
      await tester.pumpAndSettle();

      expect(find.byType(GoToPageDialog), findsNothing);
      expect(results, [6]);
    });

    testWidgets('keyboard submit of a valid page navigates too',
        (tester) async {
      final results = <int?>[];
      await _open(tester, results);

      await tester.enterText(_field, '12');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(results, [11]);
    });

    for (final input in ['0', '13', '99999999999999999999999']) {
      testWidgets('out-of-range $input shows an inline error and stays open',
          (tester) async {
        final results = <int?>[];
        await _open(tester, results);

        await tester.enterText(_field, input);
        await tester.pump();
        await tester.tap(_go);
        await tester.pumpAndSettle();

        expect(find.byType(GoToPageDialog), findsOneWidget);
        expect(find.text(_tr.goToPageOutOfRange(12)), findsOneWidget);
        expect(results, isEmpty);
      });
    }

    testWidgets('editing the number clears the error', (tester) async {
      await _open(tester, []);

      await tester.enterText(_field, '0');
      await tester.pump();
      await tester.tap(_go);
      await tester.pump();
      expect(find.text(_tr.goToPageOutOfRange(12)), findsOneWidget);

      await tester.enterText(_field, '3');
      await tester.pump();
      expect(find.text(_tr.goToPageOutOfRange(12)), findsNothing);
    });

    testWidgets('non-digit characters cannot be entered', (tester) async {
      await _open(tester, []);

      await tester.enterText(_field, '-1.5a');
      await tester.pump();

      expect(tester.widget<TextField>(_field).controller!.text, '15');
    });

    testWidgets('Go is disabled while the field is empty', (tester) async {
      await _open(tester, []);
      expect(_goEnabled(tester), isFalse);

      await tester.enterText(_field, '2');
      await tester.pump();
      expect(_goEnabled(tester), isTrue);

      await tester.enterText(_field, '');
      await tester.pump();
      expect(_goEnabled(tester), isFalse);
    });

    testWidgets('cancel returns null', (tester) async {
      final results = <int?>[];
      await _open(tester, results);

      await tester.tap(find.text(const PanelStringsTr().cancel));
      await tester.pumpAndSettle();

      expect(find.byType(GoToPageDialog), findsNothing);
      expect(results, [null]);
    });
  });

  testWidgets('PageIndicatorBar navigates to the page chosen in the dialog',
      (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pageCountProvider.overrideWith((ref) => 5),
          currentPageIndexProvider.overrideWith((ref) => 0),
        ],
        child: MaterialApp(
          home: Scaffold(body: PageIndicatorBar(onPageChanged: changes.add)),
        ),
      ),
    );

    await tester.tap(find.text('Sayfa 1 / 5'));
    await tester.pumpAndSettle();
    await tester.enterText(_field, '4');
    await tester.pump();
    await tester.tap(_go);
    await tester.pumpAndSettle();

    expect(changes, [3]);
  });
}
