import 'dart:ui' as ui;
import 'dart:ui' show Rect;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/tiled_element_painter.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect _page = Rect.fromLTWH(0, 0, 512, 512);

ElementScene _scene() => ElementScene(
      strokes: [
        Stroke(
          id: 'a',
          points: [
            DrawingPoint(x: 100, y: 100),
            DrawingPoint(x: 300, y: 300),
          ],
          style: StrokeStyle(color: 0xFF000000, thickness: 20),
          createdAt: DateTime(2024),
        ),
      ],
      elementOrder: const ['a'],
    );

PageTileCache _cache() => PageTileCache(
      strokeRenderer: FlutterStrokeRenderer(),
      cacheManager: ImageCacheManager(),
    );

Future<int> _opaquePixels(TiledElementPainter p, int px) async {
  final recorder = ui.PictureRecorder();
  p.paint(ui.Canvas(recorder), ui.Size(px.toDouble(), px.toDouble()));
  final img = recorder.endRecording().toImageSync(px, px);
  final data = await img.toByteData();
  img.dispose();
  var n = 0;
  for (var i = 3; i < data!.lengthInBytes; i += 4) {
    if (data.getUint8(i) > 0) n++;
  }
  return n;
}

void main() {
  test('shouldRepaint depends on the cache, never constant true', () {
    final a = _cache();
    final b = _cache();
    final p = TiledElementPainter(cache: a);
    expect(p.shouldRepaint(TiledElementPainter(cache: a)), isFalse);
    expect(p.shouldRepaint(TiledElementPainter(cache: b)), isTrue);
    a.dispose();
    b.dispose();
  });

  testWidgets('draws ready tiles', (tester) async {
    await tester.runAsync(() async {
      final cache = _cache()..setViewport(_page, 1, interacting: false);
      cache.update(_scene());
      expect(
        await _opaquePixels(TiledElementPainter(cache: cache), 512),
        greaterThan(1000),
      );
      cache.dispose();
    });
  });

  testWidgets('pending tiles show clipped old-scale tiles, not nothing', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final cache = _cache()..setViewport(_page, 1, interacting: false);
      cache.update(_scene());
      final ready = await _opaquePixels(TiledElementPainter(cache: cache), 512);

      cache.setViewport(_page, 2, interacting: false);
      expect(cache.hasPending, isTrue);
      expect(cache.visibleTiles, isEmpty);
      final fallback =
          await _opaquePixels(TiledElementPainter(cache: cache), 512);
      expect(fallback, closeTo(ready, ready * 0.02));
      cache.dispose();
    });
  });

  testWidgets('cold pending tiles fall back to vectors', (tester) async {
    await tester.runAsync(() async {
      final cache = _cache()..setViewport(_page, 1, interacting: false);
      cache.update(_scene());
      final ready = await _opaquePixels(TiledElementPainter(cache: cache), 512);

      // Drop the old images: only vector fallback can draw the stroke now.
      cache.setViewport(_page, 2, interacting: false);
      cache.debugDropLegacy();
      final fallback =
          await _opaquePixels(TiledElementPainter(cache: cache), 512);
      expect(fallback, closeTo(ready, ready * 0.08));
      cache.dispose();
    });
  });

  testWidgets('multiply content stays vector so it blends with the page', (
    tester,
  ) async {
    final stroke = Stroke(
      id: 'm',
      points: [DrawingPoint(x: 100, y: 100), DrawingPoint(x: 300, y: 300)],
      style: StrokeStyle(
        color: 0xFF2196F3,
        thickness: 20,
        blendMode: DrawingBlendMode.multiply,
      ),
      createdAt: DateTime(2024),
    );
    final cache = _cache()..setViewport(_page, 1, interacting: false);
    cache.update(ElementScene(strokes: [stroke], elementOrder: const ['m']));
    expect(cache.visibleTiles, isEmpty);
    expect(cache.vectorRects, isNotEmpty);
    cache.dispose();
  });
}
