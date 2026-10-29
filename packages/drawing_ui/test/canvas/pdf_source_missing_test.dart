import 'dart:io';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/pdf_page_placeholder.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:drawing_ui/src/providers/pdf_source_relink_provider.dart';
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

  Future<void> pumpPlaceholder(
    WidgetTester tester,
    String? stored, {
    PdfSourceRelinkHandler? relink,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdfPathResolverProvider.overrideWithValue(PdfPathResolver(root.path)),
          if (relink != null)
            pdfSourceRelinkProvider.overrideWith((ref) => relink),
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

  group('locate source button', () {
    const buttonKey = Key('pdfLocateSourceButton');

    testWidgets('hidden without a handler', (tester) async {
      await pumpPlaceholder(tester, 'pdfs/gone.pdf');

      expect(find.byKey(buttonKey), findsNothing);
    });

    testWidgets('shown for a missing file with a handler, at least 48dp',
        (tester) async {
      await pumpPlaceholder(
        tester,
        'pdfs/gone.pdf',
        relink: (_) async => false,
      );

      expect(find.byKey(buttonKey), findsOneWidget);
      expect(find.text("PDF'yi bul…"), findsOneWidget);
      expect(
        tester.getSize(find.byKey(buttonKey)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('hidden when the file exists', (tester) async {
      File('${root.path}/pdfs/here.pdf').writeAsBytesSync([1, 2, 3]);

      await pumpPlaceholder(
        tester,
        'pdfs/here.pdf',
        relink: (_) async => false,
      );

      expect(find.byKey(buttonKey), findsNothing);
    });

    testWidgets('tap calls the handler with the stored path', (tester) async {
      final calls = <String>[];
      await pumpPlaceholder(
        tester,
        'pdfs/gone.pdf',
        relink: (path) async {
          calls.add(path);
          return false;
        },
      );

      await tester.tap(find.byKey(buttonKey));
      await tester.pump();

      expect(calls, ['pdfs/gone.pdf']);
    });
  });
}
