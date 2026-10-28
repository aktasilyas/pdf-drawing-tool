import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/panels/add_page_import_helper.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns [result] from every import.
class _FakeImportService extends Fake implements PDFImportService {
  _FakeImportService(this.result);

  final PDFImportServiceResult result;
  bool disposed = false;

  @override
  Future<PDFImportServiceResult> importFromFile({
    required String filePath,
    required PDFImportConfig config,
  }) async =>
      result;

  @override
  void dispose() => disposed = true;
}

Page _pdfPage(int pdfPage) => Page.create(
      index: pdfPage - 1,
      background: PageBackground.pdfLazy(
        pageIndex: pdfPage,
        pdfFilePath: 'pdfs/a.pdf',
      ),
    );

void main() {
  test('reports the skipped page count and re-indexes the pages', () async {
    final service = _FakeImportService(
      PDFImportServiceResult.success(
        [_pdfPage(1), _pdfPage(2)],
        skippedPages: [3],
      ),
    );
    final skipped = <int>[];
    PdfImportFailure? failure;

    final pages = await importPdfAsPages(
      'in.pdf',
      4,
      onError: (f) => failure = f,
      onPagesSkipped: skipped.add,
      createService: () => service,
    );

    expect(pages.map((p) => p.index), [4, 5]);
    expect(skipped, [1]);
    expect(failure, isNull);
    expect(service.disposed, isTrue);
  });

  test('does not report skipped pages when every page was read', () async {
    final service = _FakeImportService(
      PDFImportServiceResult.success([_pdfPage(1)]),
    );
    var calls = 0;

    final pages = await importPdfAsPages(
      'in.pdf',
      0,
      onPagesSkipped: (_) => calls++,
      createService: () => service,
    );

    expect(pages, hasLength(1));
    expect(calls, 0);
  });

  test('a failed import reports the failure, not skipped pages', () async {
    final service = _FakeImportService(
      PDFImportServiceResult.error(
        const PdfImportFailure(PdfImportError.pagesUnreadable),
      ),
    );
    var calls = 0;
    PdfImportFailure? failure;

    final pages = await importPdfAsPages(
      'in.pdf',
      0,
      onError: (f) => failure = f,
      onPagesSkipped: (_) => calls++,
      createService: () => service,
    );

    expect(pages, isEmpty);
    expect(failure?.error, PdfImportError.pagesUnreadable);
    expect(calls, 0);
  });
}
