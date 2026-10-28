import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:example_app/l10n/l10n.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    Locale locale,
    PDFImportServiceResult result,
  ) async {
    final l10n = lookupAppLocalizations(locale);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );
    final messenger = tester.state<ScaffoldMessengerState>(
      find.byType(ScaffoldMessenger),
    );
    showPdfImportOpened(
      messenger,
      title: 'Report',
      result: result,
      l10n: l10n,
      errors: AppErrorStrings(l10n),
    );
    await tester.pump();
  }

  testWidgets('warns how many pages were skipped (EN)', (tester) async {
    await show(
      tester,
      const Locale('en'),
      PDFImportServiceResult.success(const [], skippedPages: [2, 4]),
    );

    expect(
      find.text('2 pages could not be read and were skipped'),
      findsOneWidget,
    );
    expect(find.textContaining('Opening'), findsNothing);
  });

  testWidgets('uses the singular for one skipped page (EN)', (tester) async {
    await show(
      tester,
      const Locale('en'),
      PDFImportServiceResult.success(const [], skippedPages: [3]),
    );

    expect(
      find.text('1 page could not be read and was skipped'),
      findsOneWidget,
    );
  });

  testWidgets('warns how many pages were skipped (TR)', (tester) async {
    await show(
      tester,
      const Locale('tr'),
      PDFImportServiceResult.success(const [], skippedPages: [2, 4]),
    );

    expect(find.text('2 sayfa okunamadı ve atlandı'), findsOneWidget);
  });

  testWidgets('shows the opening message when nothing was skipped',
      (tester) async {
    await show(
      tester,
      const Locale('en'),
      PDFImportServiceResult.success(const []),
    );

    expect(find.textContaining('Opening Report'), findsOneWidget);
    expect(find.textContaining('skipped'), findsNothing);
  });
}
