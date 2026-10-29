import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

// Source-PDF renders in an export are capped like every other render path,
// and an unreadable page or damaged file is reported, not fatal (#463).

class _FakePage implements PdfRenderPage {
  _FakePage(this.width, this.height, {this.fail = false});

  @override
  final double width;
  @override
  final double height;
  final bool fail;
  final requests = <(double, double)>[];
  bool closed = false;

  @override
  Future<Uint8List?> renderJpeg(double width, double height) async {
    requests.add((width, height));
    if (fail) throw StateError('pdfium could not render');
    return null;
  }

  @override
  Future<void> close() async => closed = true;
}

class _ThrowingSource implements PdfSource {
  @override
  Future<Uint8List?> renderJpeg(int index, double scale) =>
      throw StateError('broken page');

  @override
  Future<void> close() async {}
}

Page _pdfPage(int i, String path) => Page.create(
      index: i,
      size: PageSize.a4Portrait,
      background: PageBackground.pdfLazy(pageIndex: i + 1, pdfFilePath: path),
    );

const _lowDpi = PDFExportOptions(quality: PDFExportQuality.low);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cappedPdfRenderSize', () {
    test('a pixel-sized MediaBox is capped at 4096 px, aspect kept', () {
      final size = cappedPdfRenderSize(2480, 3508, 150 / 72);
      expect(size.height, closeTo(4096, 0.001));
      expect(size.width / size.height, closeTo(2480 / 3508, 1e-9));
    });

    test('an A4 page at 150 dpi is not changed', () {
      final size = cappedPdfRenderSize(595, 842, 150 / 72);
      expect(size.width, closeTo(595 * 150 / 72, 1e-9));
      expect(size.height, closeTo(842 * 150 / 72, 1e-9));
    });
  });

  group('PageRenderingPdfSource', () {
    test('a 2480x3508 pt page is requested at <= 4096 px', () async {
      final page = _FakePage(2480, 3508);
      final source = PageRenderingPdfSource(
        getPage: (_) async => page,
        close: () async {},
      );

      await source.renderJpeg(1, 150 / 72);

      final (w, h) = page.requests.single;
      expect(w <= 4096 && h <= 4096, isTrue, reason: '$w x $h');
      expect(h, closeTo(4096, 0.001));
      expect(page.closed, isTrue);
    });

    test('a page that throws renders as null and is closed', () async {
      final page = _FakePage(595, 842, fail: true);
      final source = PageRenderingPdfSource(
        getPage: (_) async => page,
        close: () async {},
      );

      expect(await source.renderJpeg(1, 2), isNull);
      expect(page.closed, isTrue);
    });

    test('a page that cannot be opened renders as null', () async {
      final source = PageRenderingPdfSource(
        getPage: (_) async => throw StateError('no such page'),
        close: () async {},
      );

      expect(await source.renderJpeg(9, 2), isNull);
    });
  });

  group('PDFExporter', () {
    test('a source page that throws is reported, the export succeeds',
        () async {
      final exporter =
          PDFExporter(sourceOpener: (_) async => _ThrowingSource());
      final result = await exporter.exportPages(
        pages: [Page.create(index: 0), _pdfPage(1, '/a.pdf')],
        options: _lowDpi,
      );

      expect(result.isSuccess, isTrue, reason: result.failure?.name);
      expect(result.missingBackgroundPages, [2]);
    });

    test('a damaged source file reports all of its pages', () async {
      final exporter = PDFExporter(
        sourceOpener: (_) async => throw const FormatException('not a PDF'),
      );
      final result = await exporter.exportPages(
        pages: [_pdfPage(0, '/bad.pdf'), _pdfPage(1, '/bad.pdf')],
        options: _lowDpi,
      );

      expect(result.isSuccess, isTrue, reason: result.failure?.name);
      expect(result.missingBackgroundPages, [1, 2]);
    });
  });
}
