import 'dart:convert';
import 'dart:io';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

// A page whose inserted image cannot be read is still exported, but the
// result names it so the export flow can warn (#445).

// 1x1 opaque PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGA'
  'hKmMIQAAAABJRU5ErkJggg==',
);

const _lowDpi = PDFExportOptions(quality: PDFExportQuality.low);

/// A page with one image at [path]; [raster] adds a text element so the
/// layer goes through the raster fallback instead of vector ops.
Page _imagePage(int i, String path, {bool raster = false}) {
  final page = Page.create(index: i, size: PageSize.a4Portrait);
  final image = ImageElement.create(
    filePath: path,
    x: 40,
    y: 40,
    width: 80,
    height: 60,
  );
  final layer = page.layers.first.copyWith(
    images: [image],
    texts: raster ? [TextElement.create(text: 'note', x: 10, y: 10)] : null,
  );
  return page.copyWith(layers: [layer]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late String okPath;
  late String corruptPath;
  const gonePath = '/nonexistent/elyanotes_missing.png';

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('elyanotes_img_export');
    okPath = '${dir.path}/ok.png';
    File(okPath).writeAsBytesSync(_png);
    corruptPath = '${dir.path}/corrupt.png';
    File(corruptPath).writeAsStringSync('not an image');
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  group('vector path', () {
    test('a missing image file is reported by its page position', () async {
      final result = await PDFExporter().exportPages(
        pages: [_imagePage(0, okPath), _imagePage(1, gonePath)],
        options: _lowDpi,
      );

      expect(result.isSuccess, isTrue, reason: result.failure?.name);
      expect(result.pdfBytes, isNotEmpty);
      expect(result.missingImagePages, [2]);
      expect(result.missingBackgroundPages, isEmpty);
    });

    test('an unreadable image file is reported', () async {
      final result = await PDFExporter().exportPages(
        pages: [_imagePage(0, corruptPath)],
        options: _lowDpi,
      );

      expect(result.isSuccess, isTrue, reason: result.failure?.name);
      expect(result.missingImagePages, [1]);
    });
  });

  group('raster path', () {
    test('a missing image file is reported by its page position', () async {
      final result = await PDFExporter().exportPages(
        pages: [
          _imagePage(0, gonePath, raster: true),
          _imagePage(1, okPath, raster: true),
        ],
        options: _lowDpi,
      );

      expect(result.isSuccess, isTrue, reason: result.failure?.name);
      expect(result.pdfBytes, isNotEmpty);
      expect(result.missingImagePages, [1]);
    });
  });

  test('readable images and image-free pages report nothing', () async {
    final result = await PDFExporter().exportPages(
      pages: [
        Page.create(index: 0, size: PageSize.a4Portrait),
        _imagePage(1, okPath),
        _imagePage(2, okPath, raster: true),
      ],
      options: _lowDpi,
    );

    expect(result.isSuccess, isTrue, reason: result.failure?.name);
    expect(result.missingImagePages, isEmpty);
  });

  test('hidden layers are not checked', () async {
    final page = _imagePage(0, gonePath);
    final hidden = page.copyWith(
      layers: [page.layers.first.copyWith(isVisible: false)],
    );
    final result = await PDFExporter().exportPages(
      pages: [hidden],
      options: _lowDpi,
    );

    expect(result.missingImagePages, isEmpty);
  });
}
