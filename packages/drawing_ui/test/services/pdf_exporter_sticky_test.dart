import 'dart:convert';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

Page _page(Layer layer) => Page.create(
      index: 0,
      size: const PageSize(width: 200, height: 120),
    ).copyWith(layers: [layer]);

/// Image XObject dictionaries visible in [pdf].
int _imageXObjects(List<int> pdf) =>
    RegExp(r'/Subtype\s*/Image').allMatches(latin1.decode(pdf)).length;

/// Exports a single page holding [layer] and returns the PDF bytes.
Future<List<int>> _export(Layer layer) async {
  final result = await PDFExporter().exportPages(
    pages: [_page(layer)],
    options: const PDFExportOptions(
      includeBackground: false,
      quality: PDFExportQuality.low,
    ),
  );
  expect(result.isSuccess, isTrue, reason: result.failure?.name);
  return result.pdfBytes;
}

void main() {
  final shape = Shape(
    id: 'rect',
    type: ShapeType.rectangle,
    startPoint: DrawingPoint(x: 10, y: 10),
    endPoint: DrawingPoint(x: 60, y: 60),
    style: StrokeStyle.pen(),
  );
  final note = StickyNote(id: 'n', x: 40, y: 20, width: 100, height: 80);

  test('sticky notes on a vector layer are exported as an overlay image',
      () async {
    final plain = await _export(Layer.empty('l').addShape(shape));
    final withNote =
        await _export(Layer.empty('l').addShape(shape).addStickyNote(note));

    expect(_imageXObjects(plain), 0);
    expect(withNote.length, greaterThan(plain.length + 200),
        reason: 'the note overlay image must be embedded');
  });
}
