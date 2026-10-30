import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas.dart';
import 'package:drawing_ui/src/canvas/editor_memory_pressure_observer.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/providers/pdf_page_cache.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Low-memory handling of the editor caches (#515).

Future<ui.Image> _solid(int w, int h) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint(),
  );
  return recorder.endRecording().toImage(w, h);
}

Stroke _s(String id, double x, double y) => Stroke(
      id: id,
      points: [
        DrawingPoint(x: x, y: y),
        DrawingPoint(x: x + 24, y: y + 16),
        DrawingPoint(x: x + 30, y: y + 40),
      ],
      style: StrokeStyle(color: 0xFF112233, thickness: 3),
      createdAt: DateTime(2024),
    );

void _fillPdfCaches(ProviderContainer container) {
  final bytes = Uint8List.fromList([1, 2, 3]);
  container.read(pdfPageCacheProvider.notifier).state = {'a.pdf|1': bytes};
  container.read(pdfThumbnailCacheProvider.notifier).state = {'a.pdf|2': bytes};
}

void main() {
  group('EditorMemoryPressureObserver', () {
    testWidgets('fires on memory pressure, never after dispose',
        (tester) async {
      var calls = 0;
      final observer = EditorMemoryPressureObserver(() => calls++);

      tester.binding.handleMemoryPressure();
      expect(calls, 1);

      observer.dispose();
      tester.binding.handleMemoryPressure();
      expect(calls, 1);
    });
  });

  group('PageTileCache.trimToVisible', () {
    test('keeps only visible tiles and rebuilds the rest on demand', () {
      const page = Rect.fromLTWH(0, 0, 1024, 1024);
      final cache = PageTileCache(
        strokeRenderer: FlutterStrokeRenderer(),
        cacheManager: ImageCacheManager(),
      )..setViewport(page, 1, interacting: false);
      addTearDown(cache.dispose);
      // One stroke in each of the four 512px tiles (1 MiB each).
      cache.update(ElementScene(strokes: [
        _s('a', 100, 100),
        _s('b', 700, 100),
        _s('c', 100, 700),
        _s('d', 700, 700),
      ], elementOrder: const ['a', 'b', 'c', 'd']));
      cache.setViewport(const Rect.fromLTWH(0, 0, 500, 500), 1,
          interacting: false);
      final before = cache.cachedBytes;
      expect(before, 4 << 20);

      cache.trimToVisible();

      expect(cache.cachedBytes, 1 << 20);
      expect(cache.visibleTiles.map((t) => t.key), [const TileKey(0, 0)]);

      cache.setViewport(page, 1, interacting: false);
      expect(cache.visibleTiles, hasLength(4));
      expect(cache.cachedBytes, before);
    });
  });

  group('ImageCacheManager.trim', () {
    testWidgets('evicts unprotected images, keeps recently read ones',
        (tester) async {
      await tester.runAsync(() async {
        final cache =
            ImageCacheManager(protectWindow: const Duration(hours: 1));
        addTearDown(cache.dispose);
        final read = await _solid(100, 100);
        final idle = await _solid(100, 100);
        cache.debugPut('read', read);
        cache.debugPut('idle', idle);
        cache.get('read');

        cache.trim();

        expect(read.debugDisposed, isFalse);
        expect(idle.debugDisposed, isTrue);
        expect(cache.cachedBytes, 100 * 100 * 4);
        expect(cache.get('read'), isNotNull);
        expect(cache.get('idle'), isNull);
      });
    });

    testWidgets('reads older than the window are not protected',
        (tester) async {
      await tester.runAsync(() async {
        final cache = ImageCacheManager(protectWindow: Duration.zero);
        addTearDown(cache.dispose);
        cache.debugPut('a', await _solid(100, 100));
        cache.get('a');

        cache.trim();

        expect(cache.cachedBytes, 0);
      });
    });
  });

  group('DrawingCanvas', () {
    testWidgets('memory pressure empties the PDF caches and idle images',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: DrawingCanvas())),
      ));
      _fillPdfCaches(container);
      final images = tester
          .state<DrawingCanvasState>(find.byType(DrawingCanvas))
          .debugImageCacheManager;
      final image = (await tester.runAsync(() => _solid(10, 10)))!;
      images.debugPut('idle.png', image);

      tester.binding.handleMemoryPressure();

      expect(container.read(pdfPageCacheProvider), isEmpty);
      expect(container.read(pdfThumbnailCacheProvider), isEmpty);
      expect(image.debugDisposed, isTrue);
    });

    testWidgets('an unmounted editor no longer reacts', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: DrawingCanvas())),
      ));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox()),
      ));
      _fillPdfCaches(container);

      tester.binding.handleMemoryPressure();

      expect(container.read(pdfPageCacheProvider), hasLength(1));
      expect(container.read(pdfThumbnailCacheProvider), hasLength(1));
    });
  });
}
