import 'dart:io';
import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_import_pages.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:drawing_ui/src/services/pdf_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

class _MockPdfDocument extends Mock implements pdfx.PdfDocument {}

class _MockPdfPage extends Mock implements pdfx.PdfPage {}

/// A 5-page document whose pages in [unreadable] throw on `getPage`.
_MockPdfDocument _document({Set<int> unreadable = const {}}) {
  final doc = _MockPdfDocument();
  when(() => doc.pagesCount).thenReturn(5);
  when(() => doc.close()).thenAnswer((_) async {});
  when(() => doc.getPage(any())).thenAnswer((invocation) async {
    final n = invocation.positionalArguments.first as int;
    if (unreadable.contains(n)) throw StateError('page $n is broken');
    final page = _MockPdfPage();
    when(() => page.width).thenReturn(595);
    when(() => page.height).thenReturn(842);
    when(() => page.close()).thenAnswer((_) async {});
    return page;
  });
  return doc;
}

void main() {
  late Directory docs;
  late PdfPathResolver resolver;

  setUp(() {
    docs = Directory.systemTemp.createTempSync('pdf_skipped_');
    resolver = PdfPathResolver(docs.path);
  });

  tearDown(() => docs.deleteSync(recursive: true));

  Future<PDFImportServiceResult> import(_MockPdfDocument doc) async {
    final service = PDFImportService(
      pdfPaths: resolver,
      loader: PDFLoader(openFile: (_) async => doc),
    );
    try {
      return await service.importFromBytes(
        bytes: Uint8List.fromList([1, 2, 3]),
        config: PDFImportConfig.all(),
      );
    } finally {
      service.dispose();
    }
  }

  test('reports the pages that could not be read (2 of 5)', () async {
    final result = await import(_document(unreadable: {2, 4}));

    expect(result.isSuccess, isTrue);
    expect(result.pages, hasLength(3));
    expect(
      result.pages.map((p) => p.background.pdfPageIndex),
      [1, 3, 5],
    );
    expect(result.skippedPages, [2, 4]);
    expect(result.hasSkippedPages, isTrue);
  });

  test('skips nothing when every page reads fine', () async {
    final result = await import(_document());

    expect(result.isSuccess, isTrue);
    expect(result.pages, hasLength(5));
    expect(result.skippedPages, isEmpty);
    expect(result.hasSkippedPages, isFalse);
  });

  test('buildLazyPdfPages reports each skipped page number', () async {
    final skipped = <int>[];
    var processed = 0;

    final pages = await buildLazyPdfPages(
      _document(unreadable: {1, 5}),
      [1, 2, 3, 4, 5],
      pdfFilePath: 'pdfs/x.pdf',
      onPageProcessed: () => processed++,
      onPageSkipped: skipped.add,
    );

    expect(pages, hasLength(3));
    expect(skipped, [1, 5]);
    expect(processed, 5);
  });

  test('a failed result has no skipped pages', () {
    final result = PDFImportServiceResult.error(
      const PdfImportFailure(PdfImportError.pagesUnreadable),
    );

    expect(result.skippedPages, isEmpty);
  });
}
