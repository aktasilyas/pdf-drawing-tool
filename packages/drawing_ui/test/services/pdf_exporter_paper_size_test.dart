import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pdf_test_text.dart';

// Notebook pages are 1024 units tall with the paper's aspect ratio; the PDF
// must still come out at the notebook's paper size (#454).

/// A notebook page for paper [widthMm] x [heightMm], as the editor creates
/// it, with one vector pen stroke across it.
Page _paperPage(double widthMm, double heightMm, {PageBackground? bg}) {
  final size = PageSize(width: 1024 * widthMm / heightMm, height: 1024);
  return Page.create(
    index: 0,
    size: size,
    background: bg ?? PageBackground.blank,
  ).copyWith(layers: [
    Layer.empty('l').addStroke(Stroke.create(
      style: StrokeStyle.pen(),
      points: [
        for (var x = 20.0; x <= size.width - 20; x += 40)
          DrawingPoint(x: x, y: 100 + x / 2, pressure: 0.5),
      ],
    )),
  ]);
}

final _a4 = PDFPageFormat.millimeters(210, 297);

Future<List<String>> _export(
  List<Page> pages, {
  PDFPageFormat? paper,
  bool infinite = false,
}) async {
  final exporter = PDFExporter(sourceOpener: (_) async => null);
  final result = await exporter.exportPages(
    pages: pages,
    options: PDFExportOptions(
      includeBackground: false,
      quality: PDFExportQuality.low,
      pageFormat: paper,
      isInfiniteCanvas: infinite,
    ),
  );
  expect(result.isSuccess, isTrue, reason: result.failure?.name);
  return pdfTexts(result.pdfBytes);
}

void expectBox(({double width, double height}) box, double w, double h) {
  expect(box.width, closeTo(w, 1), reason: 'width of $box');
  expect(box.height, closeTo(h, 1), reason: 'height of $box');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('millimeters converts to points', () {
    expect(_a4.width, closeTo(595.28, 0.01));
    expect(_a4.height, closeTo(841.89, 0.01));
  });

  test('an A4 notebook page exports at 595 x 842 with its content scaled',
      () async {
    final page = _paperPage(210, 297);
    final texts = await _export([page], paper: _a4);

    final boxes = pdfMediaBoxes(texts);
    expect(boxes, hasLength(1));
    expectBox(boxes.single, 595, 842);

    final s = _a4.width / page.size.width;
    final points = [for (final t in texts.skip(1)) ...pdfPathPoints(t)];
    expect(points, isNotEmpty);
    for (final p in points) {
      // The PDF writes coordinates with 4 decimals.
      expect(p.page.x, closeTo(p.user.x * s, 0.01), reason: 'x of $p');
      expect(p.page.y, closeTo(p.user.y * s, 0.01), reason: 'y of $p');
      expect(p.page.x, inInclusiveRange(0, boxes.single.width));
      expect(p.page.y, inInclusiveRange(0, boxes.single.height));
    }
  });

  test('an A5 notebook page exports at 420 x 595', () async {
    final texts = await _export(
      [_paperPage(148, 210)],
      paper: PDFPageFormat.millimeters(148, 210),
    );
    expectBox(pdfMediaBoxes(texts).single, 420, 595);
  });

  test('landscape A4 swaps the dimensions', () async {
    final texts = await _export(
      [_paperPage(297, 210)],
      paper: PDFPageFormat.millimeters(297, 210),
    );
    expectBox(pdfMediaBoxes(texts).single, 842, 595);
  });

  test('a PDF-backed page in the same export keeps its native size', () async {
    final pdfPage = Page.create(
      index: 1,
      size: const PageSize(width: 600, height: 800),
      background: PageBackground.pdfLazy(pageIndex: 1, pdfFilePath: 'a.pdf'),
    );
    final texts = await _export([_paperPage(210, 297), pdfPage], paper: _a4);

    final boxes = pdfMediaBoxes(texts);
    expect(boxes, hasLength(2));
    expectBox(boxes[0], 595, 842);
    expectBox(boxes[1], 600, 800);
  });

  test('an image page keeps its native size', () async {
    const bg = PageBackground(
      type: BackgroundType.blank,
      imageFilePath: 'images/photo.png',
    );
    final page = _paperPage(210, 297, bg: bg);
    final texts = await _export([page], paper: _a4);
    expectBox(pdfMediaBoxes(texts).single, page.size.width, 1024);
  });

  test('without a paper size page units stay points', () async {
    final page = _paperPage(210, 297);
    final texts = await _export([page]);
    expectBox(pdfMediaBoxes(texts).single, page.size.width, 1024);
    final points = [for (final t in texts.skip(1)) ...pdfPathPoints(t)];
    for (final p in points) {
      expect(p.page.x, closeTo(p.user.x, 1e-9), reason: 'no scale: $p');
    }
  });

  test('an infinite-canvas export ignores the paper size', () async {
    final page = _paperPage(210, 297);
    final texts = await _export([page], paper: _a4, infinite: true);
    final box = pdfMediaBoxes(texts).single;
    expect(box.width, greaterThanOrEqualTo(page.size.width));
    expect(box.height, greaterThanOrEqualTo(1024));
  });
}
