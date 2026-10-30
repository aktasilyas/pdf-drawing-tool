import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_content_painter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

// Vector export must paint the same elements, in the same order, as the
// canvas: elementOrder first, then everything missing from it by id (#583).

const _w = 200.0;
const _h = 100.0;

Future<Uint8List> _redPng() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 1, 1),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  final image = await recorder.endRecording().toImage(1, 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Plain stroked line starting at x = [x], so its `m` op identifies it.
Stroke _stroke(String id, double x) => Stroke(
      id: id,
      points: [
        DrawingPoint(x: x, y: 50, pressure: 1, timestamp: 0),
        DrawingPoint(x: x + 5, y: 60, pressure: 1, timestamp: 8),
      ],
      style: StrokeStyle.pen(thickness: 2).copyWith(
        pressureSensitive: false,
        dynamics: StrokeDynamics.none,
      ),
      createdAt: DateTime(2026),
    );

/// Element labels in the order their ops appear in the content stream.
List<String> _paintOrder(String content) {
  final labels = <String>[];
  final ops = RegExp(r'(-?[\d.]+) (-?[\d.]+) m\b|\bre\b|\bDo\b');
  for (final m in ops.allMatches(content)) {
    final String label;
    if (m.group(0) == 're') {
      label = 'shape';
    } else if (m.group(0) == 'Do') {
      label = 'image';
    } else {
      label = 'x${double.parse(m.group(1)!).round()}';
    }
    if (labels.isEmpty || labels.last != label) labels.add(label);
  }
  return labels;
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('pdf_order_test');
    File('${dir.path}/a.png').writeAsBytesSync(await _redPng());
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('exports elements missing from elementOrder, in canvas order',
      () async {
    final layer = Layer(
      id: 'l',
      name: 'l',
      strokes: [_stroke('100', 10), _stroke('200', 20), _stroke('300', 30)],
      shapes: [
        Shape(
          id: '250',
          type: ShapeType.rectangle,
          startPoint: DrawingPoint(x: 40, y: 10),
          endPoint: DrawingPoint(x: 60, y: 30),
          style: StrokeStyle.pen(thickness: 2),
        ),
      ],
      images: [
        ImageElement(
          id: '150',
          filePath: '${dir.path}/a.png',
          x: 120,
          y: 20,
          width: 20,
          height: 20,
        ),
      ],
      // Partial list: only the newest stroke (notebook saved before z-order
      // was stored, then one stroke added).
      elementOrder: const ['300'],
    );

    final doc = PdfDocument(compress: false);
    final page = PdfPage(doc, pageFormat: const PdfPageFormat(_w, _h));
    final missing = <ImageElement>[];
    await PdfContentPainter().paintLayerContent(
      page.getGraphics(),
      doc,
      layer,
      _w,
      _h,
      onMissingImage: missing.add,
    );
    final content = latin1.decode(await doc.save());

    expect(missing, isEmpty);
    // Canvas order: '300' (listed), then by id: 100, 150, 200, 250.
    expect(_paintOrder(content), ['x30', 'x10', 'image', 'x20', 'shape']);
  });

  test('a fully listed elementOrder is followed exactly', () async {
    final layer = Layer(
      id: 'l',
      name: 'l',
      strokes: [_stroke('100', 10), _stroke('200', 20), _stroke('300', 30)],
      elementOrder: const ['200', '300', '100'],
    );
    final doc = PdfDocument(compress: false);
    final page = PdfPage(doc, pageFormat: const PdfPageFormat(_w, _h));
    await PdfContentPainter()
        .paintLayerContent(page.getGraphics(), doc, layer, _w, _h);
    final content = latin1.decode(await doc.save());

    expect(_paintOrder(content), ['x20', 'x30', 'x10']);
  });
}
