import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/services/selection_capture_service.dart';
import 'package:flutter_test/flutter_test.dart';

// "Copy selection as image" / "save to gallery" (#325): the PNG the user gets.

const _scale = SelectionCaptureService.exportScale;

Stroke _line(String id) => Stroke(
      id: id,
      points: [for (var x = 20.0; x <= 100; x += 10) DrawingPoint(x: x, y: 30)],
      style: StrokeStyle.pen(color: 0xFF000000, thickness: 6).copyWith(
        pressureSensitive: false,
        dynamics: StrokeDynamics.none,
      ),
      createdAt: DateTime(2026),
    );

Future<Uint8List?> _capture(
  Selection selection,
  Layer layer, {
  PageBackground? background,
  Uint8List? pdfImageBytes,
}) async {
  final cache = ImageCacheManager();
  try {
    return await SelectionCaptureService.captureSelection(
      selection: selection,
      layer: layer,
      cacheManager: cache,
      background: background,
      pdfImageBytes: pdfImageBytes,
      pageSize: const ui.Size(595, 842),
    );
  } finally {
    cache.dispose();
  }
}

Future<ui.Image> _decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  return (await codec.getNextFrame()).image;
}

/// A solid red PNG standing in for a rasterized PDF page.
Future<Uint8List> _redPagePng() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 60, 84),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(60, 84);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

void testRender(String name, Future<void> Function() body) {
  testWidgets(name, (tester) async {
    await tester.runAsync(body);
  });
}

void main() {
  const bounds = BoundingBox(left: 10, top: 20, right: 110, bottom: 70);
  final layer = Layer.empty('l').addStroke(_line('a'));
  final selection = Selection.create(
    type: SelectionType.rectangle,
    selectedStrokeIds: const ['a'],
    bounds: bounds,
  );

  testRender('PNG decodes to (bounds + 2 x padding) x export scale', () async {
    final png = await _capture(selection, layer);
    expect(png, isNotNull);
    final image = await _decode(png!);
    expect(image.width, ((100 + 32) * _scale).ceil());
    expect(image.height, ((50 + 32) * _scale).ceil());
    image.dispose();
  });

  testRender('an empty selection captures nothing', () async {
    expect(await _capture(Selection.empty(), layer), isNull);
  });

  testRender('a selection on a PDF page includes the page image', () async {
    final png = await _capture(
      selection,
      layer,
      background: const PageBackground(
        type: BackgroundType.pdf,
        pdfFilePath: 'doc.pdf',
        pdfPageIndex: 0,
      ),
      pdfImageBytes: await _redPagePng(),
    );
    final image = await _decode(png!);
    final data = (await image.toByteData())!;
    // Page (50, 60) is on the PDF page and away from the stroke (y = 30).
    int red(int px, int py) => data.getUint8((py * image.width + px) * 4);
    int green(int px, int py) => data.getUint8((py * image.width + px) * 4 + 1);
    final x = ((50 - 10 + 16) * _scale).toInt();
    final y = ((60 - 20 + 16) * _scale).toInt();
    expect(red(x, y), greaterThan(200), reason: 'PDF page is red');
    expect(green(x, y), lessThan(60), reason: 'PDF page is red');
    image.dispose();
  });
}
