import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/page_png_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

// PNG export renders the page itself off-screen (#294): fixed scale, no
// viewport, no overlays.

Stroke _dot(double x, double y) => Stroke.create(
      points: [DrawingPoint(x: x, y: y, pressure: 0.8)],
      style: StrokeStyle.pen(color: 0xFF000000, thickness: 12),
    );

Page _a4With(Stroke stroke) =>
    Page.create(index: 0, size: PageSize.a4Portrait).addStroke(stroke);

Future<({int width, int height, ByteData data})> _decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  final data = (await image.toByteData())!;
  final result = (width: image.width, height: image.height, data: data);
  image.dispose();
  return result;
}

bool _isDark(ByteData data, int width, int x, int y) {
  final i = (y * width + x) * 4;
  return data.getUint8(i) < 100 &&
      data.getUint8(i + 1) < 100 &&
      data.getUint8(i + 2) < 100;
}

bool _isWhite(ByteData data, int width, int x, int y) {
  final i = (y * width + x) * 4;
  return data.getUint8(i) > 245 &&
      data.getUint8(i + 1) > 245 &&
      data.getUint8(i + 2) > 245;
}

void testRender(String name, Future<void> Function() body) {
  testWidgets(name, (tester) async {
    await tester.runAsync(body);
  });
}

void main() {
  group('layout', () {
    test('a paged document exports the page rect at 2x', () {
      final page = Page.create(index: 0, size: PageSize.a4Portrait);
      final l = PagePngExporter.layout(page, infiniteCanvas: false);
      expect(l.region, const ui.Rect.fromLTWH(0, 0, 595, 842));
      expect(l.width, 1190);
      expect(l.height, 1684);
      expect(l.scale, 2);
    });

    test('the longest side is capped at 4096 px', () {
      final page = Page.create(
        index: 0,
        size: const PageSize(width: 4000, height: 1000),
      );
      final l = PagePngExporter.layout(page, infiniteCanvas: false);
      expect(l.width, PagePngExporter.maxSide);
      expect(l.height, 1024);
    });

    test('content is ignored on a paged document', () {
      final page = _a4With(_dot(-300, 100));
      final l = PagePngExporter.layout(page, infiniteCanvas: false);
      expect(l.region.left, 0);
    });

    test('an infinite canvas grows the region to hold all content', () {
      final page = _a4With(_dot(-300, 100));
      final l = PagePngExporter.layout(page, infiniteCanvas: true);
      expect(l.region.left, lessThan(-300));
      expect(l.region.right, 595);
      expect(l.width, (l.region.width * 2).round());
    });
  });

  testRender('the image is the page at 2x with ink at the expected pixel',
      () async {
    final page = _a4With(_dot(300, 400));
    final png = await PagePngExporter.export(page, infiniteCanvas: false);
    final img = await _decode(png);
    expect(img.width, 1190);
    expect(img.height, 1684);
    expect(_isDark(img.data, img.width, 600, 800), isTrue);
    // Nothing but paper anywhere else: no viewport chrome or overlays.
    expect(_isWhite(img.data, img.width, 5, 5), isTrue);
    expect(_isWhite(img.data, img.width, 1180, 1675), isTrue);
    expect(_isWhite(img.data, img.width, 600, 700), isTrue);
  });

  testRender('an infinite canvas exports ink outside the page', () async {
    final page = _a4With(_dot(-300, 100));
    final l = PagePngExporter.layout(page, infiniteCanvas: true);
    final png = await PagePngExporter.export(page, infiniteCanvas: true);
    final img = await _decode(png);
    expect(img.width, l.width);
    expect(img.height, l.height);
    final x = ((-300 - l.region.left) * l.scale).round();
    final y = ((100 - l.region.top) * l.scale).round();
    expect(_isDark(img.data, img.width, x, y), isTrue);
  });
}
