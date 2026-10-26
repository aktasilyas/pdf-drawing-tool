import 'dart:io';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/pdf_page_placeholder.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('pdf_missing_');
    Directory('${root.path}/pdfs').createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<void> pumpPlaceholder(WidgetTester tester, String? stored) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdfPathResolverProvider.overrideWithValue(PdfPathResolver(root.path)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PdfPagePlaceholder(
              width: 200,
              height: 300,
              pdfFilePath: stored,
            ),
          ),
        ),
      ),
    );
    // The existence check is real file I/O, which fake async cannot await.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  testWidgets('missing source PDF shows the distinct state', (tester) async {
    await pumpPlaceholder(tester, 'pdfs/gone.pdf');

    expect(find.text('Kaynak PDF bulunamadı'), findsOneWidget);
    expect(find.text('PDF Sayfası'), findsNothing);
  });

  testWidgets('legacy absolute path of a missing file is also detected',
      (tester) async {
    await pumpPlaceholder(tester, '/data/user/0/old.pkg/files/pdfs/gone.pdf');

    expect(find.text('Kaynak PDF bulunamadı'), findsOneWidget);
  });

  testWidgets('existing source PDF keeps the generic placeholder',
      (tester) async {
    File('${root.path}/pdfs/here.pdf').writeAsBytesSync([1, 2, 3]);

    await pumpPlaceholder(tester, 'pdfs/here.pdf');

    expect(find.text('PDF Sayfası'), findsOneWidget);
    expect(find.text('Kaynak PDF bulunamadı'), findsNothing);
  });

  testWidgets('legacy absolute path resolves to the existing file',
      (tester) async {
    File('${root.path}/pdfs/here.pdf').writeAsBytesSync([1, 2, 3]);

    await pumpPlaceholder(tester, '/data/user/0/old.pkg/files/pdfs/here.pdf');

    expect(find.text('PDF Sayfası'), findsOneWidget);
  });

  testWidgets('page without a file path shows the generic placeholder',
      (tester) async {
    await pumpPlaceholder(tester, null);

    expect(find.text('PDF Sayfası'), findsOneWidget);
  });
}
