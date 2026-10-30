import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(
  WidgetTester tester,
  void Function(Future<PdfPageRange?>) onFuture, {
  int pageCount = 640,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => onFuture(
              showPdfPageRangeSheet(
                context,
                pageCount: pageCount,
                maxPages: 500,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder _key(String k) => find.byKey(ValueKey(k));

Future<void> _enter(WidgetTester tester, String start, String end) async {
  await tester.tap(_key('pdf-range-choose'));
  await tester.pumpAndSettle();
  await tester.enterText(_key('pdf-range-start'), start);
  await tester.enterText(_key('pdf-range-end'), end);
  await tester.pumpAndSettle();
}

bool _importEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_key('pdf-range-import')).onPressed != null;

void main() {
  testWidgets('first option returns 1..500', (tester) async {
    late Future<PdfPageRange?> result;
    await _open(tester, (f) => result = f);
    await tester.tap(_key('pdf-range-first'));
    await tester.pumpAndSettle();
    expect(await result, const PdfPageRange(1, 500));
  });

  testWidgets('cancel returns null', (tester) async {
    late Future<PdfPageRange?> result;
    await _open(tester, (f) => result = f);
    await tester.tap(_key('pdf-range-cancel'));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });

  testWidgets('a valid custom range is returned', (tester) async {
    late Future<PdfPageRange?> result;
    await _open(tester, (f) => result = f);
    await _enter(tester, '141', '640');
    expect(_importEnabled(tester), isTrue);
    expect(_key('pdf-range-error'), findsNothing);
    await tester.tap(_key('pdf-range-import'));
    await tester.pumpAndSettle();
    expect(await result, const PdfPageRange(141, 640));
  });

  for (final c in [
    ('10', '5', PdfPageRangeError.startAfterEnd),
    ('0', '5', PdfPageRangeError.startBelowOne),
    ('1', '641', PdfPageRangeError.endAfterTotal),
    ('1', '600', PdfPageRangeError.tooLong),
    ('', '5', PdfPageRangeError.startBelowOne),
  ]) {
    testWidgets('${c.$1}/${c.$2} disables import and shows an error',
        (tester) async {
      await _open(tester, (_) {});
      await _enter(tester, c.$1, c.$2);
      expect(_importEnabled(tester), isFalse);
      final expected = const PageStringsTr().pdfRangeError(c.$3, 640, 500);
      expect(
        find.descendant(
          of: _key('pdf-range-error'),
          matching: find.text(expected),
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('actions are at least 48dp and labelled', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, (_) {});
    const strings = PageStringsTr();
    for (final k in [
      'pdf-range-first',
      'pdf-range-choose',
      'pdf-range-cancel'
    ]) {
      final size = tester.getSize(_key(k));
      expect(size.height, greaterThanOrEqualTo(48), reason: k);
      expect(size.width, greaterThanOrEqualTo(48), reason: k);
    }
    expect(find.bySemanticsLabel(strings.pdfRangeImportFirst(500)),
        findsOneWidget);
    await tester.tap(_key('pdf-range-choose'));
    await tester.pumpAndSettle();
    for (final k in ['pdf-range-import', 'pdf-range-start', 'pdf-range-end']) {
      expect(tester.getSize(_key(k)).height, greaterThanOrEqualTo(48),
          reason: k);
    }
    expect(find.bySemanticsLabel(strings.pdfRangeStart), findsWidgets);
    expect(find.bySemanticsLabel(strings.pdfRangeEnd), findsWidgets);
    handle.dispose();
  });

  testWidgets('dismissing the sheet returns null', (tester) async {
    late Future<PdfPageRange?> result;
    await _open(tester, (f) => result = f);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });
}
