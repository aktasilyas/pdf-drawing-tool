// PDF page thumbnails share the editor's open document and decode the PDF
// at the thumbnail's size; export keeps its own resolution (#509).
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/pdf_thumbnail_documents_provider.dart';
import 'package:drawing_ui/src/services/page_rasterizer.dart';
import 'package:drawing_ui/src/services/pdf_document_pool.dart';
import 'package:drawing_ui/src/services/thumbnail_generator.dart';
import 'package:drawing_ui/src/utils/drawing_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_pdf_documents.dart';

const _pdfPath = '/docs/book.pdf';

/// Rendering uses real async (picture.toImage), which never completes under
/// the FakeAsync zone of a plain [testWidgets].
void testRender(String name, Future<void> Function() body) {
  testWidgets(name, (tester) async {
    await tester.runAsync(body);
  });
}

Page _pdfPage(int pdfPage) => Page.create(
      index: pdfPage - 1,
      size: const PageSize(width: 200, height: 300),
      background:
          PageBackground.pdfLazy(pageIndex: pdfPage, pdfFilePath: _pdfPath),
    );

void main() {
  late FakePdfDocuments pdfs;

  setUp(() {
    pdfs = FakePdfDocuments();
    // The fake bytes are not an image; the decode failure is only logged.
    DrawingLog.sink = (level, message, error, stackTrace) {};
  });

  tearDown(() => DrawingLog.sink = null);

  testRender('thumbnails of N pages of one PDF open the document once',
      () async {
    final pool = PdfDocumentPool(opener: pdfs.open);

    for (var i = 1; i <= 4; i++) {
      final png = await ThumbnailGenerator.generate(
        _pdfPage(i),
        width: 100,
        height: 150,
        pdfDocuments: pool,
      );
      expect(png, isNotNull);
    }

    expect(pdfs.openCount(_pdfPath), 1);
    expect(pdfs.renders.map((r) => r.page), [1, 2, 3, 4]);
  });

  testRender('the PDF background is decoded at the thumbnail size', () async {
    final pool = PdfDocumentPool(opener: pdfs.open);

    // A 200x300 page fitted into 100x200 is 100x150 pixels.
    await ThumbnailGenerator.generate(
      _pdfPage(1),
      width: 100,
      height: 200,
      pdfDocuments: pool,
    );

    final render = pdfs.renders.single;
    expect((render.width, render.height), (100, 150));
  });

  testRender('without a pool the thumbnail opens and closes the document',
      () async {
    // The default opener: the file is missing, so nothing is opened, and the
    // thumbnail still renders.
    final png = await ThumbnailGenerator.generate(_pdfPage(1));

    expect(png, isNotNull);
  });

  test('thumbnail PDF pixels are rounded up and capped', () {
    expect(PageRasterizer.thumbnailPdfPixels(0.2), 1);
    expect(PageRasterizer.thumbnailPdfPixels(99.5), 100);
    expect(PageRasterizer.thumbnailPdfPixels(9000),
        PageRasterizer.maxThumbnailPdfSide);
  });

  testRender('disposing the editor scope closes the open documents', () async {
    final container = ProviderContainer(overrides: [
      pdfDocumentOpenerProvider.overrideWithValue(pdfs.open),
    ]);
    final subscription =
        container.listen(pdfThumbnailDocumentsProvider, (previous, next) {});
    final pool = subscription.read();

    await pool.renderPage(_pdfPath, 1, width: 10, height: 10);
    expect(pdfs.closedPaths, isEmpty);

    container.dispose();
    await pumpEventQueue();

    expect(pdfs.closedPaths, [_pdfPath]);
  });
}
