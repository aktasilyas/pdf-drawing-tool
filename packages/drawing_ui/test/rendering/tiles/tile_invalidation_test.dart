import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/active_layer_content.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect _page = Rect.fromLTWH(0, 0, 1024, 1024);

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

/// One stroke in each of the four 512px tiles of [_page] at scale 1.
final List<Stroke> _quadrants = [
  _s('q00', 100, 100),
  _s('q10', 700, 100),
  _s('q01', 100, 700),
  _s('q11', 700, 700),
];

ElementScene _scene(
  List<Stroke> strokes, {
  List<ImageElement> images = const [],
}) =>
    ElementScene(
      strokes: strokes,
      images: images,
      elementOrder: [
        for (final s in strokes) s.id,
        for (final i in images) i.id,
      ],
    );

ui.Image _tinyImage() {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  return recorder.endRecording().toImageSync(4, 4);
}

ui.Image _imageOf(PageTileCache cache, TileKey key) =>
    cache.visibleTiles.firstWhere((t) => t.key == key).image;

void main() {
  test('CachedTile precomputes its full-image source rect', () {
    final image = _tinyImage();
    final tile = CachedTile(const TileKey(0, 0), _page, image);

    expect(tile.src, const Rect.fromLTWH(0, 0, 4, 4));
    image.dispose();
  });

  group('PageTileCache.invalidate', () {
    PageTileCache cache() => PageTileCache(
          strokeRenderer: FlutterStrokeRenderer(),
          cacheManager: ImageCacheManager(),
        );

    test('re-rasterizes only the intersecting tiles', () {
      final c = cache()..setViewport(_page, 1, interacting: false);
      c.update(_scene(_quadrants));
      final keep = {
        for (final k in const [TileKey(1, 0), TileKey(0, 1), TileKey(1, 1)])
          k: _imageOf(c, k),
      };
      final old = _imageOf(c, const TileKey(0, 0));

      c.invalidate([const Rect.fromLTWH(90, 90, 60, 60)]);

      expect(c.debugRasterizedKeys, [const TileKey(0, 0)]);
      expect(old.debugDisposed, isTrue);
      for (final e in keep.entries) {
        expect(identical(_imageOf(c, e.key), e.value), isTrue);
      }
      c.dispose();
    });

    test('is a no-op before a scene or viewport exists', () {
      final c = cache();
      c.invalidate([_page]);
      expect(c.debugRasterCount, 0);
      c.dispose();
    });
  });

  testWidgets('a late-loading image re-rasters only the tiles under it', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final manager = ImageCacheManager();
    const image = ImageElement(
      id: 'img',
      filePath: '/does/not/exist/late.png',
      x: 20,
      y: 20,
      width: 60,
      height: 60,
    );
    final scene = _scene([_s('far', 600, 400)], images: const [image]);

    await tester.pumpWidget(
      MaterialApp(
        home: ActiveLayerContent(
          scene: scene,
          transform: CanvasTransform(zoom: 1),
          viewportSize: const Size(800, 600),
          isZooming: false,
          renderer: FlutterStrokeRenderer(),
          cacheManager: manager,
        ),
      ),
    );
    final state =
        tester.state<ActiveLayerContentState>(find.byType(ActiveLayerContent));
    final cache = state.cache;
    final farTile = _imageOf(cache, const TileKey(1, 0));

    manager.debugPut(image.filePath, _tinyImage());
    await tester.pump();

    expect(identical(state.cache, cache), isTrue, reason: 'cache kept');
    expect(cache.debugRasterizedKeys, [const TileKey(0, 0)]);
    expect(identical(_imageOf(cache, const TileKey(1, 0)), farTile), isTrue);

    // A second notification with nothing new loaded changes nothing.
    final count = cache.debugRasterCount;
    manager.debugPut('/unrelated.png', _tinyImage());
    expect(cache.debugRasterCount, count);
  });

  testWidgets('after memory pressure a reloaded image re-rasters its tile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final manager = ImageCacheManager(protectWindow: Duration.zero);
    const image = ImageElement(
      id: 'img',
      filePath: '/does/not/exist/trimmed.png',
      x: 20,
      y: 20,
      width: 60,
      height: 60,
    );
    manager.debugPut(image.filePath, _tinyImage());

    await tester.pumpWidget(
      MaterialApp(
        home: ActiveLayerContent(
          scene: _scene([_s('far', 600, 400)], images: const [image]),
          transform: CanvasTransform(zoom: 1),
          viewportSize: const Size(800, 600),
          isZooming: false,
          renderer: FlutterStrokeRenderer(),
          cacheManager: manager,
        ),
      ),
    );
    final cache = tester
        .state<ActiveLayerContentState>(find.byType(ActiveLayerContent))
        .cache;

    manager.trim();
    tester.binding.handleMemoryPressure();
    manager.debugPut(image.filePath, _tinyImage());
    await tester.pump();

    expect(cache.debugRasterizedKeys, [const TileKey(0, 0)]);
  });
}
