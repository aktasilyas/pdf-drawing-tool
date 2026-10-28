import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:drawing_ui/src/services/pdf_raster_layer_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

// Inserted images are stored relative to the documents root (#370); both PDF
// export paths must resolve them against the *current* root.

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

Layer _layer(String path) => Layer.empty('l').copyWith(images: [
      ImageElement(
          id: 'i', filePath: path, x: 20, y: 20, width: 100, height: 60),
    ]);

int _imageXObjects(List<int> pdf) =>
    RegExp(r'/Subtype\s*/Image').allMatches(latin1.decode(pdf)).length;

Future<List<int>> _export(Layer layer, PdfPathResolver paths) async {
  final result = await PDFExporter(pdfPaths: paths).exportPages(
    pages: [
      Page.create(index: 0, size: const PageSize(width: 200, height: 120))
          .copyWith(layers: [layer]),
    ],
    options: const PDFExportOptions(
      includeBackground: false,
      quality: PDFExportQuality.low,
    ),
  );
  expect(result.isSuccess, isTrue, reason: result.failure?.name);
  return result.pdfBytes;
}

void main() {
  late Directory root;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('pdf_img_test');
    final dir = Directory('${root.path}/elyanotes_images')..createSync();
    File('${dir.path}/a.png').writeAsBytesSync(await _redPng());
  });
  tearDown(() => root.deleteSync(recursive: true));

  const legacy = '/data/user/0/old.pkg/app_flutter/elyanotes_images/a.png';

  for (final stored in ['elyanotes_images/a.png', legacy]) {
    test('vector export embeds image stored as $stored', () async {
      final pdf = await _export(_layer(stored), PdfPathResolver(root.path));
      expect(_imageXObjects(pdf), greaterThan(0));
    });
  }

  test('vector export without a resolver skips the relative image', () async {
    final pdf = await _export(
        _layer('elyanotes_images/a.png'), PdfPathResolver.passthrough);
    expect(_imageXObjects(pdf), 0);
  });

  testWidgets('raster layer renders a relative image from the current root',
      (tester) async {
    await tester.runAsync(() async {
      final layer = _layer('elyanotes_images/a.png');
      final withRoot = await PdfRasterLayerRenderer()
          .renderLayer(layer, 200, 120, 1, paths: PdfPathResolver(root.path));
      final without =
          await PdfRasterLayerRenderer().renderLayer(layer, 200, 120, 1);

      int redAt(PdfRawImage raw) {
        final i = (50 * raw.width + 70) * 4;
        return raw.bytes[i] > 200 && raw.bytes[i + 1] < 60 ? 1 : 0;
      }

      expect(redAt(withRoot!), 1);
      expect(redAt(without!), 0);
    });
  });
}
