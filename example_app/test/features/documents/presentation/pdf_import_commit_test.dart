import 'dart:io';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/documents.dart';

void main() {
  late Directory root;
  late PdfPathResolver resolver;
  late File pdf;
  late List<Page> pages;

  setUp(() {
    root = Directory.systemTemp.createTempSync('pdf_commit_');
    Directory('${root.path}/pdfs').createSync();
    resolver = PdfPathResolver(root.path);
    pdf = File('${root.path}/pdfs/a.pdf')..writeAsBytesSync([1, 2, 3]);
    final now = DateTime(2026, 1, 1);
    pages = [
      for (var i = 1; i <= 2; i++)
        Page(
          id: 'p$i',
          index: i - 1,
          size: const PageSize(width: 100, height: 100),
          background: PageBackground.pdfLazy(
            pageIndex: i,
            pdfFilePath: 'pdfs/a.pdf',
          ),
          layers: [Layer.empty('Layer 1')],
          createdAt: now,
          updatedAt: now,
        ),
    ];
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('keeps the stored PDF when the document is created', () async {
    final id = await commitPdfImport(pages, () async => 'doc-1', resolver);

    expect(id, 'doc-1');
    expect(pdf.existsSync(), isTrue);
  });

  test('deletes the stored PDF when creation returns null', () async {
    final id = await commitPdfImport(pages, () async => null, resolver);

    expect(id, isNull);
    expect(pdf.existsSync(), isFalse);
    expect(Directory('${root.path}/pdfs').listSync(), isEmpty);
  });

  test('deletes the stored PDF and rethrows when creation throws', () async {
    await expectLater(
      commitPdfImport(pages, () async => throw StateError('db'), resolver),
      throwsStateError,
    );

    expect(pdf.existsSync(), isFalse);
  });

  test('tolerates an already missing file', () async {
    pdf.deleteSync();

    final id = await commitPdfImport(pages, () async => null, resolver);

    expect(id, isNull);
  });
}
