import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pdf_test_text.dart';

/// A 200 x 120 page with one vector pen stroke at x -200..-100.
Page _page() => Page.create(
      index: 0,
      size: const PageSize(width: 200, height: 120),
    ).copyWith(layers: [
      Layer.empty('l').addStroke(Stroke.create(
        style: StrokeStyle.pen(),
        points: [
          for (var x = -200.0; x <= -100; x += 10)
            DrawingPoint(x: x, y: 50 + (x + 200) / 10, pressure: 0.5),
        ],
      )),
    ]);

Future<List<int>> _export({required bool infinite}) async {
  final result = await PDFExporter().exportPages(
    pages: [_page()],
    options: PDFExportOptions(
      includeBackground: false,
      isInfiniteCanvas: infinite,
      quality: PDFExportQuality.low,
    ),
  );
  expect(result.isSuccess, isTrue, reason: result.failure?.name);
  return result.pdfBytes;
}

void main() {
  test('infinite page: PDF grows to the content and the stroke lies inside',
      () async {
    final texts = pdfTexts(await _export(infinite: true));
    final box = pdfMediaBox(texts);
    expect(box.width, greaterThan(_page().size.width + 200),
        reason: 'the page grows left to hold the stroke at x = -200');
    expect(box.height, 120);

    final points = [for (final t in texts.skip(1)) ...pdfPathPoints(t)];
    expect(points.where((p) => p.user.x < 0), isNotEmpty,
        reason: 'the stroke is written in page coordinates (x < 0)');
    const tol = 0.5;
    for (final p in points) {
      expect(p.page.x, inInclusiveRange(-tol, box.width + tol),
          reason: 'x of $p');
      expect(p.page.y, inInclusiveRange(-tol, box.height + tol),
          reason: 'y of $p');
    }
  });

  test('paged export keeps the page size and coordinates', () async {
    final texts = pdfTexts(await _export(infinite: false));
    final box = pdfMediaBox(texts);
    expect(box.width, 200);
    expect(box.height, 120);
    final points = [for (final t in texts.skip(1)) ...pdfPathPoints(t)];
    expect(points, isNotEmpty);
    for (final p in points) {
      expect(p.page.x, closeTo(p.user.x, 1e-9), reason: 'no shift: $p');
    }
  });
}
