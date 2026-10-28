import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/page_png_exporter.dart';
import 'package:drawing_ui/src/services/page_rasterizer.dart';
import 'package:flutter_test/flutter_test.dart';

// Inserted images are stored relative to the documents root (#370); the
// off-screen renderers must resolve them against the *current* root.

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

Page _pageWithImage(String path) {
  final page = Page.create(index: 0, size: PageSize.a4Portrait);
  final layer = page.layers.first.copyWith(images: [
    ImageElement(
        id: 'i', filePath: path, x: 100, y: 100, width: 200, height: 200),
  ]);
  return page.copyWith(layers: [layer]);
}

Future<bool> _centreIsRed(Uint8List png, int x, int y) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  final data = (await image.toByteData())!;
  final i = (y * image.width + x) * 4;
  final red = data.getUint8(i) > 200 &&
      data.getUint8(i + 1) < 60 &&
      data.getUint8(i + 2) < 60;
  image.dispose();
  return red;
}

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('raster_img_test'));
  tearDown(() => root.deleteSync(recursive: true));

  Future<void> writeImage() async {
    final dir = Directory('${root.path}/elyanotes_images')..createSync();
    File('${dir.path}/a.png').writeAsBytesSync(await _redPng());
  }

  testWidgets('PageRasterizer draws a relative image from the current root',
      (tester) async {
    await tester.runAsync(() async {
      await writeImage();
      final image = await PageRasterizer.render(
        _pageWithImage('elyanotes_images/a.png'),
        width: 595,
        height: 842,
        pdfPaths: PdfPathResolver(root.path),
      );
      final data = (await image.toByteData())!;
      final i = (200 * 595 + 200) * 4;
      expect(data.getUint8(i), greaterThan(200));
      expect(data.getUint8(i + 1), lessThan(60));
      image.dispose();
    });
  });

  testWidgets('PagePngExporter draws a legacy absolute image re-rooted',
      (tester) async {
    await tester.runAsync(() async {
      await writeImage();
      final result = await PagePngExporter.export(
        _pageWithImage('/old/pkg/app_flutter/elyanotes_images/a.png'),
        infiniteCanvas: false,
        pdfPaths: PdfPathResolver(root.path),
      );
      expect(await _centreIsRed(result.bytes, 400, 400), isTrue);
    });
  });

  testWidgets('without a resolver the relative image is a placeholder',
      (tester) async {
    await tester.runAsync(() async {
      await writeImage();
      final result = await PagePngExporter.export(
        _pageWithImage('elyanotes_images/a.png'),
        infiniteCanvas: false,
      );
      expect(await _centreIsRed(result.bytes, 400, 400), isFalse);
    });
  });
}
