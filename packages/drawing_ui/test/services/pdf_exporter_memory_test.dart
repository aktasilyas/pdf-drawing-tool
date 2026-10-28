import 'dart:convert';
import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSource implements PdfSource {
  int renders = 0;
  bool closed = false;

  @override
  Future<Uint8List?> renderJpeg(int index, double scale) async {
    renders++;
    return null; // null skips the background; only open/close matter
  }

  @override
  Future<void> close() async => closed = true;
}

Page _pdfPage(int i, String path) => Page.create(
      index: i,
      size: const PageSize(width: 200, height: 120),
    ).copyWith(
      background: PageBackground(
        type: BackgroundType.pdf,
        pdfFilePath: path,
        pdfPageIndex: i + 1,
      ),
    );

Layer _pencilLayer() {
  final points = [
    for (var i = 0; i < 20; i++)
      DrawingPoint(x: 10.0 + i * 5, y: 20.0 + i * 3, pressure: 0.5),
  ];
  return Layer.empty('l').addStroke(
    Stroke.create(
        style: StrokeStyle.pen().copyWith(texture: StrokeTexture.pencil),
        points: points),
  );
}

void main() {
  test('each source PDF is opened once and closed after the export', () async {
    final opened = <String, _FakeSource>{};
    var opens = 0;
    final exporter = PDFExporter(sourceOpener: (path) async {
      opens++;
      return opened[path] = _FakeSource();
    });

    final result = await exporter.exportPages(
      pages: [
        for (var i = 0; i < 5; i++) _pdfPage(i, '/a.pdf'),
        _pdfPage(0, '/b.pdf'),
      ],
    );

    expect(result.isSuccess, isTrue, reason: result.failure?.name);
    expect(opens, 2);
    expect(opened['/a.pdf']!.renders, 5);
    expect(opened.values.every((s) => s.closed), isTrue);
  });

  test('PDF page content is still rendered with includeBackground off',
      () async {
    final source = _FakeSource();
    final exporter = PDFExporter(sourceOpener: (_) async => source);

    final result = await exporter.exportPages(
      pages: [_pdfPage(0, '/a.pdf')],
      options: const PDFExportOptions(includeBackground: false),
    );

    expect(result.isSuccess, isTrue, reason: result.failure?.name);
    expect(source.renders, 1);
  });

  test('relative stored paths are resolved before the pool lookup', () async {
    const resolver = PdfPathResolver('/docs');
    final resolved = resolver.resolve('book.pdf');
    expect(resolved, isNot('book.pdf'));
    final opened = <String>[];
    final exporter = PDFExporter(
      pdfPaths: resolver,
      sourceOpener: (path) async {
        opened.add(path);
        return _FakeSource();
      },
    );

    final result = await exporter.exportPages(
      pages: [for (var i = 0; i < 3; i++) _pdfPage(i, 'book.pdf')],
    );

    expect(result.isSuccess, isTrue, reason: result.failure?.name);
    expect(opened, [resolved]);
  });

  test('the source is closed when the export is cancelled', () async {
    final source = _FakeSource();
    final exporter = PDFExporter(sourceOpener: (_) async => source);
    var calls = 0;

    final result = await exporter.exportPages(
      pages: [for (var i = 0; i < 3; i++) _pdfPage(i, '/a.pdf')],
      isCancelled: () => ++calls > 1,
    );

    expect(result.wasCancelled, isTrue);
    expect(source.closed, isTrue);
  });

  test('raster layers are embedded as Flate-compressed streams', () async {
    final page = Page.create(
      index: 0,
      size: const PageSize(width: 595, height: 842),
    ).copyWith(layers: [_pencilLayer()]);

    final result = await PDFExporter().exportPages(
      pages: [page],
      options: const PDFExportOptions(includeBackground: false),
    );
    expect(result.isSuccess, isTrue, reason: result.failure?.name);

    final text = latin1.decode(result.pdfBytes);
    final images = RegExp(r'<<[^>]*/Subtype\s*/Image[^>]*>>')
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toList();
    expect(images, isNotEmpty);
    for (final dict in images) {
      expect(dict, contains('/FlateDecode'));
    }
    // RGBA at 150 dpi is ~8.7 MB uncompressed; a mostly empty layer deflates
    // to a tiny fraction of that.
    expect(result.pdfBytes.length, lessThan(500 * 1024));
  });
}
